import XCTest
@testable import SmackAPad

final class ResultNextTargetTests: XCTestCase {
    private func makeLesson(id: Int, title: String) -> Lesson {
        Lesson(
            id: id,
            cat: "starter",
            title: title,
            genre: "Basic",
            tags: [],
            text: "",
            division: 4,
            bars: 1,
            startBpm: 70,
            targetBpm: 100,
            level: 1,
            src: "test",
            hits: []
        )
    }

    func testPassedReviewWithOtherDueReviewsOpensNextDue() {
        let dueLesson = makeLesson(id: 10, title: "Due")
        let pathLesson = makeLesson(id: 20, title: "Path")

        let target = ResultNextTarget.resolve(
            isStepResult: false,
            isMix: false,
            afterMe: false,
            finishedByReview: true,
            isDueReview: false,
            reviewFeedback: .passed(nextStep: 1, gapDays: 3),
            lessonPassed: true,
            nextDueReview: dueLesson,
            nextPathLesson: pathLesson
        )

        XCTAssertEqual(target, .lesson(dueLesson))
    }

    func testPassedReviewWithNoDueReviewsFallsBackToPathLesson() {
        let pathLesson = makeLesson(id: 20, title: "Path")

        let target = ResultNextTarget.resolve(
            isStepResult: false,
            isMix: false,
            afterMe: false,
            finishedByReview: true,
            isDueReview: false,
            reviewFeedback: .settled,
            lessonPassed: true,
            nextDueReview: nil,
            nextPathLesson: pathLesson
        )

        XCTAssertEqual(target, .lesson(pathLesson))
    }

    func testPassedReviewWithNoDueAndNoPathLessonIsHidden() {
        let target = ResultNextTarget.resolve(
            isStepResult: false,
            isMix: false,
            afterMe: false,
            finishedByReview: true,
            isDueReview: false,
            reviewFeedback: .passed(nextStep: 1, gapDays: 3),
            lessonPassed: true,
            nextDueReview: nil,
            nextPathLesson: nil
        )

        XCTAssertEqual(target, .hidden)
    }

    func testFailedOrNonCountingReviewIsHidden() {
        let dueLesson = makeLesson(id: 10, title: "Due")
        let pathLesson = makeLesson(id: 20, title: "Path")

        let failedTarget = ResultNextTarget.resolve(
            isStepResult: false,
            isMix: false,
            afterMe: false,
            finishedByReview: false,
            isDueReview: false,
            reviewFeedback: .failed(newStep: 0),
            lessonPassed: true,
            nextDueReview: dueLesson,
            nextPathLesson: pathLesson
        )
        XCTAssertEqual(failedTarget, .hidden)

        let uncountedTarget = ResultNextTarget.resolve(
            isStepResult: false,
            isMix: false,
            afterMe: false,
            finishedByReview: false,
            isDueReview: true,
            reviewFeedback: .doesNotCount(goalBpm: 100),
            lessonPassed: true,
            nextDueReview: dueLesson,
            nextPathLesson: pathLesson
        )
        XCTAssertEqual(uncountedTarget, .hidden)
    }

    func testTodayStepReportsStepResultAndOrdinaryPassedLessonUsesPathLesson() {
        let pathLesson = makeLesson(id: 20, title: "Path")

        let stepTarget = ResultNextTarget.resolve(
            isStepResult: true,
            isMix: false,
            afterMe: false,
            finishedByReview: true,
            isDueReview: false,
            reviewFeedback: .passed(nextStep: 1, gapDays: 3),
            lessonPassed: true,
            nextDueReview: nil,
            nextPathLesson: pathLesson
        )
        XCTAssertEqual(stepTarget, .stepResult)

        let ordinaryTarget = ResultNextTarget.resolve(
            isStepResult: false,
            isMix: false,
            afterMe: false,
            finishedByReview: false,
            isDueReview: false,
            reviewFeedback: nil,
            lessonPassed: true,
            nextDueReview: nil,
            nextPathLesson: pathLesson
        )
        XCTAssertEqual(ordinaryTarget, .lesson(pathLesson))
    }
}
