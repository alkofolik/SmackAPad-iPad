import Darwin

/// Scoring thresholds and constants.
public enum Scoring {
    public static let passMark: Double = LearningRules.passMark
}

/// Timing feedback is independent of score weight: every match counts equally.
public enum HitJudgment: Equatable, Sendable {
    case perfect, good, off, wrongPad, ignored
}

public struct HitFeedback: Equatable, Sendable {
    /// Index in the lesson's effective hits array (hits8 in eight-pad mode).
    public let expectedHitIndex: Int?
    public let expectedStep: Int?
    public let judgment: HitJudgment
    /// Signed error after calibration and timing-center correction; nil for unmatched input.
    public let timingErrorMilliseconds: Double?
    /// Signed error after calibration only, for display and storage; nil for unmatched input.
    public let calibratedTimingErrorMilliseconds: Double?

    public init(
        expectedHitIndex: Int?,
        expectedStep: Int? = nil,
        judgment: HitJudgment,
        timingErrorMilliseconds: Double?,
        calibratedTimingErrorMilliseconds: Double? = nil
    ) {
        self.expectedHitIndex = expectedHitIndex
        self.expectedStep = expectedStep
        self.judgment = judgment
        self.timingErrorMilliseconds = timingErrorMilliseconds
        self.calibratedTimingErrorMilliseconds = calibratedTimingErrorMilliseconds
    }
}

/// Immutable attempt summary. Score is a fraction (0...1), as in persisted progress.
public struct ScoringResult: Equatable, Sendable {
    public let expectedHitCount: Int
    public let matchedHitCount: Int
    public let extraHitCount: Int
    public var missedHitCount: Int { expectedHitCount - matchedHitCount }
    public var errorCount: Int { missedHitCount + extraHitCount }
    public let score: Double
    public let passed: Bool
    public let isCleanRun: Bool
    public let mastery: Bool
    public let bpm: Int
    public let nextBpm: Int
    public var perfectOrGoodHitCount: Int = 0
}

/// One pattern attempt, using native mach timestamps for both its start and input.
/// Call on a single serial owner. MIDI mapping/BLE fallback happen before receive().
public struct ScoringEngine: Sendable {
    private struct ExpectedHit: Sendable {
        let index: Int
        let padIndex: Int
        let step: Int
        let nanoseconds: Double
    }

    private let expectedHits: [ExpectedHit]
    private let startTimestamp: UInt64
    private let nanosecondsPerTick: Double
    private let perfectNanoseconds: Double
    private let goodNanoseconds: Double
    private let maximumNanoseconds: Double
    private let calibrationOffsetNanoseconds: Double
    private let bpm: Int
    private let targetBpm: Int
    private let isIntro: Bool
    private let bpmStep: BpmStep
    private var matchedIndices: Set<Int> = []
    private var timingSamples: [Double] = []
    private var timingCenterNanoseconds: Double = 0
    private var lastAcceptedTimestampByPad: [Int: UInt64] = [:]
    private var perfectOrGoodHitCount = 0
    private var extraHitCount = 0
    private var consecutiveExtraHits = 0
    private var lastEvaluationTimestamp: UInt64?
    private var currentEvaluationCenterNanoseconds: Double = 0

    /// Read-only presentation scales, derived from the actual scoring windows.
    public var maximumTimingMilliseconds: Double { maximumNanoseconds / 1_000_000 }
    public var goodTimingMilliseconds: Double { goodNanoseconds / 1_000_000 }
    public var currentTimingCenterMilliseconds: Double { timingCenterNanoseconds / 1_000_000 }

