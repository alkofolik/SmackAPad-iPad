import XCTest
@testable import SmackAPad

final class TodayPlanTests: XCTestCase {
    func testOnlyPlayedUnpassedReviewsShowTheExclamationMarker() {
        var step = TodayPlan.Step(kind: .review, lessonIDs: [1])
        XCTAssertNil(step.markerSymbol)
        step.outcome = .init(bestScore: 1, reviewPendingReason: .notesVisible)
        XCTAssertEqual(step.markerSymbol, "exclamationmark.circle")
        step.outcome = .init(bestScore: 0.8, reviewFeedback: .passed(nextStep: 1, gapDays: 3))
        XCTAssertNil(step.markerSymbol)
    }

    func testReconciliationUsesTodaysDecisionsAndPreservesRecordedOutcomes() {
        let today = "2026-11-09"
        let recorded = PracticeStepOutcome(bestScore: 0.85, reviewFeedback: .settled)
        let plan = TodayPlan(day: today, steps: [
            .init(kind: .review, lessonIDs: [1]),
            .init(kind: .review, lessonIDs: [2]),
            .init(kind: .review, lessonIDs: [3]),
            .init(kind: .review, lessonIDs: [4], outcome: recorded),
            .init(kind: .review, lessonIDs: [5], outcome: .init(bestScore: 1, reviewPendingReason: .notesVisible)),
            .init(kind: .newLesson, lessonIDs: [1]),
            .init(kind: .mix, lessonIDs: [1, 2])
        ])
        let reconciled = plan.reconcilingReviews(with: [
            1: .init(reviewStep: 1, reviewDueDay: "2026-11-12", lastReviewedDay: today),
            2: .init(reviewStep: 0, lastReviewedDay: today, lastReviewFailDay: today),
            3: .init(lastReviewedDay: "2026-11-08"),
            4: .init(lastReviewedDay: today, lastReviewFailDay: today),
            5: .init(lastReviewedDay: today)
        ])
        XCTAssertEqual(reconciled.steps[0].status, .passed)
        XCTAssertNil(reconciled.steps[0].outcome?.bestScore)
        XCTAssertEqual(reconciled.steps[1].status, .didNotCount(.reviewNotPassed))
        XCTAssertEqual(reconciled.steps[1].markerSymbol, "exclamationmark.circle")
        XCTAssertEqual(reconciled.steps.dropFirst(2), plan.steps.dropFirst(2))
    }

    @MainActor
    func testTodaySkipsReconciledReviewsAndDoesNotPostponeThem() throws {
        let suite = "today-reconcile-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let today = AppCalendar.today()
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let decided = LessonProgress(reviewStep: 1, reviewDueDay: today, lastReviewedDay: today)
        progress.setProgress(decided, for: 1)
        let plan = TodayPlan(day: today, steps: [
            .init(kind: .review, lessonIDs: [1]),
            .init(kind: .newLesson, lessonIDs: [2])
        ])

        for transition: (TodaySessionCoordinator) -> Void in [
            { $0.reconcileReviews(progress: progress) },
            { $0.leavePractice(progress: progress) },
            { $0.skip(progress: progress) },
            { $0.finish(progress: progress) }
        ] {
            let coordinator = TodaySessionCoordinator(plan: plan, defaults: defaults)
            transition(coordinator)
            XCTAssertEqual(coordinator.plan.steps[0].status, .passed)
            XCTAssertEqual(coordinator.currentStep?.kind, coordinator.plan.finished ? nil : .newLesson)
            XCTAssertEqual(progress.progress(for: 1)?.reviewSchedule, decided.reviewSchedule)
            let saved = try XCTUnwrap(defaults.string(forKey: TodayPlan.storageKey))
            XCTAssertEqual(TodayPlan.decode(saved, today: today), coordinator.plan)
        }
    }

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
        let lesson = TodayPlan.Step(kind: .newLesson, lessonIDs: [1], outcome: .init(bestScore: 0.75))
        let passingLesson = TodayPlan.Step(kind: .newLesson, lessonIDs: [1], outcome: .init(bestScore: 0.8))
        let warmup = TodayPlan.Step(kind: .review, lessonIDs: [2],
                                   outcome: .init(bestScore: 1, reviewPendingReason: .notesVisible))
        XCTAssertEqual(lesson.status, .played)
        XCTAssertEqual(passingLesson.status, .passed)
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

