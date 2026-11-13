import AVFoundation
import Foundation
import Darwin
import os

/// Serializes playback control separately from sample validation and decoding.
public final class AudioEngine: @unchecked Sendable {
    static let practice = AudioEngine()
    private static let logger = Logger(subsystem: "cz.kju.SmackAPad", category: "Audio")

    /// AVAudioSession is process-wide even though practice and calibration have separate graphs.
    private static let sessionOwnership = AudioSessionOwnership(activate: {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setPreferredSampleRate(48_000)
        try session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true)
    }, deactivate: {
        try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    })

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
        case outputTimingUnavailable
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
            case .outputTimingUnavailable: return "Audio output timing is not ready."
            case .insufficientLeadTime: return "The requested sound time is too close or has already passed."
            case .voiceLimit: return "All audio voices are occupied."
            }
        }
    }

    fileprivate final class Layer {
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

    struct LoadedKit: @unchecked Sendable {
        fileprivate let voices: [String: [Layer]]
        /// Normalisation gain in dB per voice for this kit (ticket 166).
        fileprivate let gainsDB: [String: Float]
    }

    private struct SampleLayer {
        let maxVelocity: Int
        let urls: [URL]
    }

    private struct KitCatalog {
        let models: [SampleKit]
        let samples: [String: Result<[String: [SampleLayer]], Error>]
        let gains: SampleGain.Table
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
    private let clickOnly: Bool
    private let queue = DispatchQueue(label: "cz.kju.SmackAPad.audio", qos: .userInteractive)
    private let loader = DispatchQueue(label: "cz.kju.SmackAPad.samples", qos: .userInitiated)
    private let session = AVAudioSession.sharedInstance()
    private let sessionOwnerID = UUID()
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
    private let metronomeMixer = AVAudioMixerNode()
    private let padsMixer = AVAudioMixerNode()
    private let patternMixer = AVAudioMixerNode()

    private let clickPlayer = AVAudioPlayerNode()
    private let calibrationClickPlayer = AVAudioPlayerNode()
    private var padPlayers: [Player] = []
    private var patternPlayers: [Player] = []

    public private(set) var metronomeVolume: Float = 0.8
    public private(set) var padsVolume: Float = 1.0
    public private(set) var patternVolume: Float = 0.7
    /// User trim in dB per voice name. Only touched on `queue`.
    private var trimsDB: [String: Float] = [:]
    // Only accessed on the loader queue.
    private var catalog: KitCatalog?
    private var sampleCache = SampleKitCache<LoadedKit>()
    private var selectedKit: LoadedKit?
    private var clickBuffer: AVAudioPCMBuffer?
    private var timer: DispatchSourceTimer?
    private var metronome: Metronome?
    private var observers: [NSObjectProtocol] = []
    private var prepared = false
    private var wantsPlayback = false
    private var schedulingFailed = false
    private var lateSounds = LateSoundPolicy()
    private var onRunAudioChange: (@MainActor @Sendable () -> Void)?
    private var interrupted = false
    private var failure: Error?

    // Buffer duration is a scheduling safety margin, never the audible-time conversion.
    private var ioDuration: TimeInterval = 0

    public struct CalibrationSnapshot: Sendable {
        public let outputTimes: [Double]
        public let clockChanged: Bool
        let outputRoute: AudioOutputRoute?
    }

    private struct CalibrationCapture {
        let id: UUID
        let timing: AudioOutputTiming
        let outputRoute: AudioOutputRoute
        var outputTimes: [Double] = []
        var clockOrigin: Double?
        var sampleRate: Double?
        var lastSampleTime: AVAudioFramePosition?
        var clockChanged = false
    }

    /// Used only by the audio tap callback; never accessed from the control queue.
    private final class ClickDetector: @unchecked Sendable {
        private var lastOnset = -Double.infinity

        func onsets(in buffer: AVAudioPCMBuffer, at time: AVAudioTime) -> [Double]? {
            guard time.isHostTimeValid, time.isSampleTimeValid,
                  buffer.format.sampleRate > 0, let channel = buffer.floatChannelData?[0] else { return nil }
            let rate = buffer.format.sampleRate
            let host = AVAudioTime.seconds(forHostTime: time.hostTime)
            var result: [Double] = []
            for frame in 0..<Int(buffer.frameLength) {
                let seconds = host + Double(frame) / rate
                // Calibration is the only signal on this engine. The generated click
                // starts with one zero sample; detect its first nonzero frame and
                // recover the onset, independent of buffer delivery time.
                if abs(channel[frame]) > 0.0001, seconds - lastOnset > 0.5 {
                    let onset = seconds - 1 / rate
                    result.append(onset)
                    lastOnset = onset
                }
            }
            return result
        }
    }

    private var calibrationCapture: CalibrationCapture?
    private var calibrationTapInstalled = false

    /// Uses the canonical domain mapping by default; the engine never interprets MIDI slots.
    private init(bundle: Bundle = .main, padVoices: [String] = AudioEngine.defaultPadVoices,
                 clickOnly: Bool = false) {
        self.bundle = bundle
        self.padVoices = padVoices
        self.clickOnly = clickOnly
        observeSession()
    }

    static func calibration() -> AudioEngine { AudioEngine(clickOnly: true) }

    deinit {
        timer?.cancel()
        observers.forEach(NotificationCenter.default.removeObserver)
        if calibrationTapInstalled { engine.mainMixerNode.removeTap(onBus: 0) }
        engine.stop()
        try? Self.sessionOwnership.release(for: sessionOwnerID)
    }

    public var lastError: Error? { queue.sync { failure } }
    public var isRunning: Bool { queue.sync { engine.isRunning } }

    public func setMetronomeVolume(_ volume: Float) {
        queue.async { [weak self] in
            guard let self else { return }
            let clamped = max(0, min(1, volume))
            self.metronomeVolume = clamped
            if self.prepared { self.metronomeMixer.outputVolume = clamped }
        }
    }

    public func setPadsVolume(_ volume: Float) {
        queue.async { [weak self] in
            guard let self else { return }
            let clamped = max(0, min(1, volume))
            self.padsVolume = clamped
            if self.prepared { self.padsMixer.outputVolume = clamped }
        }
    }

    public func setPatternVolume(_ volume: Float) {
        queue.async { [weak self] in
            guard let self else { return }
            let clamped = max(0, min(1, volume))
            self.patternVolume = clamped
            if self.prepared { self.patternMixer.outputVolume = clamped }
        }
    }

    /// Per-instrument trim in dB, keyed by voice name ("kick", "crash"...). Takes effect on the next hit.
    public func setInstrumentTrims(_ trims: [String: Int]) {
        let converted = trims.mapValues { Float(SampleGain.clampTrim($0)) }
        queue.async { [weak self] in self?.trimsDB = converted }
    }

    #if DEBUG
    var timingReadout: AudioTimingReadout {
        queue.sync {
            AudioTimingReadout(
                route: session.currentRoute.outputs.map { "\($0.portName) (\($0.portType.rawValue))" }.joined(separator: ", "),
                presentationLatency: engine.mainMixerNode.outputPresentationLatency,
                sessionOutputLatency: session.outputLatency,
                ioBufferDuration: session.ioBufferDuration
            )
        }
    }
    #endif

    /// Do not calibrate against an unstarted clock or an unknown presentation delay.
    public var calibrationClockReady: Bool {
        queue.sync {
            guard engine.isRunning, let time = engine.outputNode.lastRenderTime,
                  time.isHostTimeValid, time.isSampleTimeValid else { return false }
            return AudioOutputTiming(presentationLatency: engine.mainMixerNode.outputPresentationLatency) != nil
        }
    }

    /// Validates the catalog once and prepares the graph without decoding any kit.
    func prepare() async throws -> [SampleKit] {
        #if DEBUG
        let started = DispatchTime.now()
        defer { if clickOnly { Self.logDuration("prepare", since: started) } }
        #endif
        let models: [SampleKit] = clickOnly ? [] : try await withCheckedThrowingContinuation { continuation in
            loader.async {
                continuation.resume(with: Result { try self.kitCatalog().models })
            }
        }
        try Task.checkCancellation()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                continuation.resume(with: Result { try self.prepareGraph() })
            }
        }
        return models
    }

    private func prepareGraph() throws {
        guard !prepared else { return }
        clickBuffer = try makeClick()

        if !clickOnly {
            engine.attach(metronomeMixer)
            engine.connect(metronomeMixer, to: engine.mainMixerNode, format: format)
            engine.attach(padsMixer)
            engine.connect(padsMixer, to: engine.mainMixerNode, format: format)
            engine.attach(patternMixer)
            engine.connect(patternMixer, to: engine.mainMixerNode, format: format)

            metronomeMixer.outputVolume = metronomeVolume
            padsMixer.outputVolume = padsVolume
            patternMixer.outputVolume = patternVolume

            for _ in 0..<48 {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: padsMixer, format: format)
                padPlayers.append(Player(node: node))
            }
            for _ in 0..<48 {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: patternMixer, format: format)
                patternPlayers.append(Player(node: node))
            }
            engine.attach(clickPlayer)
            engine.connect(clickPlayer, to: metronomeMixer, format: format)
        }
        engine.attach(calibrationClickPlayer)
        engine.connect(calibrationClickPlayer, to: engine.mainMixerNode, format: format)
        engine.prepare()
        prepared = true
    }

    func loadKit(_ id: String) async throws -> LoadedKit {
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
            loader.async {
                continuation.resume(with: Result {
                    // Take a local reference to avoid overlapping access to sampleCache.
                    let catalog = try self.kitCatalog()
                    return try self.sampleCache.load(id, fallback: SoundKitResolver.fallbackKitId) { id in
                        do {
                            return try self.decodeKit(id, catalog: catalog)
                        } catch {
                            Self.logger.error("Kit \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
                            throw error
                        }
                    }
                })
            }
        }
    }

    func selectKit(_ kit: LoadedKit?) {
        queue.sync { selectedKit = kit }
    }

    public func start() throws {
        try start(onRunAudioChange: nil)
    }

    @discardableResult
    func start(onRunAudioChange: (@MainActor @Sendable () -> Void)?) throws -> AudioOutputRoute {
        try queue.sync {
            guard prepared, clickOnly || selectedKit != nil else { throw Failure.notPrepared }
            if interrupted, !clickOnly, onRunAudioChange == nil {
                // Reopening idle practice audio can wait for the interruption to end.
                // An explicit Start still attempts activation, even without an end notification.
                wantsPlayback = true
                return .current
            }
            do {
                try activateSession()
                if !engine.isRunning { try engine.start() }
                wantsPlayback = true
                interrupted = false
                failure = nil
                self.onRunAudioChange = onRunAudioChange
                return .current
            } catch {
                wantsPlayback = false
                engine.stop()
                try? Self.sessionOwnership.release(for: sessionOwnerID)
                failure = error
                throw error
            }
        }
    }

    public func stop() {
        queue.sync {
            wantsPlayback = false
            schedulingFailed = false
            lateSounds = LateSoundPolicy()
            onRunAudioChange = nil
            stopPlayers()
            calibrationClickPlayer.stop()
            engine.stop()
            do {
                try Self.sessionOwnership.release(for: sessionOwnerID)
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
                try self.playOnQueue(padIndex: padIndex, velocity: velocity, audibleHostTime: nil, isPattern: false)
            } catch {
                self.failure = error
            }
        }
    }

    struct ScheduledSound: Sendable {
        let audibleHostTime: UInt64
        let padIndex: Int?
        var velocity = 0
        var passStart: Double?
    }

    /// Absolute mach times describe when sounds should reach the output.
    func schedule(_ sounds: [ScheduledSound], onError: @escaping @Sendable (Error) -> Void) {
        queue.async {
            guard !self.schedulingFailed else { return }
            do {
                for sound in sounds {
                    do {
                        if let pad = sound.padIndex {
                            try self.playOnQueue(padIndex: pad, velocity: sound.velocity,
                                                 audibleHostTime: sound.audibleHostTime, isPattern: true)
                        } else {
                            try self.scheduleClick(audibleHostTime: sound.audibleHostTime)
                        }
                    } catch Failure.insufficientLeadTime {
                        let shouldStop = self.lateSounds.recordSkip(passStart: sound.passStart)
                        Self.logger.debug("[Audio] late sound skipped (\(self.lateSounds.totalSkipped))")
                        if shouldStop { throw Failure.insufficientLeadTime }
                    }
                }
            } catch {
                self.schedulingFailed = true
                onError(error)
            }
        }
    }

    /// Returns the intended audible time of the first click.
    /// Calibration independently observes the rendered click instead of using this anchor.
    @discardableResult
    public func startMetronome(
        bpm: Double, firstBeatHostTime: UInt64? = nil, beatCount: Int? = nil
    ) throws -> UInt64 {
        try queue.sync {
            guard engine.isRunning else { throw Failure.notRunning }
            guard bpm.isFinite, (1...400).contains(bpm), beatCount.map({ $0 > 0 }) ?? true else {
                throw Failure.invalidTempo
            }
            let timing = try outputTimingOnQueue()
            let first = firstBeatHostTime ?? (mach_absolute_time() + ticks(timing.presentationLatency + 0.1))
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

    /// Four count-in clicks followed by ten measured clicks, exactly one second apart.
    /// The returned time is for display/deadline only, NEVER a measurement anchor.
    @discardableResult
    public func startCalibrationClicks() throws -> Double {
        try queue.sync {
            guard engine.isRunning, let clickBuffer else { throw Failure.notRunning }
            stopCalibrationOnQueue()
            stopPlayers()
            let timing = try outputTimingOnQueue()
            let id = UUID()
            calibrationCapture = CalibrationCapture(id: id, timing: timing, outputRoute: .current)
            let detector = ClickDetector()
            engine.mainMixerNode.installTap(onBus: 0, bufferSize: 512, format: nil) { [weak self] buffer, time in
                // Copy values while the tap owns the buffer; never retain audio memory.
                let onsets = detector.onsets(in: buffer, at: time)
                let rate = buffer.format.sampleRate
                let sampleTime = time.sampleTime
                let host = AVAudioTime.seconds(forHostTime: time.hostTime)
                self?.queue.async { [weak self] in
                    self?.captureCalibration(id: id, onsets: onsets, host: host, sampleTime: sampleTime, rate: rate)
                }
            }
            calibrationTapInstalled = true
            let first = mach_absolute_time() + ticks(timing.presentationLatency + 0.6)
            for index in 0..<14 {
                let time = try renderTime(for: first + ticks(Double(index)))
                calibrationClickPlayer.scheduleBuffer(clickBuffer, at: time)
            }
            calibrationClickPlayer.play()
            return AVAudioTime.seconds(forHostTime: first)
        }
    }

    public func calibrationSnapshot() -> CalibrationSnapshot {
        queue.sync {
            guard let capture = calibrationCapture else {
                return CalibrationSnapshot(outputTimes: [], clockChanged: true, outputRoute: nil)
            }
            let latency = engine.mainMixerNode.outputPresentationLatency
            return CalibrationSnapshot(outputTimes: capture.outputTimes,
                clockChanged: capture.clockChanged || !engine.isRunning || AudioOutputTiming(presentationLatency: latency) == nil ||
                    abs(latency - capture.timing.presentationLatency) > 0.002,
                outputRoute: capture.outputRoute)
        }
    }

    public func stopCalibrationClicks() { queue.sync { stopCalibrationOnQueue() } }

    private func captureCalibration(id: UUID, onsets: [Double]?, host: Double,
                                    sampleTime: AVAudioFramePosition, rate: Double) {
        guard var capture = calibrationCapture, capture.id == id else { return }
        defer { calibrationCapture = capture }
        guard let onsets, rate.isFinite, rate > 0, host.isFinite else {
            capture.clockChanged = true
            return
        }
        let origin = host - Double(sampleTime) / rate
        if let previous = capture.clockOrigin, abs(origin - previous) > 0.002 {
            capture.clockChanged = true
        }
        if let previous = capture.sampleRate, previous != rate { capture.clockChanged = true }
        if let previous = capture.lastSampleTime, sampleTime <= previous { capture.clockChanged = true }
        if capture.clockOrigin == nil { capture.clockOrigin = origin }
        capture.sampleRate = rate
        capture.lastSampleTime = sampleTime
        // The tap timestamp is the RENDERED frame's host time. Convert to hardware
        // presentation time using the engine's downstream presentation latency.
        // Scheduling uses this exact model in reverse; session+buffer is diagnostic only.
        capture.outputTimes += onsets.map { capture.timing.audibleTime(forRenderTime: $0) }
        if capture.outputTimes.count > 14 { capture.clockChanged = true }
    }

    private func stopCalibrationOnQueue() {
        calibrationCapture = nil
        if calibrationTapInstalled {
            engine.mainMixerNode.removeTap(onBus: 0)
            calibrationTapInstalled = false
        }
        calibrationClickPlayer.stop()
    }

    /// Schedules one audible click. A continuous lesson owns the beat times so a
    /// tempo change does not cancel clicks already queued for the preceding pass.
    private func scheduleClick(audibleHostTime: UInt64) throws {
        guard engine.isRunning, let clickBuffer else { throw Failure.notRunning }
        let time = try renderTime(for: audibleHostTime)
        clickPlayer.scheduleBuffer(clickBuffer, at: time)
        if !clickPlayer.isPlaying { clickPlayer.play() }
    }

    private func playOnQueue(padIndex: Int, velocity: Int, audibleHostTime: UInt64?, isPattern: Bool) throws {
        guard prepared else { throw Failure.notPrepared }
        guard padVoices.indices.contains(padIndex) else { throw Failure.invalidPad(padIndex) }
        guard (0...127).contains(velocity) else { throw Failure.invalidVelocity(velocity) }
        guard velocity > 0 else { return }
        guard engine.isRunning else { throw Failure.notRunning }
        guard let layers = selectedKit?.voices[padVoices[padIndex]],
              let layer = layers.first(where: { velocity <= $0.maxVelocity }) else {
            throw Failure.invalidManifest("Missing voice \(padVoices[padIndex])")
        }
        let voice = padVoices[padIndex]
        let volume = SampleGain.playerVolume(
            velocity: velocity,
            normalisationDB: selectedKit?.gainsDB[voice] ?? 0,
            trimDB: trimsDB[voice] ?? 0
        )
        let time = try audibleHostTime.map { try renderTime(for: $0) }
        let now = mach_absolute_time()
        if isPattern {
            guard let index = patternPlayers.firstIndex(where: { $0.availableAt <= now }) else {
                throw Failure.voiceLimit
            }
            let buffer = layer.nextBuffer()
            let node = patternPlayers[index].node
            node.stop()
            node.volume = volume
            node.scheduleBuffer(buffer, at: time, options: [])
            node.play()
            let start = time?.hostTime ?? now
            patternPlayers[index].availableAt = start + ticks(Double(buffer.frameLength) / format.sampleRate + ioDuration)
        } else {
            guard let index = padPlayers.firstIndex(where: { $0.availableAt <= now }) else {
                throw Failure.voiceLimit
            }
            let buffer = layer.nextBuffer()
            let node = padPlayers[index].node
            node.stop()
            node.volume = volume
            node.scheduleBuffer(buffer, at: time, options: [])
            node.play()
            let start = time?.hostTime ?? now
            padPlayers[index].availableAt = start + ticks(Double(buffer.frameLength) / format.sampleRate + ioDuration)
        }
    }

    private func activateSession() throws {
        try Self.sessionOwnership.acquire(for: sessionOwnerID)
        ioDuration = session.ioBufferDuration
    }

    private func outputTimingOnQueue() throws -> AudioOutputTiming {
        guard let timing = AudioOutputTiming(presentationLatency: engine.mainMixerNode.outputPresentationLatency) else {
            throw Failure.outputTimingUnavailable
        }
        return timing
    }

    private func renderTime(for audibleTime: UInt64) throws -> AVAudioTime {
        let timing = try outputTimingOnQueue()
        let renderSeconds = timing.renderTime(forAudibleTime: AVAudioTime.seconds(forHostTime: audibleTime))
        let now = mach_absolute_time()
        guard renderSeconds > 0 else { throw Failure.insufficientLeadTime }
        let renderHostTime = ticks(renderSeconds)
        guard renderHostTime > now + ticks(ioDuration) else {
            throw Failure.insufficientLeadTime
        }
        return AVAudioTime(hostTime: renderHostTime)
    }

    private func ticks(_ seconds: TimeInterval) -> UInt64 {
        AVAudioTime.hostTime(forSeconds: seconds)
    }

    private func scheduleMetronome() {
        guard var state = metronome, let clickBuffer, engine.isRunning else { return }
        let timing: AudioOutputTiming
        do { timing = try outputTimingOnQueue() }
        catch { failure = error; stopMetronomeOnQueue(); return }
        let now = mach_absolute_time()
        let earliest = now + ticks(timing.presentationLatency + ioDuration)
        let horizon = now + ticks(timing.presentationLatency + 0.1)
        while state.beatCount.map({ state.nextBeat < $0 }) ?? true {
            let audibleTime = state.firstAudibleTime + ticks(Double(state.nextBeat) * state.secondsPerBeat)
            guard audibleTime <= horizon else { break }
            state.nextBeat += 1
            // Never bunch missed beats after an OS scheduling stall.
            guard audibleTime > earliest else { continue }
            do { clickPlayer.scheduleBuffer(clickBuffer, at: try renderTime(for: audibleTime)) }
            catch { failure = error; stopMetronomeOnQueue(); return }
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
        if !clickOnly { clickPlayer.stop() }
    }

    private func stopPlayers() {
        calibrationCapture?.clockChanged = true
        stopMetronomeOnQueue()
        for index in padPlayers.indices {
            padPlayers[index].node.stop()
            padPlayers[index].availableAt = 0
        }
        for index in patternPlayers.indices {
            patternPlayers[index].node.stop()
            patternPlayers[index].availableAt = 0
        }
    }

    private func kitCatalog() throws -> KitCatalog {
        if let catalog { return catalog }
        guard padVoices.count == 16 else {
            throw Failure.invalidManifest("Expected sixteen pad voice names")
        }
        guard let manifest = bundle.url(forResource: "sample-kits", withExtension: "json", subdirectory: "Data")
            ?? bundle.url(forResource: "sample-kits", withExtension: "json") else {
            throw Failure.missingResource("sample-kits.json")
        }
        guard let root = bundle.url(forResource: "samples", withExtension: "bundle")
            ?? bundle.url(forResource: "Samples", withExtension: nil) else {
            throw Failure.missingResource("samples.bundle")
        }
        let definitions = try JSONDecoder().decode([String: SampleKitDefinition].self, from: Data(contentsOf: manifest))
        guard definitions[SoundKitResolver.fallbackKitId] != nil else {
            throw Failure.invalidManifest("Missing default acoustic kit")
        }
        var samples: [String: Result<[String: [SampleLayer]], Error>] = [:]
        for (id, definition) in definitions {
            let result = Result { try validateKit(id, definition: definition, root: root) }
            if case .failure(let error) = result {
                Self.logger.error("Kit \(id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
            samples[id] = result
        }
        let models = definitions.map { SampleKit(kitId: $0.key, definition: $0.value) }
            .sorted { $0.kitId < $1.kitId }
        let catalog = KitCatalog(models: models, samples: samples, gains: SampleGain.Table.load(from: bundle))
        self.catalog = catalog
        return catalog
    }

    private func validateKit(
        _ id: String, definition: SampleKitDefinition, root: URL
    ) throws -> [String: [SampleLayer]] {
        for voice in Set(padVoices) where definition.voices[voice] == nil {
            throw Failure.invalidManifest("\(id): missing \(voice)")
        }
        var voices: [String: [SampleLayer]] = [:]
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
                let urls = try paths.map { path in
                    let parts = path.split(separator: "/")
                    guard parts.count == 3, parts[0] == "samples",
                          !parts.contains(".."), !parts.contains(".") else {
                        throw Failure.invalidManifest("Invalid sample path: \(path)")
                    }
                    let url = root.appendingPathComponent(String(parts[1])).appendingPathComponent(String(parts[2]))
                    guard FileManager.default.fileExists(atPath: url.path) else {
                        throw Failure.missingResource(path)
                    }
                    return url
                }
                return SampleLayer(maxVelocity: entry.maxVel, urls: urls)
            }
        }
        return voices
    }

    private func decodeKit(_ id: String, catalog: KitCatalog) throws -> LoadedKit {
        #if DEBUG
        let started = DispatchTime.now()
        #endif
        guard let samples = catalog.samples[id] else { throw Failure.unknownKit(id) }
        var buffersByURL: [URL: AVAudioPCMBuffer] = [:]
        let voices = try samples.get().mapValues { layers in
            try layers.map { layer in
                let buffers = try layer.urls.map { url in
                    if let buffer = buffersByURL[url] { return buffer }
                    let buffer = try decodeSample(url)
                    buffersByURL[url] = buffer
                    return buffer
                }
                return Layer(maxVelocity: layer.maxVelocity, buffers: buffers)
            }
        }
        #if DEBUG
        Self.logDuration("kit \(id) loaded", since: started)
        #endif
        let gainsDB = Dictionary(uniqueKeysWithValues: voices.keys.map {
            ($0, catalog.gains.gainDB(kit: id, voice: $0))
        })
        return LoadedKit(voices: voices, gainsDB: gainsDB)
    }

    #if DEBUG
    static func logDuration(_ event: String, since started: DispatchTime) {
        let elapsed = Double(DispatchTime.now().uptimeNanoseconds - started.uptimeNanoseconds) / 1_000_000
        print("[Audio] \(event) \(String(format: "%.1f", elapsed)) ms")
    }

    static func logFootprint(lessonID: Int) {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return }
        let mib = Double(info.phys_footprint) / 1_048_576
        print("[Audio] lesson \(lessonID) footprint \(String(format: "%.1f", mib)) MiB")
    }
    #endif

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
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in self?.calibrationCapture?.clockChanged = true }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereLostNotification, object: session, queue: nil) { [weak self] _ in
            self?.queue.async { [weak self] in self?.calibrationCapture?.clockChanged = true }
        })
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: nil) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue
            let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? NSNumber)?.uintValue ?? 0
            self?.queue.async { [weak self] in
                guard let self else { return }
                if type == AVAudioSession.InterruptionType.began.rawValue {
                    self.interrupted = true
                    self.stopPlayers()
                    self.engine.pause()
                    self.reportRunAudioChange()
                } else if type == AVAudioSession.InterruptionType.ended.rawValue {
                    self.interrupted = false
                    if !self.schedulingFailed, options & AVAudioSession.InterruptionOptions.shouldResume.rawValue != 0 {
                        self.resumeAfterSessionChange()
                    }
                }
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: session, queue: nil) { [weak self] note in
            guard let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue else { return }
            let previous = note.userInfo?[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription
            let previousOutputs = previous?.outputs.map(\.uid)
            self?.queue.async { [weak self] in
                guard let self else { return }
                let outputsChanged = previousOutputs.map { $0 != self.session.currentRoute.outputs.map(\.uid) }
                guard Self.isOutputRouteChange(reason: reason, outputsChanged: self.clickOnly ? nil : outputsChanged) else {
                    return
                }
                if self.onRunAudioChange != nil {
                    self.stopPlayers()
                    self.engine.stop()
                    // The owner's stop path restarts idle audio on the new route.
                    self.reportRunAudioChange()
                } else if !self.schedulingFailed {
                    self.resumeAfterSessionChange()
                }
            }
        })
    }

    static func isOutputRouteChange(reason: UInt, outputsChanged: Bool?) -> Bool {
        switch AVAudioSession.RouteChangeReason(rawValue: reason) {
        case .categoryChange: return false // Ignore our own category setup.
        case .newDeviceAvailable, .oldDeviceUnavailable: return outputsChanged != false
        default: return true
        }
    }

    private func reportRunAudioChange() {
        guard let onRunAudioChange else { return }
        self.onRunAudioChange = nil
        schedulingFailed = true
        Task { @MainActor in onRunAudioChange() }
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
            engine.stop()
            try? Self.sessionOwnership.release(for: sessionOwnerID)
            failure = error
        }
    }
}
