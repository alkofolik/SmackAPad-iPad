import AVFoundation
import Darwin
import Observation

/// Owns the guided flow. Only a completed, accepted measurement can change settings.
@MainActor
@Observable
final class CalibrationSession {
    enum Phase { case idle, preparing, countIn, measuring, completed, cancelled, failed }

    var deviceID = "touch"
    private(set) var phase: Phase = .idle
    private(set) var clickNumber = 0
    private(set) var matchedClicks: Set<Int> = []
    private(set) var result: CalibrationResult?
    private(set) var failure: CalibrationFailure?
    private(set) var audioError: String?

    @ObservationIgnored private let audio = AudioEngine()
    @ObservationIgnored private let settings: SettingsManager
    @ObservationIgnored private let midi: MIDIInput
    @ObservationIgnored private var measurement = CalibrationMeasurement()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var previousPadHandler: ((PadInputEvent) -> Void)?
    @ObservationIgnored private var previousNoteHandler: ((MIDINoteEvent) -> Void)?
    @ObservationIgnored private var previousSourceID: String?
    @ObservationIgnored private var attached = false
    @ObservationIgnored private var runID = UUID()

    init(settings: SettingsManager, midi: MIDIInput) {
        self.settings = settings
        self.midi = midi
        deviceID = midi.selectedSourceID ?? midi.sources.first?.id ?? "touch"
    }

    var busy: Bool { phase == .preparing || phase == .countIn || phase == .measuring }

    func attach() {
        guard !attached else { return }
        attached = true
        previousSourceID = midi.selectedSourceID
        previousPadHandler = midi.onPadEvent
        previousNoteHandler = midi.onNoteEvent
        midi.cancelLearning()
        midi.onNoteEvent = { [weak self] event in
            guard event.isNoteOn else { return }
            self?.receive(timestamp: event.timestamp, deviceID: event.deviceID)
        }
        midi.onPadEvent = { [weak self] event in
            guard event.isNoteOn, event.deviceID == "touch" else { return }
            self?.receive(timestamp: event.timestamp, deviceID: event.deviceID)
        }
    }

    func start() {
        guard attached, !busy,
              deviceID == "touch" || midi.sources.contains(where: { $0.id == deviceID }) else { return }
        let id = UUID()
        runID = id
        measurement = CalibrationMeasurement()
        result = nil; failure = nil; audioError = nil
        clickNumber = 0; matchedClicks = []
        phase = .preparing
        midi.selectedSourceID = deviceID == "touch" ? nil : deviceID
        task = Task { [weak self] in
            guard let self else { return }
            do {
                let engine = audio
                try await Task.detached(priority: .userInitiated) { try engine.prepare() }.value
                guard !Task.isCancelled, runID == id, attached else { return }
                try audio.start()
                let readyDeadline = AVAudioTime.seconds(forHostTime: mach_absolute_time()) + 1.5
                while !audio.calibrationClockReady {
                    if AVAudioTime.seconds(forHostTime: mach_absolute_time()) > readyDeadline {
                        fail(.audioClockChanged)
                        return
                    }
                    try await Task.sleep(for: .milliseconds(20))
                }
                try Task.checkCancellation()
                let first = try audio.startCalibrationClicks()
                phase = .countIn
                while !Task.isCancelled, runID == id, busy {
                    let snapshot = audio.calibrationSnapshot()
                    guard !snapshot.clockChanged else { fail(.audioClockChanged); return }
                    guard deviceID == "touch" || midi.sources.contains(where: { $0.id == deviceID }) else {
                        cancel()
                        return
                    }
                    let now = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                    let audible = snapshot.outputTimes.filter { $0 <= now }.count
                    let measured = Array(snapshot.outputTimes.dropFirst(4))
                    phase = audible > 4 ? .measuring : .countIn
                    clickNumber = audible > 4 ? min(10, audible - 4) : min(4, audible)
                    matchedClicks = measurement.matchedClickIndices(outputTimes: measured)
                    if snapshot.outputTimes.count == 14,
                       let last = measured.last, now >= last + 0.6 {
                        finish(outputTimes: measured)
                        return
                    }
                    // A missing render timestamp is an audio failure, never a planned-time fallback.
                    if now > first + 15 { fail(.audioClockChanged); return }
                    try await Task.sleep(for: .milliseconds(20))
                }
            } catch is CancellationError {
                // cancel()/close() already stopped playback and kept the previous offset.
            } catch {
                guard runID == id else { return }
                audioError = error.localizedDescription
                phase = .failed
                stopAudio()
            }
        }
    }

    func cancel() {
        guard busy else { return }
        phase = .cancelled
        runID = UUID()
        task?.cancel(); task = nil
        stopAudio()
    }

    func touch() {
        receive(timestamp: mach_absolute_time(), deviceID: "touch")
    }

    func close() {
        cancel()
        audio.stopCalibrationClicks()
        audio.stop()
        guard attached else { return }
        midi.onPadEvent = previousPadHandler
        midi.onNoteEvent = previousNoteHandler
        restoreSource()
        previousPadHandler = nil; previousNoteHandler = nil
        attached = false
    }

    private func receive(timestamp: UInt64, deviceID: String) {
        guard busy, phase != .preparing, self.deviceID == deviceID else { return }
        measurement.recordTap(at: AVAudioTime.seconds(forHostTime: timestamp))
    }

    private func finish(outputTimes: [Double]) {
        // Recheck the clock immediately before committing the measurement.
        switch measurement.finish(outputTimes: outputTimes, clockChanged: audio.calibrationSnapshot().clockChanged) {
        case .success(let value):
            settings.setCalibrationOffset(value.offsetMilliseconds, for: deviceID)
            result = value
            phase = .completed
            stopAudio()
        case .failure(let reason): fail(reason)
        }
    }

    private func fail(_ reason: CalibrationFailure) {
        failure = reason
        phase = .failed
        stopAudio()
    }

    private func stopAudio() {
        audio.stopCalibrationClicks()
        audio.stop()
        restoreSource()
    }

    private func restoreSource() {
        midi.selectedSourceID = previousSourceID.flatMap { saved in
            midi.sources.contains(where: { $0.id == saved }) ? saved : nil
        }
    }
}