    @MainActor
    func testStartingReviewFromTodayPanelAndReviewQueueOnSameDayCountsOnce() {
        let today = AppCalendar.today()
        let yesterday = AppCalendar.addingDays(-1, to: today) ?? today
        let suiteName = "TodayPlanTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        func completeReviewRun(for lessonID: Int, in progress: ProgressStore) -> ReviewScheduler.Outcome? {
            var window = ReviewScheduler.WindowState()
            var decidedOutcome: ReviewScheduler.Outcome?
            for _ in 0..<LearningRules.reviewDecisionPasses {
                let schedule = progress.progress(for: lessonID)?.reviewSchedule ?? ReviewScheduler.ScheduleState()
                let pass = ReviewScheduler.evaluate(
                    schedule: schedule,
                    today: today,
                    isFullRun: true,
                    fromMemory: true,
                    bpm: 100,
                    targetBpm: 100,
                    score: 0.9,
                    notesHidden: true
                )
                let stepDecision = ReviewScheduler.advanceWindow(window, with: pass)
                window = stepDecision.window
                if let outcome = stepDecision.outcome {
                    decidedOutcome = outcome
                }
            }
            if let outcome = decidedOutcome {
                progress.updateReviewSchedule(outcome.newSchedule, for: lessonID, autoSave: false)
                progress.recordReviewRun(lessonId: lessonID, passed: true, today: today, autoSave: false)
            }
            return decidedOutcome
        }

        // Case 1: Played in Review queue first, then opened from Today panel.
        let queueFirstFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(suiteName)-queue-first.json")
        defer { try? FileManager.default.removeItem(at: queueFirstFile) }
        let progress1 = ProgressStore(fileURL: queueFirstFile, autoLoad: false)
        progress1.setProgress(
            LessonProgress(passed: true, mastery: true, masteryDay: yesterday, reviewStep: 0, reviewDueDay: today),
            for: 1
        )
        let plan1 = TodayPlan.make(day: today, dueLessonIDs: [1], nextLessonID: 99, mixLessonIDs: [])!

        let firstQueueOutcome = completeReviewRun(for: 1, in: progress1)
        XCTAssertNotNil(firstQueueOutcome?.feedback)
        XCTAssertEqual(progress1.progress(for: 1)?.reviewStep, 1)
        XCTAssertEqual(progress1.trainingLog.reviewsPassed, 1)

        let coordinator1 = TodaySessionCoordinator(plan: plan1, defaults: defaults)
        coordinator1.reconcileReviews(progress: progress1)
        XCTAssertEqual(coordinator1.plan.reviewSummary.passed, 1)
        XCTAssertEqual(coordinator1.plan.index, 1)

        let repeatAttempt1 = completeReviewRun(for: 1, in: progress1)
        XCTAssertNil(repeatAttempt1)
        XCTAssertEqual(progress1.progress(for: 1)?.reviewStep, 1)
        XCTAssertEqual(progress1.trainingLog.reviewsPassed, 1)

        // Case 2: Started from Today panel first, then replayed from Review queue on the same day.
        let todayFirstFile = FileManager.default.temporaryDirectory.appendingPathComponent("\(suiteName)-today-first.json")
        defer { try? FileManager.default.removeItem(at: todayFirstFile) }
        let progress2 = ProgressStore(fileURL: todayFirstFile, autoLoad: false)
        progress2.setProgress(
            LessonProgress(passed: true, mastery: true, masteryDay: yesterday, reviewStep: 0, reviewDueDay: today),
            for: 2
        )
        let plan2 = TodayPlan.make(day: today, dueLessonIDs: [2], nextLessonID: 99, mixLessonIDs: [])!

