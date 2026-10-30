import AVFoundation
import Foundation
import Darwin

/// Preloads bundled kits and serializes control work away from the audio render thread.
/// Call `prepare()` before playing; pass resolved lesson pad indices in eight-pad mode.
public final class AudioEngine: @unchecked Sendable {
    /// Canonical padIndex-to-voice mapping; paired hand pads share the same voice.
    /// See DECISIONS §2. Eight-pad controller slots must first resolve to lesson pad indices.
    public static let defaultPadVoices = [
        "tomHi", "tomLo", "crash", "ride",
        "shaker", "wood", "cowbell", "openHat",
        "hat", "clap", "rim", "hat",
        "kick", "snare", "snare", "kick"
    ]

    public enum Failure: LocalizedError {
        case missingResource(String)
        case invalidManifest(String)
        case invalidSample(String)
        case unknownKit(String)
        case invalidPad(Int)
        case invalidVelocity(Int)
        case invalidTempo
        case notPrepared
        case notRunning
        case insufficientLeadTime
        case voiceLimit

        public var errorDescription: String? {
            switch self {
            case .missingResource(let path): return "Missing audio resource: \(path)."
            case .invalidManifest(let reason): return "Invalid sample kit manifest: \(reason)."
            case .invalidSample(let path): return "Cannot decode sample: \(path)."
            case .unknownKit(let id): return "Unknown sample kit: \(id)."
            case .invalidPad(let index): return "Invalid audio pad index: \(index)."
            case .invalidVelocity(let velocity): return "Invalid MIDI velocity: \(velocity)."
            case .invalidTempo: return "Metronome tempo must be between 1 and 400 BPM, with a positive beat count."
            case .notPrepared: return "Prepare the audio engine before playing."
            case .notRunning: return "The audio engine is stopped."
            case .insufficientLeadTime: return "The requested sound time is too close or has already passed."
            case .voiceLimit: return "All audio voices are occupied."
            }
        }
    }

    private final class Layer {
        let maxVelocity: Int
        let buffers: [AVAudioPCMBuffer]
        var nextVariant = 0

        init(maxVelocity: Int, buffers: [AVAudioPCMBuffer]) {
            self.maxVelocity = maxVelocity
            self.buffers = buffers
        }

        func nextBuffer() -> AVAudioPCMBuffer {
            let buffer = buffers[nextVariant]
            nextVariant = (nextVariant + 1) % buffers.count
            return buffer
        }
    }

    private struct Player {
        let node: AVAudioPlayerNode
        var availableAt: UInt64 = 0
    }

    private struct Metronome {
        let firstAudibleTime: UInt64
        let secondsPerBeat: Double
        let beatCount: Int?
        var nextBeat = 0
    }

    private let bundle: Bundle
    private let padVoices: [String]
    private let queue = DispatchQueue(label: "cz.kju.SmackAPad.audio", qos: .userInteractive)
    private let session = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
    private let clickPlayer = AVAudioPlayerNode()
    private var players: [Player] = []
    private var kits: [String: [String: [Layer]]] = [:]
    private var kitModels: [SampleKit] = []
    private var selectedKit = "acoustic"
    private var clickBuffer: AVAudioPCMBuffer?
    private var timer: DispatchSourceTimer?
    private var metronome: Metronome?
    private var observers: [NSObjectProtocol] = []
    private var prepared = false
    private var wantsPlayback = false
    private var interrupted = false
    private var failure: Error?

    // Output delay belongs exclusively to audio scheduling, never to scoring.
    private var playbackDelay: TimeInterval = 0
    private var ioDuration: TimeInterval = 0

    /// Uses the canonical domain mapping by default; the engine never interprets MIDI slots.
    public init(bundle: Bundle = .main, padVoices: [String] = AudioEngine.defaultPadVoices) {
        self.bundle = bundle
        self.padVoices = padVoices
        observeSession()
    }

    deinit {
        timer?.cancel()
        observers.forEach(NotificationCenter.default.removeObserver)
        engine.stop()
    }

    public var availableKits: [SampleKit] { queue.sync { kitModels } }
    public var selectedKitID: String { queue.sync { selectedKit } }
    public var lastError: Error? { queue.sync { failure } }
    public var isRunning: Bool { queue.sync { engine.isRunning } }

