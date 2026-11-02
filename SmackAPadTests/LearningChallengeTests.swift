import XCTest
@testable import SmackAPad

final class LearningChallengeTests: XCTestCase {
    func testModesKeepLearningCreditAndResetOnlyFailedChallengeStars() {
        var learning = StarStreak()
        var challenge = StarStreak()
        for mode in [PracticeMode.learning, .challenge] {
            var streak = StarStreak()
            _ = streak.record(passed: true, mastery: true, memory: true, requiredRuns: 4, mode: mode)
            _ = streak.record(passed: true, mastery: false, memory: true, requiredRuns: 4, mode: mode)
            if mode == .learning { learning = streak } else { challenge = streak }
        }
        XCTAssertEqual(learning.passedRuns, 2)
        XCTAssertEqual(learning.masteryRuns, 1)
        XCTAssertEqual(learning.memoryRuns, 2)
        XCTAssertEqual(challenge.passedRuns, 2)
        XCTAssertEqual(challenge.masteryRuns, 0)
        XCTAssertEqual(challenge.memoryRuns, 2)
        _ = learning.record(passed: false, mastery: false, memory: false, requiredRuns: 4, mode: .learning)
        XCTAssertEqual(learning.passedRuns, 2)
        XCTAssertEqual(learning.memoryRuns, 2)
    }

    func testLearningAlternativeFirstStarBoundaries() {
        func qualifies(_ score: Double, _ good: Int, _ expected: Int, _ errors: Int) -> Bool {
            StarStreak.learningPassed(score: score, perfectOrGoodHits: good,
                                      expectedHits: expected, errors: errors)
        }
        XCTAssertTrue(qualifies(0.60, 17, 20, 2))
        XCTAssertFalse(qualifies(0.599, 17, 20, 2))
        XCTAssertFalse(qualifies(0.60, 16, 20, 2))
        for (expected, good, budget) in [(4, 4, 1), (16, 14, 1), (40, 34, 4)] {
            XCTAssertTrue(qualifies(0.60, good, expected, budget))
            XCTAssertFalse(qualifies(0.60, good, expected, budget + 1))
            XCTAssertFalse(qualifies(0.60, good - 1, expected, 0))
        }
        XCTAssertFalse(qualifies(1, 0, 0, 0))
    }
}
