import XCTest
@testable import SmackAPad

final class ReviewScheduleTests: XCTestCase {
    func testOnlyScheduledReviewsNotYetDecidedTodayAreDue() {
        let today = "2026-11-09"
        XCTAssertTrue(ReviewScheduler.ScheduleState(reviewDueDay: today).isDueReview(on: today))
        XCTAssertFalse(ReviewScheduler.ScheduleState(reviewDueDay: "2026-11-10").isDueReview(on: today))
        XCTAssertFalse(ReviewScheduler.ScheduleState(reviewDueDay: today, lastReviewedDay: today).isDueReview(on: today))
        XCTAssertFalse(ReviewScheduler.ScheduleState().isDueReview(on: today))
    }

    func testLibraryAndHomeSelectAReviewLaunchOnlyWhenDue() {
        let today = "2026-11-09"
        let lesson = Lesson(id: 158, cat: "test", title: "Review", genre: "", tags: [],
                            text: "", division: 16, bars: 1, startBpm: 90, targetBpm: 120,
                            level: 1, src: "test", hits: [])
        let due = LessonProgress(reviewDueDay: today)
        let upcoming = LessonProgress(reviewDueDay: "2026-11-10")
        guard case .review(let review) = LessonLaunch.library(lesson, progress: due, today: today),
              case .lesson(let practice) = LessonLaunch.library(lesson, progress: upcoming, today: today) else {
            return XCTFail("Expected a review for the due lesson and practice for the upcoming lesson")
        }
        XCTAssertEqual(review, lesson)
        XCTAssertEqual(practice, lesson)
    }

