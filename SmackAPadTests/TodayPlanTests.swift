import XCTest
@testable import SmackAPad

final class TodayPlanTests: XCTestCase {
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
