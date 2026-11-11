import XCTest
@testable import SmackAPad

final class MemoryStarRuleTests: XCTestCase {
    // 1. same day → no credit
    func testSameDayDoesNotEarnMemoryCredit() {
        let qualifies = StarStreak.mayEarnMemoryCredit(
            masteryDay: "2026-11-05",
            wasMastered: true,
            today: "2026-11-05",
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertFalse(qualifies)
    }

    // 2. next day → no longer earns memory credit in Practice
    func testNextDayNoLongerEarnsMemoryCredit() {
        let qualifies = StarStreak.mayEarnMemoryCredit(
            masteryDay: "2026-11-05",
            wasMastered: true,
            today: "2026-11-06",
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertFalse(qualifies)
    }

    // 3. old record without a day → no longer earns memory credit in Practice
    func testOldRecordWithoutDayNoLongerEarnsMemoryCredit() {
        let qualifies = StarStreak.mayEarnMemoryCredit(
            masteryDay: nil,
            wasMastered: true,
            today: "2026-11-05",
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertFalse(qualifies)
    }

    // 4. star 2 earned in the current run → no credit
    func testStar2EarnedInCurrentRunDoesNotEarnMemoryCredit() {
        let qualifies = StarStreak.mayEarnMemoryCredit(
            masteryDay: nil,
            wasMastered: false,
            today: "2026-11-05",
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertFalse(qualifies)
    }

    // 5. merge keeps the earlier day
    func testMergingKeepsEarlierMasteryDay() {
        let recordA = LessonProgress(passed: true, mastery: true, memory: false, masteryDay: "2026-11-05")
        let recordB = LessonProgress(passed: true, mastery: true, memory: false, masteryDay: "2026-11-02")
        let merged = ProgressStore.merging(recordA, with: recordB)
        XCTAssertEqual(merged.masteryDay, "2026-11-02")

        let mergedReverse = ProgressStore.merging(recordB, with: recordA)
        XCTAssertEqual(mergedReverse.masteryDay, "2026-11-02")
    }
}
