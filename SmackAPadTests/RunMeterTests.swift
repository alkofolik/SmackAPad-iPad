import XCTest
@testable import SmackAPad

final class RunMeterTests: XCTestCase {
    func testStar1KeepsTheRunMeterAtAnyTempo() {
        for bpm in [50, 65, 80, 85] {
            XCTAssertEqual(
                PracticeMeterPhase(starIndex: 0, count: 1, required: 2,
                                   startBpm: 60, goalBpm: 80, step: 5, currentBpm: bpm),
                .runs(count: 1, required: 2)
            )
        }
    }

    func testStar2AtOrAboveGoalKeepsTheCountedRuns() {
        for bpm in [80, 85] {
            XCTAssertEqual(
                PracticeMeterPhase(starIndex: 1, count: 1, required: 3,
                                   startBpm: 60, goalBpm: 80, step: 5, currentBpm: bpm),
                .runs(count: 1, required: 3)
            )
        }
    }

    func testStar2UsesContinuousTempoProgressWithManyStepsOrAutoStepOff() {
        XCTAssertEqual(
            PracticeMeterPhase(starIndex: 1, count: 0, required: 3,
                               startBpm: 60, goalBpm: 80, step: 2, currentBpm: 65),
            .climbContinuous(fraction: 0.25)
        )
        XCTAssertEqual(
            PracticeMeterPhase(starIndex: 1, count: 0, required: 3,
                               startBpm: 60, goalBpm: 80, step: 0, currentBpm: 65),
            .climbContinuous(fraction: 0.25)
        )
    }

    func testStar2BelowGoalShowsCompletedTempoSteps() {
        XCTAssertEqual(
            PracticeMeterPhase(starIndex: 1, count: 0, required: 3,
                               startBpm: 60, goalBpm: 80, step: 5, currentBpm: 65),
            .climbSegments(filled: 1, total: 4)
        )
        XCTAssertEqual(
            PracticeMeterPhase(starIndex: 1, count: 0, required: 3,
                               startBpm: 60, goalBpm: 82, step: 5, currentBpm: 80),
            .climbSegments(filled: 4, total: 5)
        )
    }

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
            badgeCount: 1,
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
        XCTAssertEqual(reviewEn.status.title, AppLanguage.english.localized("Review passed"))
        XCTAssertEqual(reviewEn.reviewLine?.text, "next in 3 days")
        XCTAssertEqual(reviewEn.reviewLine?.icon, "calendar")
        XCTAssertNil(reviewEn.runsLine)
        XCTAssertEqual(reviewEn.badgeLine?.text, "1 new badge")
        XCTAssertEqual(reviewEn.badgeLine?.icon, "rosette")
        XCTAssertTrue(reviewEn.badgeLine?.isOrange == true)
        XCTAssertEqual(reviewEn.lines.map(\.text), ["next in 3 days", "1 new badge"])

        let reviewCs = EndOfRunCardModel.build(
            summary: summary,
            runs: [],
            saved: savedThree,
            reviewFeedback: .passed(nextStep: 2, gapDays: 3),
            badgeCount: 0,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .czech
        )
        XCTAssertEqual(reviewCs.reviewLine?.text, "další za 3 dny")
        XCTAssertNil(reviewCs.runsLine)
        XCTAssertNil(reviewCs.badgeLine)
        XCTAssertEqual(reviewCs.lines.map(\.text), ["další za 3 dny"])

