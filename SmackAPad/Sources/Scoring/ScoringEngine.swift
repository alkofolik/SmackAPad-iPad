import Darwin

/// Timing feedback is independent of score weight: every match counts equally.
public enum HitJudgment: Equatable, Sendable {
    case perfect, good, off, wrongPad
}

public struct HitFeedback: Equatable, Sendable {
    /// Index in the lesson's effective hits array (hits8 in eight-pad mode).
    public let expectedHitIndex: Int?
    public let judgment: HitJudgment
    /// Signed error after calibration and timing-center correction; nil for unmatched input.
    public let timingErrorMilliseconds: Double?
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
}

/// One pattern attempt, using native mach timestamps for both its start and input.
/// Call on a single serial owner. MIDI mapping/BLE fallback happen before receive().
public struct ScoringEngine: Sendable {
    private struct ExpectedHit: Sendable {
        let index: Int
        let padIndex: Int
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
    private var lastMatchedTimestampByPad: [Int: UInt64] = [:]
    private var extraHitCount = 0

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
            ExpectedHit(index: index, padIndex: hit.padIndex,
                        nanoseconds: Double(hit.step) * 15_000_000_000 / Double(bpm))
        }
        let windows: (Double, Double, Double)
        switch lesson.level {
        case 1...2: windows = (45, 100, 200)
        case 3...4: windows = (38, 85, 175)
        default: windows = (30, 70, 150)
        }
        perfectNanoseconds = windows.0 * 1_000_000
        goodNanoseconds = windows.1 * 1_000_000
        maximumNanoseconds = windows.2 * 1_000_000
    }

    /// The padIndex must already be resolved through the current controller/lesson layout.
    public mutating func receive(padIndex: Int, at timestamp: UInt64) -> HitFeedback {
        if let previous = lastMatchedTimestampByPad[padIndex] {
            let distance = timestamp >= previous ? timestamp - previous : previous - timestamp
            if Double(distance) * nanosecondsPerTick <= 30_000_000 {
                extraHitCount += 1
                return HitFeedback(expectedHitIndex: nil, judgment: .wrongPad, timingErrorMilliseconds: nil)
            }
        }
        let elapsed = timestamp >= startTimestamp
            ? Double(timestamp - startTimestamp) * nanosecondsPerTick
            : -Double(startTimestamp - timestamp) * nanosecondsPerTick
        // Calibration is the only latency compensation. Audio output latency belongs
        // to the audio scheduler and must never be added to this comparison.
        let calibrated = elapsed - calibrationOffsetNanoseconds
        let corrected = calibrated - timingCenterNanoseconds
        let candidate = expectedHits.filter {
            $0.padIndex == padIndex && !matchedIndices.contains($0.index) &&
            abs(corrected - $0.nanoseconds) <= maximumNanoseconds
        }.min { abs(corrected - $0.nanoseconds) < abs(corrected - $1.nanoseconds) }
        guard let candidate else {
            extraHitCount += 1
            return HitFeedback(expectedHitIndex: nil, judgment: .wrongPad, timingErrorMilliseconds: nil)
        }
        let error = corrected - candidate.nanoseconds
        matchedIndices.insert(candidate.index)
        lastMatchedTimestampByPad[padIndex] = timestamp
        let judgment: HitJudgment = abs(error) <= perfectNanoseconds ? .perfect
            : abs(error) <= goodNanoseconds ? .good : .off
        // Learn only matched, calibration-corrected errors within ±110 ms. Using
        // errors before the adaptive shift prevents feeding the correction back
        // into itself. Grade this hit before learning from it.
        let sample = calibrated - candidate.nanoseconds
        if abs(sample) <= 110_000_000 {
            timingSamples.append(sample)
            if timingSamples.count > 8 { timingSamples.removeFirst() }
            let sorted = timingSamples.sorted()
            let middle = sorted.count / 2
            timingCenterNanoseconds = sorted.count.isMultiple(of: 2)
                ? (sorted[middle - 1] + sorted[middle]) / 2
                : sorted[middle]
        }
        return HitFeedback(expectedHitIndex: candidate.index, judgment: judgment,
                           timingErrorMilliseconds: error / 1_000_000)
    }

    /// Snapshot once the caller has stopped input after the last maximum timing window.
    /// Remaining unmatched notes are misses. This does not mutate tempo or persist progress;
    /// consuming the same summary twice cannot advance tempo twice.
    public func finish() -> ScoringResult {
        let expected = expectedHits.count
        let matches = matchedIndices.count
        let denominator = expected + extraHitCount
        let score = denominator > 0 ? Double(matches) / Double(denominator) : 0
        let allowedErrors = isIntro || expected <= 15 ? 0 : expected <= 32 ? 1 : 2
        let clean = expected > 0 && expected - matches + extraHitCount <= allowedErrors
        return ScoringResult(
            expectedHitCount: expected, matchedHitCount: matches, extraHitCount: extraHitCount,
            score: score, passed: expected > 0 && score >= (isIntro ? 0.8 : 0.7),
            isCleanRun: clean, mastery: clean && bpm >= targetBpm,
            bpm: bpm, nextBpm: clean && bpm < targetBpm ? bpm + min(bpmStep.rawValue, targetBpm - bpm) : bpm
        )
    }
}
