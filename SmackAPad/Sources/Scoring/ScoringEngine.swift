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
    private var matchedIndices: Set<Int> = []

    public init(lesson: Lesson, bpm: Int, startTimestamp: UInt64, padCount: Int = 16) {
        precondition(bpm > 0 && (1...5).contains(lesson.level))
        precondition(padCount == 8 || padCount == 16)
        self.startTimestamp = startTimestamp
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
        let elapsed = timestamp >= startTimestamp
            ? Double(timestamp - startTimestamp) * nanosecondsPerTick
            : -Double(startTimestamp - timestamp) * nanosecondsPerTick
        let candidate = expectedHits.filter {
            $0.padIndex == padIndex && !matchedIndices.contains($0.index) &&
            abs(elapsed - $0.nanoseconds) <= maximumNanoseconds
        }.min { abs(elapsed - $0.nanoseconds) < abs(elapsed - $1.nanoseconds) }
        guard let candidate else {
            return HitFeedback(expectedHitIndex: nil, judgment: .wrongPad, timingErrorMilliseconds: nil)
        }
        let error = elapsed - candidate.nanoseconds
        matchedIndices.insert(candidate.index)
        let judgment: HitJudgment = abs(error) <= perfectNanoseconds ? .perfect
            : abs(error) <= goodNanoseconds ? .good : .off
        return HitFeedback(expectedHitIndex: candidate.index, judgment: judgment,
                           timingErrorMilliseconds: error / 1_000_000)
    }
}