    // 1. pass advances with the right gap for each step
    func testPassAdvancesWithRightGapForEachStep() {
        let today = "2026-11-05"

        // Step 0 -> pass advances to Step 1 with gap 3 days (due today + 3 = 2026-11-08)
        let schedule0 = ReviewScheduler.ScheduleState(reviewStep: 0, reviewDueDay: today, settled: false)
        let outcome0 = ReviewScheduler.evaluate(
            schedule: schedule0,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertEqual(outcome0.newSchedule.reviewStep, 1)
        XCTAssertEqual(outcome0.newSchedule.reviewDueDay, "2026-11-08")
        XCTAssertEqual(outcome0.newSchedule.settled, false)
        XCTAssertEqual(outcome0.feedback, .passed(nextStep: 1, gapDays: 3))

        // Step 1 -> pass advances to Step 2 with gap 7 days (due today + 7 = 2026-11-12)
        let schedule1 = ReviewScheduler.ScheduleState(reviewStep: 1, reviewDueDay: today, settled: false)
        let outcome1 = ReviewScheduler.evaluate(
            schedule: schedule1,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertEqual(outcome1.newSchedule.reviewStep, 2)
        XCTAssertEqual(outcome1.newSchedule.reviewDueDay, "2026-11-12")
        XCTAssertEqual(outcome1.newSchedule.settled, false)
        XCTAssertEqual(outcome1.feedback, .passed(nextStep: 2, gapDays: 7))

        // Step 2 -> pass advances to Step 3 with gap 21 days (due today + 21 = 2026-11-26)
        let schedule2 = ReviewScheduler.ScheduleState(reviewStep: 2, reviewDueDay: today, settled: false)
        let outcome2 = ReviewScheduler.evaluate(
            schedule: schedule2,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertEqual(outcome2.newSchedule.reviewStep, 3)
        XCTAssertEqual(outcome2.newSchedule.reviewDueDay, "2026-11-26")
        XCTAssertEqual(outcome2.newSchedule.settled, false)
        XCTAssertEqual(outcome2.feedback, .passed(nextStep: 3, gapDays: 21))
    }

    // 2. fail steps back and is due tomorrow
    func testFailStepsBackAndIsDueTomorrow() {
        let today = "2026-11-05"

        // Step 2 -> fail steps back to Step 1, due tomorrow (2026-11-06)
        let schedule2 = ReviewScheduler.ScheduleState(reviewStep: 2, reviewDueDay: today, settled: false)
        let outcome2 = ReviewScheduler.evaluate(
            schedule: schedule2,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.75
        )
        XCTAssertEqual(outcome2.newSchedule.reviewStep, 1)
        XCTAssertEqual(outcome2.newSchedule.reviewDueDay, "2026-11-06")
        XCTAssertEqual(outcome2.newSchedule.settled, false)
        XCTAssertEqual(outcome2.feedback, .failed(newStep: 1))

        // Step 0 -> fail steps back to minimum Step 0, due tomorrow (2026-11-06)
        let schedule0 = ReviewScheduler.ScheduleState(reviewStep: 0, reviewDueDay: today, settled: false)
        let outcome0 = ReviewScheduler.evaluate(
            schedule: schedule0,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.75
        )
        XCTAssertEqual(outcome0.newSchedule.reviewStep, 0)
        XCTAssertEqual(outcome0.newSchedule.reviewDueDay, "2026-11-06")
        XCTAssertEqual(outcome0.newSchedule.settled, false)
        XCTAssertEqual(outcome0.feedback, .failed(newStep: 0))
    }

    // 3. below goal tempo / not from memory / not yet due → unchanged
    func testBelowGoalTempoOrNotFromMemoryOrNotYetDueUnchanged() {
        let today = "2026-11-05"
        let schedule = ReviewScheduler.ScheduleState(reviewStep: 1, reviewDueDay: today, settled: false)

        // Below goal tempo (90 BPM vs target 100 BPM) -> unchanged, feedback doesNotCount
        let outcomeBelowTempo = ReviewScheduler.evaluate(
            schedule: schedule,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 90,
            targetBpm: 100,
            score: 0.90
        )
        XCTAssertEqual(outcomeBelowTempo.newSchedule, schedule)
        XCTAssertEqual(outcomeBelowTempo.feedback, .doesNotCount(goalBpm: 100))

        // Not from memory -> unchanged, feedback doesNotCount
        let outcomeNotMemory = ReviewScheduler.evaluate(
            schedule: schedule,
            today: today,
            isFullRun: true,
            fromMemory: false,
            bpm: 100,
            targetBpm: 100,
            score: 0.90
        )
        XCTAssertEqual(outcomeNotMemory.newSchedule, schedule)
        XCTAssertEqual(outcomeNotMemory.feedback, .doesNotCount(goalBpm: 100))

        // Not yet due (due on 2026-11-08, today is 2026-11-05) -> unchanged, feedback nil
        let futureSchedule = ReviewScheduler.ScheduleState(reviewStep: 1, reviewDueDay: "2026-11-08", settled: false)
        let outcomeNotDue = ReviewScheduler.evaluate(
            schedule: futureSchedule,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.90
        )
        XCTAssertEqual(outcomeNotDue.newSchedule, futureSchedule)
        XCTAssertNil(outcomeNotDue.feedback)
    }

    // 4. second review the same day ignored
    func testSecondReviewTheSameDayIgnored() {
        let today = "2026-11-05"
        let schedule0 = ReviewScheduler.ScheduleState(reviewStep: 0, reviewDueDay: today, settled: false)

        // First review today: passes
        let firstOutcome = ReviewScheduler.evaluate(
            schedule: schedule0,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertEqual(firstOutcome.newSchedule.reviewDueDay, "2026-11-08")

        // Second run today on the updated schedule: not due, ignored (ordinary practice)
        let secondOutcome = ReviewScheduler.evaluate(
            schedule: firstOutcome.newSchedule,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertEqual(secondOutcome.newSchedule, firstOutcome.newSchedule)
        XCTAssertNil(secondOutcome.feedback)
    }

    // 5. step 3 pass → settled
    func testStep3PassMarksLessonSettled() {
        let today = "2026-11-05"
        let schedule3 = ReviewScheduler.ScheduleState(reviewStep: 3, reviewDueDay: today, settled: false)

        let outcome = ReviewScheduler.evaluate(
            schedule: schedule3,
            today: today,
            isFullRun: true,
            fromMemory: true,
            bpm: 100,
            targetBpm: 100,
            score: 0.85
        )
        XCTAssertEqual(outcome.newSchedule.reviewStep, 3)
        XCTAssertNil(outcome.newSchedule.reviewDueDay)
        XCTAssertEqual(outcome.newSchedule.settled, true)
        XCTAssertTrue(outcome.newSchedule.isSettled)
        XCTAssertEqual(outcome.feedback, .settled)
    }

    // 6. old file → first review tomorrow
    func testOldFileGetsFirstReviewTomorrow() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let fileURL = tempDir.appendingPathComponent("progress.json")
        // An old JSON representation without reviewStep, reviewDueDay, settled
        let oldJSON = """
        {
            "42": {
                "passed": true,
                "mastery": true,
                "memory": false,
                "currentBpm": 100,
                "bestScore": 0.85,
                "hasPlayed": true,
                "masteryDay": "2026-11-04"
            }
        }
        """
        try oldJSON.write(to: fileURL, atomically: true, encoding: .utf8)

        AppCalendar.todayProvider = { "2026-11-05" }
        defer { AppCalendar.todayProvider = { AppCalendar.dayString(from: Date()) } }

        let store = ProgressStore(fileURL: fileURL, autoLoad: true)
        let record = store.progress(for: 42)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.reviewStep, 0)
        XCTAssertEqual(record?.reviewDueDay, "2026-11-06") // tomorrow!
        XCTAssertFalse(record?.reviewSchedule.isSettled ?? true)
    }
}
