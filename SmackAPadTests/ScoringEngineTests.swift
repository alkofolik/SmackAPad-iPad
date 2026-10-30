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

    func testSignedCalibrationOffsetIsSubtractedExactlyOnce() {
        for offset in [-125.0, 125.0] {
            var engine = ScoringEngine(
                lesson: lesson(level: 5), bpm: 120, startTimestamp: start,
                calibrationOffsetMilliseconds: offset
            )
            let feedback = engine.receive(padIndex: 12, at: timestamp(offset))
            XCTAssertEqual(feedback.judgment, .perfect)
            XCTAssertEqual(feedback.timingErrorMilliseconds ?? .infinity, 0, accuracy: 0.0001)
        }
    }

    func testAdaptiveCenterUsesTheLastEightCalibratedErrorsAndTheirMedian() {
        var engine = ScoringEngine(
            lesson: lesson(count: 13), bpm: 120, startTimestamp: start,
            calibrationOffsetMilliseconds: 125
        )
        // The first four zeros must eventually fall out of the eight-sample window.
        let errors: [Double] = [0, 0, 0, 0, 20, 20, 20, 40, 80, 80, 80, 100]
        for (index, error) in errors.enumerated() {
            let feedback = engine.receive(padIndex: 12, at: timestamp(Double(index) * 500 + 125 + error))
            XCTAssertEqual(feedback.expectedHitIndex, index)
        }
        // Last eight = [20,20,20,40,80,80,80,100], median = 60 (mean = 55).
        let feedback = engine.receive(padIndex: 12, at: timestamp(6_185))
        XCTAssertEqual(feedback.judgment, .perfect)
        XCTAssertEqual(feedback.timingErrorMilliseconds ?? .infinity, 0, accuracy: 0.0001)
    }

    func testAdaptiveCenterAcceptsSignedGateBoundaryButRejectsOutliersAndUnmatchedInput() {
        for sign in [-1.0, 1.0] {
            var engine = ScoringEngine(lesson: lesson(count: 11), bpm: 120, startTimestamp: start)
            _ = engine.receive(padIndex: 12, at: timestamp(sign * 110))
            // These matches are within the scoring window but outside the learning gate.
            for index in 1...8 {
                _ = engine.receive(padIndex: 12, at: timestamp(Double(index) * 500 + sign * 110.01))
                _ = engine.receive(padIndex: 13, at: timestamp(Double(index) * 500 + sign * 110.01))
            }
            let feedback = engine.receive(padIndex: 12, at: timestamp(4_500 + sign * 110))
            XCTAssertEqual(feedback.timingErrorMilliseconds ?? .infinity, 0, accuracy: 0.0001)
        }
    }

    func testAdaptiveCenterShiftsBothWindowEdgesWithoutWideningThem() {
        var learned = ScoringEngine(lesson: lesson(count: 9), bpm: 120, startTimestamp: start)
        for index in 0..<8 {
            _ = learned.receive(padIndex: 12, at: timestamp(Double(index) * 500 + 80))
        }
        for (error, expected) in [(280.0, HitJudgment.off), (280.01, .wrongPad),
                                  (-120.0, .off), (-120.01, .wrongPad)] {
            var engine = learned
            XCTAssertEqual(engine.receive(padIndex: 12, at: timestamp(4_000 + error)).judgment, expected)
        }
    }

    func testDoubleHitGuardUsesRawTimeAndOnlyPreviouslyMatchedHitsOnTheSamePad() {
        let pattern = [
            LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100),
            LessonHit(step: 1, padIndex: 12, hand: "L", velocity: 100),
            LessonHit(step: 1, padIndex: 13, hand: "R", velocity: 100)
        ]
        // At 300 BPM a sixteenth is 50 ms. The first 20 ms error moves the
        // adaptive center; the guard must still compare raw input timestamps.
        var matched = ScoringEngine(lesson: lesson(hits: pattern), bpm: 300, startTimestamp: start)
        _ = matched.receive(padIndex: 12, at: timestamp(20))
        for delay in [0.0, 29.99, 30.0] {
            var engine = matched
            let blocked = engine.receive(padIndex: 12, at: timestamp(20 + delay))
            XCTAssertEqual(blocked.judgment, .wrongPad)
            XCTAssertNil(blocked.expectedHitIndex)
            // Rejection must not consume the second expected note or train the center.
            let next = engine.receive(padIndex: 12, at: timestamp(70))
            XCTAssertEqual(next.expectedHitIndex, 1)
            XCTAssertEqual(next.timingErrorMilliseconds ?? .infinity, 0, accuracy: 0.0001)
        }
        var boundary = matched
        XCTAssertEqual(boundary.receive(padIndex: 12, at: timestamp(50.01)).expectedHitIndex, 1)
        XCTAssertEqual(matched.receive(padIndex: 13, at: timestamp(45)).expectedHitIndex, 2)

        var unmatched = ScoringEngine(lesson: lesson(), bpm: 120, startTimestamp: start)
        XCTAssertEqual(unmatched.receive(padIndex: 12, at: timestamp(-220)).judgment, .wrongPad)
        XCTAssertEqual(unmatched.receive(padIndex: 12, at: timestamp(-195)).expectedHitIndex, 0)
    }

    func testResultCountsMissesAndExtrasAndUsesTheConfirmedScoreFormula() {
        var engine = ScoringEngine(lesson: lesson(count: 10), bpm: 120, startTimestamp: start)
        for index in 0..<8 {
            _ = engine.receive(padIndex: 12, at: timestamp(Double(index) * 500))
        }
        _ = engine.receive(padIndex: 13, at: timestamp(4_000))
        _ = engine.receive(padIndex: 13, at: timestamp(4_500))
        let result = engine.finish()
        XCTAssertEqual(result.expectedHitCount, 10)
        XCTAssertEqual(result.matchedHitCount, 8)
        XCTAssertEqual(result.missedHitCount, 2)
        XCTAssertEqual(result.extraHitCount, 2)
        XCTAssertEqual(result.errorCount, 4)
        XCTAssertEqual(result.score, 0.6666666667, accuracy: 0.000000001)
        XCTAssertFalse(result.passed)
        XCTAssertFalse(result.isCleanRun)
        XCTAssertFalse(result.mastery)
    }

    func testPerfectGoodAndOffHaveEqualScoreWeightAndAreNotErrors() {
        var engine = ScoringEngine(lesson: lesson(count: 3), bpm: 120, startTimestamp: start)
        XCTAssertEqual(engine.receive(padIndex: 12, at: timestamp(0)).judgment, .perfect)
        XCTAssertEqual(engine.receive(padIndex: 12, at: timestamp(580)).judgment, .good)
        XCTAssertEqual(engine.receive(padIndex: 12, at: timestamp(1_150)).judgment, .off)
        let result = engine.finish()
        XCTAssertEqual(result.score, 1)
        XCTAssertEqual(result.errorCount, 0)
        XCTAssertTrue(result.mastery)
    }

    func testPassIncludesSeventyPercentAndIntroRequiresEightyPercent() {
        let cases = [(false, 6, false), (false, 7, true), (true, 7, false), (true, 8, true)]
        for (intro, matches, passed) in cases {
            var engine = ScoringEngine(lesson: lesson(count: 10, intro: intro), bpm: 120, startTimestamp: start)
            for index in 0..<matches {
                _ = engine.receive(padIndex: 12, at: timestamp(Double(index) * 500))
            }
            XCTAssertEqual(engine.finish().passed, passed)
        }
    }

    func testMasteryUsesExpectedHitErrorLimitsAndRequiresTargetTempo() {
        for (count, allowed) in [(15, 0), (16, 1), (32, 1), (33, 2)] {
            let pattern = (0..<count).map { LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100) }
            for bpm in [119, 120, 121] {
                for errors in [allowed, allowed + 1] {
                    var engine = ScoringEngine(lesson: lesson(hits: pattern), bpm: bpm, startTimestamp: start)
                    for index in 0..<(count - errors) {
                        _ = engine.receive(padIndex: 12, at: timestamp(Double(index) * 15_000 / Double(bpm)))
                    }
                    let result = engine.finish()
                    XCTAssertEqual(result.isCleanRun, errors == allowed, "\(count) hits, \(errors) misses")
                    XCTAssertEqual(result.mastery, errors == allowed && bpm >= 120)
                }
            }
        }
    }

    func testIntroAlwaysRequiresZeroErrorsAndExtrasConsumeTheCleanRunAllowance() {
        for intro in [false, true] {
            var engine = ScoringEngine(lesson: lesson(count: 16, intro: intro), bpm: 120, startTimestamp: start)
            for index in 0..<15 {
                _ = engine.receive(padIndex: 12, at: timestamp(Double(index) * 500))
            }
            XCTAssertEqual(engine.finish().isCleanRun, !intro)
            _ = engine.receive(padIndex: 13, at: timestamp(7_500))
            XCTAssertFalse(engine.finish().isCleanRun)
            XCTAssertEqual(engine.finish().errorCount, 2)
        }
        var empty = ScoringEngine(lesson: lesson(count: 0), bpm: 120, startTimestamp: start)
        XCTAssertEqual(empty.finish().score, 0)
        XCTAssertFalse(empty.finish().passed)
        XCTAssertFalse(empty.finish().isCleanRun)
        XCTAssertFalse(empty.finish().mastery)
        _ = empty.receive(padIndex: 12, at: timestamp(0))
        XCTAssertEqual(empty.finish().score, 0)
    }

    func testEightPadResultUsesEffectiveHitsAndOneExpectedNoteCannotMatchTwice() {
        let simplified = [LessonHit(step: 0, padIndex: 13, hand: "L", velocity: 100)]
        var engine = ScoringEngine(
            lesson: lesson(count: 16, hits8: simplified), bpm: 120, startTimestamp: start, padCount: 8
        )
        XCTAssertEqual(engine.receive(padIndex: 13, at: timestamp(0)).expectedHitIndex, 0)
        XCTAssertEqual(engine.receive(padIndex: 13, at: timestamp(30)).judgment, .wrongPad)
        XCTAssertEqual(engine.receive(padIndex: 13, at: timestamp(100)).judgment, .wrongPad)
        let result = engine.finish()
        XCTAssertEqual(result.expectedHitCount, 1)
        XCTAssertEqual(result.matchedHitCount, 1)
        XCTAssertEqual(result.extraHitCount, 2)
        XCTAssertEqual(result.score, 0.3333333333, accuracy: 0.000000001)
        XCTAssertFalse(result.mastery)
    }

    func testCleanRunBelowTargetAdvancesByTheSelectedStepWithoutPassingTarget() {
        let cases: [(BpmStep, Int)] = [(.one, 101), (.two, 102), (.five, 105), (.ten, 110)]
        for (step, next) in cases {
            var engine = ScoringEngine(lesson: lesson(), bpm: 100, startTimestamp: start, bpmStep: step)
            _ = engine.receive(padIndex: 12, at: timestamp(0))
            let result = engine.finish()
            XCTAssertTrue(result.isCleanRun)
            XCTAssertFalse(result.mastery)
            XCTAssertEqual(result.bpm, 100)
            XCTAssertEqual(result.nextBpm, next)
            XCTAssertEqual(engine.finish(), result)
        }
        var nearTarget = ScoringEngine(lesson: lesson(), bpm: 118, startTimestamp: start, bpmStep: .ten)
        _ = nearTarget.receive(padIndex: 12, at: timestamp(0))
        XCTAssertEqual(nearTarget.finish().nextBpm, 120)

        for bpm in [120, 125] {
            var engine = ScoringEngine(lesson: lesson(), bpm: bpm, startTimestamp: start, bpmStep: .ten)
            _ = engine.receive(padIndex: 12, at: timestamp(0))
            XCTAssertTrue(engine.finish().mastery)
            XCTAssertEqual(engine.finish().nextBpm, bpm)
        }
        var dirty = ScoringEngine(lesson: lesson(count: 2), bpm: 100, startTimestamp: start, bpmStep: .ten)
        _ = dirty.receive(padIndex: 12, at: timestamp(0))
        XCTAssertFalse(dirty.finish().isCleanRun)
        XCTAssertEqual(dirty.finish().nextBpm, 100)
        let empty = ScoringEngine(lesson: lesson(count: 0), bpm: 100, startTimestamp: start, bpmStep: .ten)
        XCTAssertEqual(empty.finish().nextBpm, 100)
    }
}
