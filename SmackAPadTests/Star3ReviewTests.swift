import XCTest
@testable import SmackAPad

final class Star3ReviewTests: XCTestCase {
    private let today = "2026-11-07"

    func testLegacyThreeStarsStartTheExistingScheduleWithoutAZeroPassCounter() {
        var records = [1: LessonProgress(passed: true, mastery: true, memory: true)]
        XCTAssertTrue(ProgressStore.migrateLegacyMasteredReviewSchedule(in: &records, today: today))
        XCTAssertEqual(records[1]?.memory, true)
        XCTAssertEqual(records[1]?.reviewDueDay, "2026-11-08")
        XCTAssertEqual(records[1]?.isUnstartedLegacyReview, true)
        records[1]?.lastReviewedDay = "2026-11-08"
        XCTAssertEqual(records[1]?.isUnstartedLegacyReview, false)
        XCTAssertFalse(LessonProgress(mastery: true, memory: false, reviewStep: 0).isUnstartedLegacyReview)
        XCTAssertFalse(LessonProgress(memory: true, reviewStep: 2).isUnstartedLegacyReview)
    }

    // 1. second passed review → star 3
    func testSecondPassedReviewAwardsStar3() {
        let progress = LessonProgress(passed: true, mastery: true, memory: false, reviewStep: 1)
        let outcome = ReviewScheduler.Outcome(
            newSchedule: .init(reviewStep: 2, reviewDueDay: "2026-11-14", settled: false, lastReviewedDay: today),
            feedback: .passed(nextStep: 2, gapDays: 7)
        )
        XCTAssertTrue(ReviewScheduler.mayEarnStar3(outcome: outcome, progress: progress))
    }

    // 2. first passed review → no star 3
    func testFirstPassedReviewDoesNotAwardStar3() {
        let progress = LessonProgress(passed: true, mastery: true, memory: false, reviewStep: 0)
        let outcome = ReviewScheduler.Outcome(
            newSchedule: .init(reviewStep: 1, reviewDueDay: "2026-11-10", settled: false, lastReviewedDay: today),
            feedback: .passed(nextStep: 1, gapDays: 3)
        )
        XCTAssertFalse(ReviewScheduler.mayEarnStar3(outcome: outcome, progress: progress))
    }

    // 3. pass, fail, pass → star 3 on the second pass
    func testPassFailPassAwardsStar3OnSecondPass() {
        let progress = LessonProgress(passed: true, mastery: true, memory: false, reviewStep: 1)
        func passResult(score: Float) -> ReviewScheduler.Outcome {
            ReviewScheduler.evaluate(
                schedule: .init(reviewStep: 1, reviewDueDay: today),
                today: today,
                isFullRun: true,
                fromMemory: true,
                bpm: 100,
                targetBpm: 100,
                score: score
            )
        }
        var window = ReviewScheduler.WindowState()

        // Pass 1: first pass (pass)
        let step1 = ReviewScheduler.advanceWindow(window, with: passResult(score: 0.9))
        window = step1.window
        XCTAssertNil(step1.outcome)
        XCTAssertFalse(ReviewScheduler.mayEarnStar3(outcome: step1.outcome, progress: progress))

        // Pass 2: fail
        let step2 = ReviewScheduler.advanceWindow(window, with: passResult(score: 0.5))
        window = step2.window
        XCTAssertNil(step2.outcome)
        XCTAssertFalse(ReviewScheduler.mayEarnStar3(outcome: step2.outcome, progress: progress))

        // Pass 3: pass (the second pass!)
        let step3 = ReviewScheduler.advanceWindow(window, with: passResult(score: 0.85))
        window = step3.window
        XCTAssertEqual(step3.window.successes, 2)
        XCTAssertNotNil(step3.outcome)
        XCTAssertEqual(step3.outcome?.feedback, .passed(nextStep: 2, gapDays: 7))
        XCTAssertTrue(ReviewScheduler.mayEarnStar3(outcome: step3.outcome, progress: progress))
    }

    // 4. From memory run in Practice (not a due review) → no star 3
    func testFromMemoryRunInPracticeDoesNotAwardStar3() {
        let progress = LessonProgress(passed: true, mastery: true, memory: false, masteryDay: "2026-11-05")
        let earnsMemoryCredit = StarStreak.mayEarnMemoryCredit(
            progress: progress,
            today: "2026-11-07",
            fromMemory: true,
            bpm: 120,
            targetBpm: 100,
            score: 0.95,
            isSectionLoop: false,
            pass: 3,
            fadeNotes: true
        )
        XCTAssertFalse(earnsMemoryCredit)
    }

    // 5. migration gives star 3 to reviewStep 2 without star 3
    func testMigrationGivesStar3ToReviewStep2WithoutStar3() {
        var records: [Int: LessonProgress] = [
            1: LessonProgress(passed: true, mastery: true, memory: false, reviewStep: 2),
            2: LessonProgress(passed: true, mastery: true, memory: false, reviewStep: 1),
            3: LessonProgress(passed: true, mastery: true, memory: false, reviewStep: 3, settled: true),
            4: LessonProgress(passed: true, mastery: true, memory: true, reviewStep: 2)
        ]
        let changed = ProgressStore.migrateTwoReviewsStar3(in: &records)
        XCTAssertTrue(changed)
        XCTAssertEqual(records[1]?.memory, true)
        XCTAssertEqual(records[2]?.memory, false)
        XCTAssertEqual(records[3]?.memory, true)
        XCTAssertEqual(records[4]?.memory, true)
    }
}