    /// Performs file I/O and conversion once. Call outside latency-sensitive input callbacks.
    public func prepare() throws {
        try queue.sync {
            guard !prepared else { return }
            guard padVoices.count == 16 else {
                throw Failure.invalidManifest("Expected sixteen pad voice names")
            }
            try loadKits()
            clickBuffer = try makeClick()
            for _ in 0..<64 {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: format)
                players.append(Player(node: node))
            }
            engine.attach(clickPlayer)
            engine.connect(clickPlayer, to: engine.mainMixerNode, format: format)
            engine.prepare()
            prepared = true
        }
    }

    public func selectKit(_ id: String) throws {
        try queue.sync {
            guard prepared else { throw Failure.notPrepared }
            guard kits[id] != nil else { throw Failure.unknownKit(id) }
            selectedKit = id
        }
    }

    public func start() throws {
        try queue.sync {
            guard prepared else { throw Failure.notPrepared }
            try activateSession()
            try engine.start()
            wantsPlayback = true
            interrupted = false
            failure = nil
        }
    }

    public func stop() {
        queue.sync {
            wantsPlayback = false
            stopPlayers()
            engine.stop()
            do {
                try session.setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                failure = error
            }
        }
    }

    /// Live hits are enqueued immediately, without adding any output-delay wait.
    /// Velocity zero is MIDI note-off and produces no sound.
    public func play(padIndex: Int, velocity: Int) {
        queue.async { [weak self] in
            guard let self else { return }
            do {
                try self.playOnQueue(padIndex: padIndex, velocity: velocity, audibleHostTime: nil)
            } catch {
                self.failure = error
            }
        }
    }

    /// `audibleHostTime` is an absolute mach host time when sound should reach the output.
    /// Submit ahead of time; late notes are rejected instead of silently moving the beat.
    public func schedule(padIndex: Int, velocity: Int, audibleHostTime: UInt64) throws {
        try queue.sync {
            try playOnQueue(padIndex: padIndex, velocity: velocity, audibleHostTime: audibleHostTime)
        }
    }

    /// Returns the audible time of the first click, also usable as the calibration anchor.
    /// A ten-click calibration uses BPM 60 and `beatCount: 10`.
    @discardableResult
    public func startMetronome(
        bpm: Double, firstBeatHostTime: UInt64? = nil, beatCount: Int? = nil
    ) throws -> UInt64 {
        try queue.sync {
            guard engine.isRunning else { throw Failure.notRunning }
            guard bpm.isFinite, (1...400).contains(bpm), beatCount.map({ $0 > 0 }) ?? true else {
                throw Failure.invalidTempo
            }
            let first = firstBeatHostTime ?? (mach_absolute_time() + ticks(playbackDelay + 0.1))
            _ = try renderTime(for: first)
            stopMetronomeOnQueue()
            metronome = Metronome(firstAudibleTime: first, secondsPerBeat: 60 / bpm, beatCount: beatCount)
            let source = DispatchSource.makeTimerSource(queue: queue)
            source.schedule(deadline: .now(), repeating: .milliseconds(20), leeway: .milliseconds(1))
            source.setEventHandler { [weak self] in self?.scheduleMetronome() }
            timer = source
            source.resume()
            return first
        }
    }

    public func stopMetronome() { queue.sync { stopMetronomeOnQueue() } }

    private func playOnQueue(padIndex: Int, velocity: Int, audibleHostTime: UInt64?) throws {
        guard prepared else { throw Failure.notPrepared }
        guard padVoices.indices.contains(padIndex) else { throw Failure.invalidPad(padIndex) }
        guard (0...127).contains(velocity) else { throw Failure.invalidVelocity(velocity) }
        guard velocity > 0 else { return }
        guard engine.isRunning else { throw Failure.notRunning }
        guard let layers = kits[selectedKit]?[padVoices[padIndex]],
              let layer = layers.first(where: { velocity <= $0.maxVelocity }) else {
            throw Failure.invalidManifest("Missing voice \(padVoices[padIndex])")
        }
        let time = try audibleHostTime.map { try renderTime(for: $0) }
        let now = mach_absolute_time()
        guard let index = players.firstIndex(where: { $0.availableAt <= now }) else {
            throw Failure.voiceLimit
        }
        let buffer = layer.nextBuffer()
        let node = players[index].node
        node.stop()
        node.volume = Float(velocity) / 127
        node.scheduleBuffer(buffer, at: time, options: [])
        node.play()
        let start = time?.hostTime ?? now
        // Keep a render-buffer margin before reusing a node with a sounding tail.
        players[index].availableAt = start + ticks(Double(buffer.frameLength) / format.sampleRate + ioDuration)
    }

    private func activateSession() throws {
        try session.setCategory(.playback, mode: .default)
        // AVAudioSession has no Web Audio `.interactive` hint. Request its native equivalent.
        try session.setPreferredSampleRate(format.sampleRate)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
        ioDuration = session.ioBufferDuration
        playbackDelay = session.outputLatency + ioDuration
    }

    private func renderTime(for audibleTime: UInt64) throws -> AVAudioTime {
        let delay = ticks(playbackDelay)
        let now = mach_absolute_time()
        guard audibleTime > delay, audibleTime - delay > now + ticks(ioDuration) else {
            throw Failure.insufficientLeadTime
        }
        return AVAudioTime(hostTime: audibleTime - delay)
    }

    private func ticks(_ seconds: TimeInterval) -> UInt64 {
        AVAudioTime.hostTime(forSeconds: seconds)
    }

    private func scheduleMetronome() {
        guard var state = metronome, let clickBuffer, engine.isRunning else { return }
        let now = mach_absolute_time()
        let earliest = now + ticks(playbackDelay + ioDuration)
        let horizon = now + ticks(playbackDelay + 0.1)
        while state.beatCount.map({ state.nextBeat < $0 }) ?? true {
            let audibleTime = state.firstAudibleTime + ticks(Double(state.nextBeat) * state.secondsPerBeat)
            guard audibleTime <= horizon else { break }
            state.nextBeat += 1
            // Never bunch missed beats after an OS scheduling stall.
            guard audibleTime > earliest else { continue }
            clickPlayer.scheduleBuffer(clickBuffer, at: AVAudioTime(hostTime: audibleTime - ticks(playbackDelay)))
            if !clickPlayer.isPlaying { clickPlayer.play() }
        }
        metronome = state
        if let count = state.beatCount, state.nextBeat >= count {
            timer?.cancel()
            timer = nil
            metronome = nil
            // Leave the player running until the last queued click has rendered.
        }
    }

    private func stopMetronomeOnQueue() {
        timer?.cancel()
        timer = nil
        metronome = nil
        clickPlayer.stop()
    }

    private func stopPlayers() {
        stopMetronomeOnQueue()
        for index in players.indices {
            players[index].node.stop()
            players[index].availableAt = 0
        }
    }

    private func loadKits() throws {
        guard let manifest = bundle.url(forResource: "sample-kits", withExtension: "json", subdirectory: "Data")
            ?? bundle.url(forResource: "sample-kits", withExtension: "json") else {
            throw Failure.missingResource("sample-kits.json")
        }
        guard let root = bundle.url(forResource: "samples", withExtension: "bundle")
            ?? bundle.url(forResource: "Samples", withExtension: nil) else {
            throw Failure.missingResource("samples.bundle")
        }
        let definitions = try JSONDecoder().decode([String: SampleKitDefinition].self, from: Data(contentsOf: manifest))
        guard definitions["acoustic"] != nil else { throw Failure.invalidManifest("Missing default acoustic kit") }
        var cache: [String: AVAudioPCMBuffer] = [:]
        var loaded: [String: [String: [Layer]]] = [:]
        for (id, definition) in definitions {
            var voices: [String: [Layer]] = [:]
            for voice in Set(padVoices) where definition.voices[voice] == nil {
                throw Failure.invalidManifest("\(id): missing \(voice)")
            }
            for (voice, entries) in definition.voices {
                guard !entries.isEmpty else {
                    throw Failure.invalidManifest("\(id): missing \(voice)")
                }
                let sorted = entries.sorted { $0.maxVel < $1.maxVel }
                guard sorted.last?.maxVel == 127,
                      sorted.allSatisfy({ (1...127).contains($0.maxVel) }),
                      Set(sorted.map(\.maxVel)).count == sorted.count else {
                    throw Failure.invalidManifest("\(id)/\(voice): invalid velocity boundaries")
                }
                voices[voice] = try sorted.map { entry in
                    let paths = entry.variants.flatMap { $0.isEmpty ? nil : $0 } ?? [entry.url]
                    let buffers = try paths.map { path in
                        if let cached = cache[path] { return cached }
                        let parts = path.split(separator: "/").map(String.init)
                        guard parts.count == 3, parts[0] == "samples",
                              !parts.contains(".."), !parts.contains(".") else {
                            throw Failure.invalidManifest("Invalid sample path: \(path)")
                        }
                        let url = root.appendingPathComponent(parts[1]).appendingPathComponent(parts[2])
                        guard FileManager.default.fileExists(atPath: url.path) else {
                            throw Failure.missingResource(path)
                        }
                        let buffer = try decodeSample(url)
                        cache[path] = buffer
                        return buffer
                    }
                    return Layer(maxVelocity: entry.maxVel, buffers: buffers)
                }
            }
            loaded[id] = voices
        }
        kits = loaded
        kitModels = definitions.map { SampleKit(kitId: $0.key, definition: $0.value) }
            .sorted { $0.kitId < $1.kitId }
    }

    private func decodeSample(_ url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url)
        guard file.length > 0, file.length < Int64(UInt32.max),
              let input = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw Failure.invalidSample(url.lastPathComponent)
        }
        try file.read(into: input)
        if input.format == format { return input }
        let capacity = ceil(Double(input.frameLength) * format.sampleRate / input.format.sampleRate) + 32
        guard capacity < Double(UInt32.max),
              let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(capacity)),
              let converter = AVAudioConverter(from: input.format, to: format) else {
            throw Failure.invalidSample(url.lastPathComponent)
        }
        var supplied = false
        var conversionError: NSError?
        let status = converter.convert(to: output, error: &conversionError) { _, status in
            if supplied {
                status.pointee = .endOfStream
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return input
        }
        if let conversionError { throw conversionError }
        guard status != .error, output.frameLength > 0 else { throw Failure.invalidSample(url.lastPathComponent) }
        return output
    }

    private func makeClick() throws -> AVAudioPCMBuffer {
        let length = AVAudioFrameCount(format.sampleRate * 0.012)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: length),
              let channels = buffer.floatChannelData else { throw Failure.invalidSample("metronome click") }
        buffer.frameLength = length
        for frame in 0..<Int(length) {
            let time = Double(frame) / format.sampleRate
            let envelope = min(time / 0.001, 1) * exp(-time * 500)
            let value = Float(sin(2 * .pi * 1_500 * time) * envelope * 0.45)
            for channel in 0..<Int(format.channelCount) { channels[channel][frame] = value }
        }
        return buffer
    }

    private func observeSession() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: nil) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue
            let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? NSNumber)?.uintValue ?? 0
            self?.queue.async { [weak self] in
                guard let self else { return }
                if type == AVAudioSession.InterruptionType.began.rawValue {
                    self.interrupted = true
                    self.stopPlayers()
                    self.engine.pause()
                } else if type == AVAudioSession.InterruptionType.ended.rawValue {
                    self.interrupted = false
                    if options & AVAudioSession.InterruptionOptions.shouldResume.rawValue != 0 {
                        self.resumeAfterSessionChange()
                    }
                }
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: nil) { [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue
            // Our own initial category setup must not restart an already scheduled sequence.
            guard reason != AVAudioSession.RouteChangeReason.categoryChange.rawValue else { return }
            self?.queue.async { [weak self] in self?.resumeAfterSessionChange() }
        })
    }

    private func resumeAfterSessionChange() {
        guard prepared, wantsPlayback, !interrupted else { return }
        stopPlayers()
        engine.stop()
        do {
            try activateSession()
            try engine.start()
            failure = nil
        } catch {
            failure = error
        }
        // A route change invalidates calibration timing; the caller restarts the click sequence.
    }
}
