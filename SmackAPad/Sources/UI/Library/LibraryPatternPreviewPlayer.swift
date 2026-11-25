import AVFoundation
import Foundation
import Observation

/// Pure timing and scheduling math for the Library pattern preview loop.
struct PreviewLoopTiming: Sendable {
    static let stepsPerBar = 16
    static let leadTimeSeconds: TimeInterval = 0.12
    static let scheduleHorizonSeconds: TimeInterval = 0.25

    let secondsPerStep: Double
    let totalSteps: Int

    init(bpm: Int, bars: Int) {
        let safeBpm = max(20, bpm)
        self.secondsPerStep = 15.0 / Double(safeBpm)
        self.totalSteps = max(Self.stepsPerBar, bars * Self.stepsPerBar)
    }

    var loopDurationSeconds: Double {
        Double(totalSteps) * secondsPerStep
    }

    /// Returns the fractional step within the 16-step first-bar strip (`0 ..< 16`), or `nil` before start.
    func barStepProgress(elapsedSeconds: Double) -> Double? {
        guard elapsedSeconds >= 0, secondsPerStep > 0 else { return nil }
        let total = elapsedSeconds / secondsPerStep
        return total.truncatingRemainder(dividingBy: Double(Self.stepsPerBar))
    }

    struct ScheduledStepHit: Equatable, Sendable {
        let timeSeconds: Double
        let padIndex: Int
        let velocity: Int
    }

    /// Collects all hits from `sortedHits` that fall in `[fromLoop, ...]` up to `horizonSeconds`.
    static func collectHits(
        sortedHits: [LessonHit],
        timing: PreviewLoopTiming,
        anchorSeconds: Double,
        horizonSeconds: Double,
        nextLoop: inout Int,
        nextHitIndex: inout Int
    ) -> [ScheduledStepHit] {
        guard !sortedHits.isEmpty else { return [] }
        var result: [ScheduledStepHit] = []
        let loopDuration = timing.loopDurationSeconds

        while true {
            if nextHitIndex >= sortedHits.count {
                nextHitIndex = 0
                nextLoop += 1
            }
            let hit = sortedHits[nextHitIndex]
            let hitTime = anchorSeconds
                + Double(nextLoop) * loopDuration
                + Double(max(0, hit.step)) * timing.secondsPerStep

            if hitTime > horizonSeconds {
                break
            }
            result.append(ScheduledStepHit(
                timeSeconds: hitTime,
                padIndex: hit.padIndex,
                velocity: hit.velocity
            ))
            nextHitIndex += 1
        }
        return result
    }
}

/// Manages single-row live audio preview playback on the Library screen.
@MainActor
@Observable
final class LibraryPatternPreviewPlayer {
    private(set) var playingLessonID: Int?
    private(set) var anchorHostTime: UInt64 = 0
    private(set) var secondsPerStep: Double = 0

    @ObservationIgnored private var playbackTask: Task<Void, Never>?
    @ObservationIgnored private var ownsAudio = false

    func toggle(lesson: Lesson, settings: SettingsManager) {
        if playingLessonID == lesson.id {
            stop(releaseAudio: false)
            return
        }
        start(lesson: lesson, settings: settings)
    }

    func stop(releaseAudio: Bool) {
        playbackTask?.cancel()
        playbackTask = nil
        playingLessonID = nil
        anchorHostTime = 0
        secondsPerStep = 0

        let audio = AudioEngine.practice
        audio.stopPatternPlayback()
        if releaseAudio, ownsAudio {
            ownsAudio = false
            audio.stop()
        }
    }

    private func start(lesson: Lesson, settings: SettingsManager) {
        stop(releaseAudio: false)
        playingLessonID = lesson.id

        let kitID = SoundKitResolver.resolveKitId(for: lesson, settings: settings)
        let timing = PreviewLoopTiming(bpm: lesson.targetBpm, bars: lesson.bars)
        let sortedHits = lesson.hits.sorted { $0.step < $1.step }
        let patternVolume = Float(settings.patternVolume) / 100
        let trims = settings.instrumentTrims

        playbackTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let audio = AudioEngine.practice
            do {
                _ = try await audio.prepare()
                try Task.checkCancellation()
                let kit = try await audio.loadKit(kitID)
                try Task.checkCancellation()
                guard self.playingLessonID == lesson.id else { return }

                audio.selectKit(kit)
                audio.setPatternVolume(patternVolume)
                audio.setInstrumentTrims(trims)
                if !audio.isRunning {
                    try audio.start()
                    self.ownsAudio = true
                }

                let startSeconds = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                    + PreviewLoopTiming.leadTimeSeconds
                let anchor = AVAudioTime.hostTime(forSeconds: startSeconds)
                self.anchorHostTime = anchor
                self.secondsPerStep = timing.secondsPerStep

                var nextLoop = 0
                var nextHitIndex = 0

                while !Task.isCancelled, self.playingLessonID == lesson.id {
                    let nowSeconds = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                    let horizon = nowSeconds + PreviewLoopTiming.scheduleHorizonSeconds
                    let hits = PreviewLoopTiming.collectHits(
                        sortedHits: sortedHits,
                        timing: timing,
                        anchorSeconds: startSeconds,
                        horizonSeconds: horizon,
                        nextLoop: &nextLoop,
                        nextHitIndex: &nextHitIndex
                    )
                    if !hits.isEmpty {
                        let sounds = hits.map { hit in
                            AudioEngine.ScheduledSound(
                                audibleHostTime: AVAudioTime.hostTime(forSeconds: hit.timeSeconds),
                                padIndex: hit.padIndex,
                                velocity: hit.velocity
                            )
                        }
                        audio.schedule(sounds) { [weak self] _ in
                            Task { @MainActor [weak self] in
                                self?.stop(releaseAudio: false)
                            }
                        }
                    }
                    try await Task.sleep(for: .milliseconds(50))
                }
            } catch {
                if !Task.isCancelled, self.playingLessonID == lesson.id {
                    self.stop(releaseAudio: false)
                }
            }
        }
    }
}