    public init(
        lesson: Lesson, bpm: Int, startTimestamp: UInt64, padCount: Int = 16,
        calibrationOffsetMilliseconds: Double = 0, bpmStep: BpmStep = .defaultStep
    ) {
        precondition(bpm > 0 && (1...5).contains(lesson.level))
        precondition(padCount == 8 || padCount == 16)
        precondition(calibrationOffsetMilliseconds.isFinite)
        self.startTimestamp = startTimestamp
        calibrationOffsetNanoseconds = calibrationOffsetMilliseconds * 1_000_000
        self.bpm = bpm
        targetBpm = lesson.targetBpm
        isIntro = lesson.cat == "intro"
        self.bpmStep = bpmStep
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        nanosecondsPerTick = Double(timebase.numer) / Double(timebase.denom)
        expectedHits = lesson.hits(forPadCount: padCount).enumerated().map { index, hit in
            ExpectedHit(index: index, padIndex: hit.padIndex, step: hit.step,
                        nanoseconds: Double(hit.step) * 15_000_000_000 / Double(bpm))
        }
        let windows: (Double, Double, Double)
        switch lesson.level {
        case 1...LearningRules.beginnerTimingMaximumLevel: windows = LearningRules.beginnerTimingMilliseconds
        case (LearningRules.beginnerTimingMaximumLevel + 1)...LearningRules.intermediateTimingMaximumLevel: windows = LearningRules.intermediateTimingMilliseconds
        default: windows = LearningRules.advancedTimingMilliseconds
        }
        perfectNanoseconds = windows.0 * 1_000_000
        goodNanoseconds = windows.1 * 1_000_000
        maximumNanoseconds = windows.2 * 1_000_000
    }

    /// The padIndex must already be resolved through the current controller/lesson layout.
    public mutating func receive(padIndex: Int, at timestamp: UInt64) -> HitFeedback {
        if let previous = lastAcceptedTimestampByPad[padIndex] {
            let distance = timestamp >= previous ? timestamp - previous : previous - timestamp
            if Double(distance) * nanosecondsPerTick <= LearningRules.duplicateHitWindowNanoseconds {
                return HitFeedback(expectedHitIndex: nil, expectedStep: nil, judgment: .ignored, timingErrorMilliseconds: nil)
            }
        }
        lastAcceptedTimestampByPad[padIndex] = timestamp
        let elapsed = timestamp >= startTimestamp
            ? Double(timestamp - startTimestamp) * nanosecondsPerTick
            : -Double(startTimestamp - timestamp) * nanosecondsPerTick
        // Calibration is the only latency compensation. Audio output latency belongs
        // to the audio scheduler and must never be added to this comparison.
        let calibrated = elapsed - calibrationOffsetNanoseconds
        if lastEvaluationTimestamp == nil || timestamp != lastEvaluationTimestamp {
            lastEvaluationTimestamp = timestamp
            currentEvaluationCenterNanoseconds = timingCenterNanoseconds
        }
        let corrected = calibrated - currentEvaluationCenterNanoseconds
        let candidate = expectedHits.filter {
            $0.padIndex == padIndex && !matchedIndices.contains($0.index) &&
            abs(corrected - $0.nanoseconds) <= maximumNanoseconds
        }.min { abs(corrected - $0.nanoseconds) < abs(corrected - $1.nanoseconds) }
        guard let candidate else {
            extraHitCount += 1
            consecutiveExtraHits += 1
            if consecutiveExtraHits >= LearningRules.extraHitsToResetTimingCenter && timingCenterNanoseconds != 0 {
                timingCenterNanoseconds = 0
                currentEvaluationCenterNanoseconds = 0
                timingSamples.removeAll()
            }
            return HitFeedback(expectedHitIndex: nil, expectedStep: nil, judgment: .wrongPad, timingErrorMilliseconds: nil)
        }
        consecutiveExtraHits = 0
        let error = corrected - candidate.nanoseconds
        matchedIndices.insert(candidate.index)
        let judgment: HitJudgment = abs(error) <= perfectNanoseconds ? .perfect
            : abs(error) <= goodNanoseconds ? .good : .off
        if judgment == .perfect || judgment == .good { perfectOrGoodHitCount += 1 }
        // Learn only matched, calibration-corrected errors within ±110 ms. Using
        // errors before the adaptive shift prevents feeding the correction back
        // into itself. Grade this hit before learning from it.
        let sample = calibrated - candidate.nanoseconds
        if abs(sample) <= LearningRules.timingCenterSampleLimitNanoseconds {
            timingSamples.append(sample)
            if timingSamples.count > LearningRules.timingCenterSampleCount { timingSamples.removeFirst() }
            let sorted = timingSamples.sorted()
            let middle = sorted.count / 2
            timingCenterNanoseconds = sorted.count.isMultiple(of: 2)
                ? (sorted[middle - 1] + sorted[middle]) / 2
                : sorted[middle]
        }
        return HitFeedback(expectedHitIndex: candidate.index, expectedStep: candidate.step, judgment: judgment,
                           timingErrorMilliseconds: error / 1_000_000,
                           calibratedTimingErrorMilliseconds: sample / 1_000_000)
    }