        let coordinator2 = TodaySessionCoordinator(plan: plan2, defaults: defaults)
        coordinator2.continueSession()
        let todayOutcome = completeReviewRun(for: 2, in: progress2)
        XCTAssertNotNil(todayOutcome?.feedback)
        coordinator2.record(PracticeStepOutcome(bestScore: 0.9, reviewFeedback: todayOutcome?.feedback))
        coordinator2.leavePractice(progress: progress2)

        XCTAssertEqual(coordinator2.plan.reviewSummary.passed, 1)
        XCTAssertEqual(progress2.progress(for: 2)?.reviewStep, 1)
        XCTAssertEqual(progress2.trainingLog.reviewsPassed, 1)

        let queueReplay = completeReviewRun(for: 2, in: progress2)
        XCTAssertNil(queueReplay)
        XCTAssertEqual(progress2.progress(for: 2)?.reviewStep, 1)
        XCTAssertEqual(progress2.trainingLog.reviewsPassed, 1)
        XCTAssertEqual(coordinator2.plan.reconcilingReviews(with: progress2.records).reviewSummary.passed, 1)
    }

    @MainActor
    func testReconcilingReviewsAndPostponeNeverMovePassedReviewBackToToday() {
        let today = AppCalendar.today()
        let nextWeek = AppCalendar.addingDays(7, to: today) ?? today
        let suiteName = "TodayPlanTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suiteName).json")
        defer { try? FileManager.default.removeItem(at: file) }

        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let passed = LessonProgress(passed: true, mastery: true, memory: true,
                                    currentBpm: 90, reviewStep: 2, reviewDueDay: nextWeek,
                                    lastReviewedDay: today)
        progress.setProgress(passed, for: 6)

        let plan = TodayPlan.make(day: today, dueLessonIDs: [6], nextLessonID: 7, mixLessonIDs: [])!
        let reconciled = plan.reconcilingReviews(with: progress.records)
        XCTAssertEqual(reconciled.reviewSummary.passed, 1)
        XCTAssertEqual(reconciled.steps[0].outcome?.reviewFeedback, .passed(nextStep: 2, gapDays: 7))

        // Postponing directly or via TodaySessionCoordinator must leave a passed review on its future date.
        let postponedSchedule = ReviewScheduler.postpone(passed.reviewSchedule, today: today)
        XCTAssertEqual(postponedSchedule.reviewDueDay, nextWeek)
        XCTAssertEqual(postponedSchedule.lastReviewedDay, today)

        progress.postponeReview(for: 6, today: today)
        XCTAssertEqual(progress.progress(for: 6)?.reviewDueDay, nextWeek)
        XCTAssertFalse(progress.dueLessonIds(today: today).contains(6))

        let coordinator = TodaySessionCoordinator(plan: plan, defaults: defaults)
        coordinator.skip(progress: progress)
        XCTAssertEqual(progress.progress(for: 6)?.reviewDueDay, nextWeek)
        XCTAssertFalse(progress.dueLessonIds(today: today).contains(6))
    }

    @MainActor
    func testContinueTargetResolvesSessionSummaryOrNilAcrossPlanStates() {
        let day = "2026-11-12"
        let activePlan = TodayPlan(
            day: day,
            steps: [
                .init(kind: .review, lessonIDs: [1]),
                .init(kind: .newLesson, lessonIDs: [2])
            ]
        )

        if case .session(let resolved) = TodayContinueTarget.resolve(
            currentPlan: activePlan,
            today: day,
            nextLessonID: 99,
            mixLessonIDs: [10, 11]
        ) {
            XCTAssertEqual(resolved.day, day)
            XCTAssertEqual(resolved.steps.count, 2)
            XCTAssertFalse(resolved.finished)
        } else {
            XCTFail("Expected active plan to open the Today session")
        }

        var finishedPlan = activePlan
        finishedPlan.index = finishedPlan.steps.count
        finishedPlan.finished = true
        finishedPlan.phase = .summary
        if case .summary(let resolved) = TodayContinueTarget.resolve(
            currentPlan: finishedPlan,
            today: day,
            nextLessonID: nil,
            mixLessonIDs: []
        ) {
            XCTAssertTrue(resolved.finished)
            XCTAssertEqual(resolved.phase, .summary)
        } else {
            XCTFail("Expected finished plan to open the day summary")
        }

        var exhaustedPlan = activePlan
        exhaustedPlan.index = exhaustedPlan.steps.count
        exhaustedPlan.finished = false
        if case .summary(let resolved) = TodayContinueTarget.resolve(
            currentPlan: exhaustedPlan,
            today: day,
            nextLessonID: nil,
            mixLessonIDs: []
        ) {
            XCTAssertTrue(resolved.finished)
            XCTAssertEqual(resolved.phase, .summary)
        } else {
            XCTFail("Expected exhausted plan to normalize to the day summary")
        }

        if case .summary(let resolved) = TodayContinueTarget.resolve(
            currentPlan: TodayPlan(day: day, steps: []),
            today: day,
            nextLessonID: nil,
            mixLessonIDs: []
        ) {
            XCTAssertTrue(resolved.finished)
            XCTAssertEqual(resolved.phase, .summary)
        } else {
            XCTFail("Expected empty plan to open the day summary")
        }

        if case .session(let fallback) = TodayContinueTarget.resolve(
            currentPlan: nil,
            today: day,
            nextLessonID: 5,
            mixLessonIDs: [10, 11]
        ) {
            XCTAssertEqual(fallback.steps.map(\.kind), [.newLesson, .mix])
            XCTAssertEqual(fallback.steps.map(\.lessonIDs), [[5], [10, 11]])
        } else {
            XCTFail("Expected no-plan fallback with next lesson and mix to open a session")
        }

        XCTAssertNil(TodayContinueTarget.resolve(
            currentPlan: nil,
            today: day,
            nextLessonID: nil,
            mixLessonIDs: [10]
        ))
    }

    @MainActor
    func testAfterLastMixLessonOutcomeRecordedTodayStateReportsMixDoneAndNextActionDaySummary() throws {
        let suite = "today-mix-done-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let today = AppCalendar.today()

        let plan = TodayPlan(day: today, steps: [
            .init(kind: .review, lessonIDs: [1], outcome: PracticeStepOutcome(bestScore: 0.9, reviewFeedback: .settled)),
            .init(kind: .newLesson, lessonIDs: [2], outcome: PracticeStepOutcome(bestScore: 0.85)),
            .init(kind: .mix, lessonIDs: [1, 2])
        ], index: 2, finished: false, phase: .practice)

        let coordinator = TodaySessionCoordinator(plan: plan, defaults: defaults)
        // Record the last mix lesson's outcome
        coordinator.record(PracticeStepOutcome(bestScore: 0.9))

        // 1. In coordinator.plan, mix is done
        let mixStep = try XCTUnwrap(coordinator.plan.steps.first(where: { $0.kind == .mix }))
        XCTAssertEqual(mixStep.status, .passed)

        // 2. Next action is day summary without any extra reload call
        let target = TodayContinueTarget.resolve(
            currentPlan: coordinator.plan,
            today: today,
            nextLessonID: nil,
            mixLessonIDs: [1, 2]
        )
        if case .summary(let summaryPlan) = target {
            XCTAssertTrue(summaryPlan.finished)
        } else {
            XCTFail("Expected next action to be day summary, but got: \(String(describing: target))")
        }

        // 3. Saved day state in defaults also reports mix done and summary
        let savedJson = try XCTUnwrap(defaults.string(forKey: TodayPlan.storageKey))
        let savedPlan = try XCTUnwrap(TodayPlan.decode(savedJson, today: today))
        let savedMixStep = try XCTUnwrap(savedPlan.steps.first(where: { $0.kind == .mix }))
        XCTAssertEqual(savedMixStep.status, .passed)

        let savedTarget = TodayContinueTarget.resolve(
            currentPlan: savedPlan,
            today: today,
            nextLessonID: nil,
            mixLessonIDs: [1, 2]
        )
        if case .summary(let summaryPlan) = savedTarget {
            XCTAssertTrue(summaryPlan.finished)
        } else {
            XCTFail("Expected saved plan next action to be day summary, but got: \(String(describing: savedTarget))")
        }
    }
}
