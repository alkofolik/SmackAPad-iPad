import Darwin
import XCTest
@testable import SmackAPad

final class ScoringEngineTests: XCTestCase {
    // Exact millisecond offsets on the same native clock used by MIDI input.
    private let start: UInt64 = 10_000_000_000

    private func timestamp(_ milliseconds: Double) -> UInt64 {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let ticks = Int64((milliseconds * 1_000_000 * Double(timebase.denom) / Double(timebase.numer)).rounded())
        return ticks >= 0 ? start + UInt64(ticks) : start - UInt64(-ticks)
    }

    private func lesson(
        level: Int = 1, count: Int = 1, intro: Bool = false,
        hits: [LessonHit]? = nil, hits8: [LessonHit]? = nil
    ) -> Lesson {
        Lesson(
            id: 1, cat: intro ? "intro" : "starter", title: "Scoring fixture",
            genre: "test", tags: [], text: "", division: 16, bars: 3,
            startBpm: 60, targetBpm: 120, level: level, src: "test",
            hits: hits ?? (0..<count).map {
                LessonHit(step: $0 * 4, padIndex: 12, hand: "L", velocity: 100)
            }, hits8: hits8
        )
    }

    func testEveryLevelGradesBothSidesOfItsExactTimingWindows() {
        let cases: [(Int, Double, Double, Double)] = [
            (1, 45, 100, 200), (2, 45, 100, 200),
            (3, 38, 85, 175), (4, 38, 85, 175), (5, 30, 70, 150)
        ]
        for (level, perfect, good, maximum) in cases {
            let offsets: [(Double, HitJudgment)] = [
                (0, .perfect), (perfect, .perfect), (perfect + 0.01, .good),
                (good, .good), (good + 0.01, .off), (maximum, .off),
                (maximum + 0.01, .wrongPad)
            ]
            for (offset, expected) in offsets {
                for sign in [-1.0, 1.0] {
                    var engine = ScoringEngine(lesson: lesson(level: level), bpm: 120, startTimestamp: start)
                    XCTAssertEqual(engine.receive(padIndex: 12, at: timestamp(sign * offset)).judgment,
                                   expected, "Level \(level), offset \(sign * offset) ms")
                }
            }
        }
    }
}
