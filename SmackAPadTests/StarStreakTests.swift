import XCTest
@testable import SmackAPad

final class StarStreakTests: XCTestCase {
    func testRequiredRunsFollowHitCountAndKeepTheIntroMinimum() {
        for (hits, required) in [(4, 4), (6, 3), (8, 2), (16, 1)] {
            XCTAssertEqual(StarStreak.requiredRuns(expectedHits: hits), required, "\(hits) expected hits")
        }
        XCTAssertEqual(StarStreak.requiredRuns(expectedHits: 4, isIntro: true), 4)
        XCTAssertEqual(StarStreak.requiredRuns(expectedHits: 16, isIntro: true), 3)
    }

    func testEachStarNeedsItsOwnConsecutiveQualifyingPasses() {
        var streak = StarStreak()
        for _ in 0..<2 {
            let stars = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
            XCTAssertFalse(stars.passed)
            XCTAssertFalse(stars.mastery)
            XCTAssertFalse(stars.memory)
        }
        // Missing the clean-run requirement resets only the goal-tempo streak.
        var stars = streak.record(passed: true, mastery: false, memory: true, requiredRuns: 4)
        XCTAssertFalse(stars.passed)
        XCTAssertFalse(stars.mastery)
        XCTAssertFalse(stars.memory)
        stars = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
        XCTAssertTrue(stars.passed)
        XCTAssertFalse(stars.mastery)
        XCTAssertTrue(stars.memory)
        // A failed memory pass must not erase either of the other streaks.
        stars = streak.record(passed: true, mastery: true, memory: false, requiredRuns: 4)
        XCTAssertTrue(stars.passed)
        XCTAssertFalse(stars.mastery)
        XCTAssertFalse(stars.memory)
        for _ in 0..<2 {
            stars = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
        }
        XCTAssertTrue(stars.mastery)
        XCTAssertFalse(stars.memory)
        stars = streak.record(passed: false, mastery: false, memory: false, requiredRuns: 4)
        XCTAssertFalse(stars.passed)
        XCTAssertFalse(stars.mastery)
        XCTAssertFalse(stars.memory)
    }

    func testNewRunsClearAllCountersAndTempoChangesKeepPassedProgress() {
        var streak = StarStreak()
        for (index, bpm) in [60, 70, 80, 90].enumerated() {
            let stars = streak.record(passed: true, mastery: bpm >= 80, memory: false, requiredRuns: 4)
            XCTAssertEqual(stars.passed, index == 3)
            XCTAssertFalse(stars.mastery)
        }
        // START, RESTART and STOP share this reset; no partial streak crosses a run boundary.
        for _ in 0..<3 {
            streak.reset()
            XCTAssertEqual(streak.passedRuns, 0)
            XCTAssertEqual(streak.masteryRuns, 0)
            XCTAssertEqual(streak.memoryRuns, 0)
            for _ in 0..<3 {
                let stars = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
                XCTAssertFalse(stars.passed)
                XCTAssertFalse(stars.mastery)
                XCTAssertFalse(stars.memory)
            }
        }
        streak.reset()
        let longLesson = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 1)
        XCTAssertTrue(longLesson.passed)
        XCTAssertTrue(longLesson.mastery)
        XCTAssertTrue(longLesson.memory)
    }
}
