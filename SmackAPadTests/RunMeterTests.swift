import XCTest
@testable import SmackAPad

final class RunMeterTests: XCTestCase {
    @MainActor
    func testRunFractionIncludesBothRepeatsAndWrapsAtTheNextRun() {
        XCTAssertEqual(PracticeSession.runFraction(tapePosition: 0, totalSteps: 32, repeatsPerRun: 2), 0)
        XCTAssertEqual(PracticeSession.runFraction(tapePosition: 32, totalSteps: 32, repeatsPerRun: 2), 0.5)
        XCTAssertEqual(PracticeSession.runFraction(tapePosition: 64, totalSteps: 32, repeatsPerRun: 2), 0)
    }

    @MainActor
    func testMicroStepsLightAtTheThirds() {
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 0), 0)
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 1.0 / 3), 1)
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 2.0 / 3), 2)
        XCTAssertEqual(RunMeterView.litMicroSteps(fraction: 1), 3)
    }

    @MainActor
    func testEndOfRunCardModelFormatsReviewNormalAndNotCountedRuns() {
        let savedThree = LessonProgress(passed: true, mastery: true, memory: true)
        let summary = RunSummary(score: 0.96, bpm: 90, passes: 2, passed: true, mastery: true, memory: true)

        let reviewEn = EndOfRunCardModel.build(
            summary: summary,
            runs: [],
            saved: savedThree,
            reviewFeedback: .passed(nextStep: 2, gapDays: 3),
            badgeMessage: "New badge: Streak",
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .english
        )
        XCTAssertEqual(reviewEn.scorePercent, 96)
        XCTAssertEqual(reviewEn.bpm, 90)
        XCTAssertTrue(reviewEn.showsStars)
        XCTAssertEqual(reviewEn.earnedStars, [true, true, true])
        XCTAssertTrue(reviewEn.status.tintOrange)
        XCTAssertEqual(reviewEn.chips.map(\.isOrange), [false, true])
        XCTAssertEqual(reviewEn.chips.last?.text, "New badge: Streak")

        let reviewCs = EndOfRunCardModel.build(
            summary: summary,
            runs: [],
            saved: savedThree,
            reviewFeedback: .passed(nextStep: 2, gapDays: 3),
            badgeMessage: nil,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .czech
        )
        XCTAssertEqual(reviewCs.chips.first?.text, "další za 3 dny")

        let normal = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.88, bpm: 80, passes: 2, passed: true, mastery: false, memory: false),
            runs: [
                PracticeRunResult(runNumber: 1, score: 0.88, bpm: 80, passed: true),
                PracticeRunResult(runNumber: 2, score: 0.94, bpm: 85, passed: true)
            ],
            saved: LessonProgress(passed: true, mastery: false, memory: false),
            reviewFeedback: nil,
            badgeMessage: nil,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .english
        )
        XCTAssertEqual(normal.chips.map(\.text), ["2 runs · best 94%"])

        let afterMe = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.9, bpm: 80, passes: 1, passed: false, mastery: false, memory: false),
            runs: [],
            saved: nil,
            reviewFeedback: nil,
            badgeMessage: nil,
            isAfterMe: true,
            isSectionLoop: false,
            bestResponseScore: 0.92,
            language: .english
        )
        XCTAssertFalse(afterMe.showsStars)
        XCTAssertEqual(afterMe.chips.count, 1)

        let notCounted = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.5, bpm: 70, passes: 0, passed: false, mastery: false, memory: false),
            runs: [],
            saved: nil,
            reviewFeedback: nil,
            badgeMessage: nil,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .english
        )
        XCTAssertFalse(notCounted.status.tintOrange)
        XCTAssertEqual(notCounted.status.icon, "exclamationmark.circle")
    }
}
