import XCTest
@testable import SmackAPad

final class ReviewWindowTests: XCTestCase {
    private let today = "2026-11-07"

    private func passResult(score: Float, step: Int = 1, bpm: Int = 100) -> ReviewScheduler.Outcome {
        ReviewScheduler.evaluate(
            schedule: .init(reviewStep: step, reviewDueDay: today), today: today,
            isFullRun: true, fromMemory: true, bpm: bpm, targetBpm: 100, score: score
        )
    }

    func testTwoSuccessesPassAfterTwoCountedPasses() {
        let first = ReviewScheduler.advanceWindow(.init(), with: passResult(score: 0.8))
        XCTAssertEqual(first.window.successes, 1)
        XCTAssertEqual(first.window.failures, 0)
        XCTAssertNil(first.outcome)
        let second = ReviewScheduler.advanceWindow(first.window, with: passResult(score: 0.9))
        XCTAssertEqual(second.window.successes, 2)
        XCTAssertEqual(second.outcome?.feedback, .passed(nextStep: 2, gapDays: 7))
        XCTAssertEqual(second.outcome?.newSchedule.reviewDueDay, "2026-11-14")
    }

    func testTwoFailuresFailAfterTwoCountedPasses() {
        let first = ReviewScheduler.advanceWindow(.init(), with: passResult(score: 0.79))
        XCTAssertEqual(first.window.failures, 1)
        XCTAssertNil(first.outcome)
        let second = ReviewScheduler.advanceWindow(first.window, with: passResult(score: 0.4))
        XCTAssertEqual(second.window.failures, 2)
        XCTAssertEqual(second.outcome?.feedback, .failed(newStep: 0))
        XCTAssertEqual(second.outcome?.newSchedule.reviewDueDay, "2026-11-08")
    }

    func testSuccessFailureSuccessPassesAfterThree() {
        let first = ReviewScheduler.advanceWindow(.init(), with: passResult(score: 0.9))
        let second = ReviewScheduler.advanceWindow(first.window, with: passResult(score: 0.7))
        XCTAssertNil(second.outcome)
        let third = ReviewScheduler.advanceWindow(second.window, with: passResult(score: 0.8))
        XCTAssertEqual(third.window.successes, 2)
        XCTAssertEqual(third.window.failures, 1)
        XCTAssertEqual(third.outcome?.feedback, .passed(nextStep: 2, gapDays: 7))
    }

    func testFailureSuccessFailureFailsAfterThree() {
        let first = ReviewScheduler.advanceWindow(.init(), with: passResult(score: 0.5))
        let second = ReviewScheduler.advanceWindow(first.window, with: passResult(score: 1))
        XCTAssertNil(second.outcome)
        let third = ReviewScheduler.advanceWindow(second.window, with: passResult(score: 0.79))
        XCTAssertEqual(third.window.successes, 1)
        XCTAssertEqual(third.window.failures, 2)
        XCTAssertEqual(third.outcome?.feedback, .failed(newStep: 0))
    }

    func testDoesNotCountLeavesWindowUnchanged() {
        let first = ReviewScheduler.advanceWindow(.init(), with: passResult(score: 0.9))
        let ignored = ReviewScheduler.advanceWindow(first.window, with: passResult(score: 1, bpm: 90))
        XCTAssertEqual(ignored.window, first.window)
        XCTAssertNil(ignored.outcome)
    }

    func testLastStepSettlesOnlyAfterTwoSuccesses() {
        let first = ReviewScheduler.advanceWindow(.init(), with: passResult(score: 0.8, step: 3))
        XCTAssertNil(first.outcome)
        let second = ReviewScheduler.advanceWindow(first.window, with: passResult(score: 0.8, step: 3))
        XCTAssertEqual(second.outcome?.feedback, .settled)
        XCTAssertEqual(second.outcome?.newSchedule.settled, true)
        XCTAssertEqual(second.outcome?.newSchedule.lastReviewedDay, today)
        XCTAssertNil(second.outcome?.newSchedule.reviewDueDay)
    }
}
