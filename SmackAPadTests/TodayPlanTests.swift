import XCTest
@testable import SmackAPad

final class TodayPlanTests: XCTestCase {
    func testReviewStatesAndSummaryUseTheSameOutcomesEvenAtOneHundredPercent() {
        let steps: [TodayPlan.Step] = [
            .init(kind: .review, lessonIDs: [1], outcome: .init(bestScore: 1, reviewFeedback: nil)),
            .init(kind: .review, lessonIDs: [2], outcome: .init(bestScore: 1, reviewFeedback: .passed(nextStep: 1, gapDays: 3))),
            .init(kind: .review, lessonIDs: [3], outcome: .init(bestScore: 1, reviewFeedback: .failed(newStep: 0))),
            .init(kind: .review, lessonIDs: [4], outcome: .init(bestScore: 1, reviewFeedback: .doesNotCount(goalBpm: 120))),
            .init(kind: .review, lessonIDs: [5], outcome: .init(bestScore: 0.9, reviewFeedback: .settled)),
            .init(kind: .review, lessonIDs: [6]),
            .init(kind: .mix, lessonIDs: [7, 8], outcome: .init(bestScore: 1, reviewFeedback: nil))
        ]
        let plan = TodayPlan(day: "2026-11-08", steps: steps)
        XCTAssertEqual(steps[0].status, .didNotCount(.unfinishedReview))
        XCTAssertEqual(steps[1].status, .passed)
        XCTAssertEqual(steps[2].status, .didNotCount(.reviewNotPassed))
        XCTAssertEqual(steps[3].status, .didNotCount(.requirements(goalBpm: 120)))
        XCTAssertEqual(steps[4].status, .passed)
        XCTAssertNil(steps[5].status)
        XCTAssertEqual(plan.reviewSummary.played, 5)
        XCTAssertEqual(plan.reviewSummary.passed, 2)
        XCTAssertEqual(plan.reviewSummary.didNotCount, 3)
        XCTAssertEqual(plan.reviewSummary.notPlayed, 1)
        XCTAssertEqual(plan.reviewSummary.passed + plan.reviewSummary.didNotCount + plan.reviewSummary.notPlayed,
                       plan.reviewCount)
    }

    func testPlayedLessonAndWarmupHaveDistinctStatesAndReasons() {
        let lesson = TodayPlan.Step(kind: .newLesson, lessonIDs: [1], outcome: .init(bestScore: 0.7))
        let warmup = TodayPlan.Step(kind: .review, lessonIDs: [2],
                                   outcome: .init(bestScore: 1, reviewPendingReason: .notesVisible))
        XCTAssertEqual(lesson.status, .played)
        XCTAssertEqual(warmup.status, .didNotCount(.notesVisible))
    }

    func testLaterPracticeCannotReplaceADecidedReviewOutcome() {
        for feedback: ReviewScheduler.ReviewFeedback in [.passed(nextStep: 1, gapDays: 3), .settled, .failed(newStep: 0)] {
            var outcome = PracticeStepOutcome(bestScore: 0.8, reviewFeedback: feedback)
            outcome.include(.init(bestScore: 1, reviewFeedback: .doesNotCount(goalBpm: 120)))
            XCTAssertEqual(outcome.reviewFeedback, feedback)
            XCTAssertEqual(outcome.bestScore, 1)
        }
    }

    func testReviewLoadSeparatesTodaysTwoFromTheRemainingQueue() throws {
        let due = Array(1...29)
        let plan = try XCTUnwrap(TodayPlan.make(day: "2026-11-08", dueLessonIDs: due,
                                               nextLessonID: nil, mixLessonIDs: []))
        let load = TodayPlan.ReviewLoad(dueLessonIDs: due, plan: plan)
        XCTAssertEqual(load.todayIDs, [1, 2])
        XCTAssertEqual(load.queueIDs, Array(3...29))
        // Completing or postponing the first review must not pull another lesson into Today.
        let resumed = TodayPlan.ReviewLoad(dueLessonIDs: Array(2...29), plan: plan)
        XCTAssertEqual(resumed.todayIDs, [1, 2])
        XCTAssertEqual(resumed.queueIDs, Array(3...29))
        XCTAssertEqual(TodayPlan.ReviewLoad(dueLessonIDs: [], plan: nil).todayIDs, [])
        XCTAssertEqual(TodayPlan.ReviewLoad(dueLessonIDs: [1], plan: nil).todayIDs, [1])
    }

    func testExistingSavedOutcomeStillDecodesWithAnExplanation() throws {
        let json = """
        {"day":"2026-11-08","steps":[{"kind":"review","lessonIDs":[1],"outcome":{"bestScore":1}}],
         "index":1,"finished":true,"phase":"summary"}
        """
        let plan = try XCTUnwrap(TodayPlan.decode(json, today: "2026-11-08"))
        XCTAssertEqual(plan.steps[0].status, .didNotCount(.unfinishedReview))
    }

    func testThreeDueReviewsTakeTwoOldestThenNewLessonAndMix() {
        let plan = TodayPlan.make(day: "2026-11-05", dueLessonIDs: [30, 10, 20],
                                  nextLessonID: 40, mixLessonIDs: [50, 60])
        XCTAssertEqual(plan?.steps.map(\.kind), [.review, .review, .newLesson, .mix])
        XCTAssertEqual(plan?.steps.map(\.lessonIDs), [[30], [10], [40], [50, 60]])
    }

    func testNoNewLessonAndMixBelowTwoAreOmitted() {
        for mix in [[], [50]] {
            let plan = TodayPlan.make(day: "2026-11-05", dueLessonIDs: [30],
                                      nextLessonID: nil, mixLessonIDs: mix)
            XCTAssertEqual(plan?.steps.map(\.kind), [.review])
            XCTAssertEqual(plan?.steps.map(\.lessonIDs), [[30]])
        }
    }

    func testNoDueReviewsMeansNoTodayPlan() {
        XCTAssertNil(TodayPlan.make(day: "2026-11-05", dueLessonIDs: [],
                                   nextLessonID: 40, mixLessonIDs: [50, 60]))
    }

    func testPostponeMovesDueDayToTomorrowAndPreservesStep() {
        let schedule = ReviewScheduler.ScheduleState(reviewStep: 2, reviewDueDay: "2026-11-01", settled: false)
        let postponed = ReviewScheduler.postpone(schedule, today: "2026-11-05")
        XCTAssertEqual(postponed.reviewDueDay, "2026-11-06")
        XCTAssertEqual(postponed.reviewStep, schedule.reviewStep)
        XCTAssertEqual(postponed.settled, schedule.settled)
        XCTAssertEqual(postponed.lastReviewedDay, schedule.lastReviewedDay)
    }

    func testPostponeIgnoresReviewPlayedToday() {
        let schedule = ReviewScheduler.ScheduleState(reviewStep: 2, reviewDueDay: "2026-11-01", settled: false,
                                                      lastReviewedDay: "2026-11-05")
        XCTAssertEqual(ReviewScheduler.postpone(schedule, today: "2026-11-05"), schedule)
    }
}