        let normal = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.88, bpm: 80, passes: 2, passed: true, mastery: false, memory: false),
            runs: [
                PracticeRunResult(runNumber: 1, score: 0.88, bpm: 80, passed: true),
                PracticeRunResult(runNumber: 2, score: 0.94, bpm: 85, passed: true)
            ],
            saved: LessonProgress(passed: true, mastery: false, memory: false),
            reviewFeedback: nil,
            badgeCount: 0,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .english
        )
        XCTAssertNil(normal.reviewLine)
        XCTAssertEqual(normal.runsLine?.text, "2 runs · best 94%")
        XCTAssertEqual(normal.runsLine?.icon, "chart.bar.fill")
        XCTAssertNil(normal.badgeLine)
        XCTAssertEqual(normal.lines.map(\.text), ["2 runs · best 94%"])

        let afterMe = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.9, bpm: 80, passes: 1, passed: false, mastery: false, memory: false),
            runs: [],
            saved: nil,
            reviewFeedback: nil,
            badgeCount: 0,
            isAfterMe: true,
            isSectionLoop: false,
            bestResponseScore: 0.92,
            language: .english
        )
        XCTAssertFalse(afterMe.showsStars)
        XCTAssertEqual(afterMe.lines.count, 1)
        XCTAssertEqual(afterMe.reviewLine?.text, "Best response: 92\u{00a0}%")

        let notCounted = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.5, bpm: 70, passes: 0, passed: false, mastery: false, memory: false),
            runs: [],
            saved: nil,
            reviewFeedback: nil,
            badgeCount: 0,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .english
        )
        XCTAssertFalse(notCounted.status.tintOrange)
        XCTAssertEqual(notCounted.status.icon, "exclamationmark.circle")
        XCTAssertTrue(notCounted.lines.isEmpty)

        let earlyDueStop = EndOfRunCardModel.build(
            summary: RunSummary(score: 1.0, bpm: 80, passes: 1, passed: true, mastery: false, memory: false),
            runs: [PracticeRunResult(runNumber: 1, score: 1.0, bpm: 80, passed: true)],
            saved: LessonProgress(passed: true, mastery: true, memory: true, currentBpm: 80, reviewStep: 2, reviewDueDay: "2026-11-12"),
            reviewFeedback: nil,
            badgeCount: 0,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .english,
            isDueReview: true,
            reviewPendingReason: .notesVisible
        )
        XCTAssertFalse(earlyDueStop.status.tintOrange)
        XCTAssertEqual(earlyDueStop.status.icon, "exclamationmark.circle")
        XCTAssertEqual(earlyDueStop.status.title, AppLanguage.english.localized("Not counted"))
        XCTAssertEqual(earlyDueStop.reviewLine?.text, PracticeStepOutcome.Reason.notesVisible.message(language: .english))
        XCTAssertEqual(earlyDueStop.runsLine?.text, "1 run · best 100%")
        XCTAssertEqual(earlyDueStop.lines.map(\.text), [PracticeStepOutcome.Reason.notesVisible.message(language: .english), "1 run · best 100%"])
    }

    func testCzechBadgePlural() {
        XCTAssertEqual(EndOfRunCardModel.badgeSummaryText(count: 1, language: .czech), "1 nový odznak")
        XCTAssertEqual(EndOfRunCardModel.badgeSummaryText(count: 2, language: .czech), "2 nové odznaky")
        XCTAssertEqual(EndOfRunCardModel.badgeSummaryText(count: 5, language: .czech), "5 nových odznaků")
    }

    func testStar2EarnedShowsReviewTomorrowLine() {
        let star2En = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.95, bpm: 80, passes: 2, passed: true, mastery: true, memory: false, firstStar2: true),
            runs: [PracticeRunResult(runNumber: 1, score: 0.95, bpm: 80, passed: true)],
            saved: LessonProgress(passed: true, mastery: true, memory: false),
            reviewFeedback: nil,
            badgeCount: 2,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .english
        )
        XCTAssertEqual(star2En.reviewLine?.text, "Review tomorrow")
        XCTAssertEqual(star2En.reviewLine?.icon, "calendar")
        XCTAssertEqual(star2En.runsLine?.text, "1 run · best 95%")
        XCTAssertEqual(star2En.badgeLine?.text, "2 new badges")
        XCTAssertEqual(star2En.lines.map(\.text), ["Review tomorrow", "1 run · best 95%", "2 new badges"])

        let star2Cs = EndOfRunCardModel.build(
            summary: RunSummary(score: 0.95, bpm: 80, passes: 2, passed: true, mastery: true, memory: false, firstStar2: true),
            runs: [PracticeRunResult(runNumber: 1, score: 0.95, bpm: 80, passed: true)],
            saved: LessonProgress(passed: true, mastery: true, memory: false),
            reviewFeedback: nil,
            badgeCount: 2,
            isAfterMe: false,
            isSectionLoop: false,
            bestResponseScore: nil,
            language: .czech
        )
        XCTAssertEqual(star2Cs.reviewLine?.text, "Opakování zítra")
        XCTAssertEqual(star2Cs.badgeLine?.text, "2 nové odznaky")
    }
}
