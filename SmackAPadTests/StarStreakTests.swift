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

    func testWeakerPassKeepsCreditAndAddsNothing() {
        var streak = StarStreak()
        _ = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
        _ = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
        var stars = streak.record(passed: false, mastery: false, memory: false, requiredRuns: 4)
        XCTAssertEqual(streak.passedRuns, 2)
        XCTAssertEqual(streak.masteryRuns, 2)
        XCTAssertFalse(stars.passed)
        stars = streak.record(passed: true, mastery: false, memory: true, requiredRuns: 4)
        XCTAssertEqual(streak.passedRuns, 3)
        XCTAssertEqual(streak.masteryRuns, 2)
        stars = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
        XCTAssertTrue(stars.passed)
        XCTAssertFalse(stars.mastery)
    }

    func testIntroFirstStarNeedsOnlyTheHitCountRule() {
        var streak = StarStreak()
        let stars = streak.record(passed: true, mastery: true, memory: false, requiredRuns: 3, passedRequired: 1)
        XCTAssertTrue(stars.passed)
        XCTAssertFalse(stars.mastery)
    }

    func testResetClearsSessionCounters() {
        var streak = StarStreak()
        _ = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4)
        streak.reset()
        XCTAssertEqual(streak.passedRuns, 0)
        XCTAssertEqual(streak.masteryRuns, 0)
        XCTAssertEqual(streak.memoryRuns, 0)
    }
}