    /// Snapshot once the caller has stopped input after the last maximum timing window.
    /// Remaining unmatched notes are misses. This does not mutate tempo or persist progress;
    /// consuming the same summary twice cannot advance tempo twice.
    public func finish() -> ScoringResult {
        let expected = expectedHits.count
        let matches = matchedIndices.count
        let denominator = expected + extraHitCount
        let score = denominator > 0 ? Double(matches) / Double(denominator) : 0
        let allowedErrors = isIntro || expected <= LearningRules.shortCleanRunMaximumHits
            ? LearningRules.shortCleanRunAllowedErrors
            : expected <= LearningRules.mediumCleanRunMaximumHits
                ? LearningRules.mediumCleanRunAllowedErrors : LearningRules.longCleanRunAllowedErrors
        let clean = expected > 0 && expected - matches + extraHitCount <= allowedErrors
        return ScoringResult(
            expectedHitCount: expected, matchedHitCount: matches, extraHitCount: extraHitCount,
            score: score, passed: expected > 0 && score >= Scoring.passMark,
            isCleanRun: clean, mastery: clean && bpm >= targetBpm,
            bpm: bpm, nextBpm: clean && bpm < targetBpm ? bpm + min(bpmStep.rawValue, targetBpm - bpm) : bpm,
            perfectOrGoodHitCount: perfectOrGoodHitCount
        )
    }

    /// Evaluates the pattern attempt as known so far at the given host timestamp.
    /// Notes whose matching window has closed or which were already matched are evaluated;
    /// unhit notes still inside their window are left out of this decision.
    public func earlyResult(at timestamp: UInt64) -> ScoringResult {
        let elapsed = timestamp >= startTimestamp
            ? Double(timestamp - startTimestamp) * nanosecondsPerTick
            : -Double(startTimestamp - timestamp) * nanosecondsPerTick
        let calibrated = elapsed - calibrationOffsetNanoseconds
        let corrected = calibrated - timingCenterNanoseconds
        let evaluatedHits = expectedHits.filter {
            corrected >= $0.nanoseconds + maximumNanoseconds || matchedIndices.contains($0.index)
        }
        let matches = evaluatedHits.filter { matchedIndices.contains($0.index) }.count
        let misses = evaluatedHits.count - matches
        let denominator = evaluatedHits.count + extraHitCount
        let score = denominator > 0 ? Double(matches) / Double(denominator) : 0
        let allowedErrors = isIntro || expectedHits.count <= LearningRules.shortCleanRunMaximumHits
            ? LearningRules.shortCleanRunAllowedErrors
            : expectedHits.count <= LearningRules.mediumCleanRunMaximumHits
                ? LearningRules.mediumCleanRunAllowedErrors : LearningRules.longCleanRunAllowedErrors
        let clean = !evaluatedHits.isEmpty && misses + extraHitCount <= allowedErrors
        return ScoringResult(
            expectedHitCount: evaluatedHits.count,
            matchedHitCount: matches,
            extraHitCount: extraHitCount,
            score: score,
            passed: !evaluatedHits.isEmpty && score >= Scoring.passMark,
            isCleanRun: clean,
            mastery: clean && bpm >= targetBpm,
            bpm: bpm,
            nextBpm: clean && bpm < targetBpm ? bpm + min(bpmStep.rawValue, targetBpm - bpm) : bpm,
            perfectOrGoodHitCount: perfectOrGoodHitCount
        )
    }
}
