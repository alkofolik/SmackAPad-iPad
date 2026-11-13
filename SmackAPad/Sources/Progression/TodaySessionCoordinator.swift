import Foundation
import Observation

/// Persists the daily steps while Training owns presentation and navigation.
@MainActor
@Observable
final class TodaySessionCoordinator {
    private(set) var plan: TodayPlan
    private let defaults: UserDefaults

    init(plan: TodayPlan, defaults: UserDefaults = .standard) {
        var normalized = plan
        if normalized.finished || normalized.steps.isEmpty || normalized.index >= normalized.steps.count {
            normalized.index = normalized.steps.count
            normalized.finished = true
            normalized.phase = .summary
        }
        self.plan = normalized
        self.defaults = defaults
    }

    var currentStep: TodayPlan.Step? {
        plan.steps.indices.contains(plan.index) ? plan.steps[plan.index] : nil
    }

    var nextAction: TodayContinueTarget? {
        TodayContinueTarget.resolve(currentPlan: plan, today: plan.day, nextLessonID: nil, mixLessonIDs: [])
    }

    func record(_ outcome: PracticeStepOutcome) {
        guard plan.day == AppCalendar.today(), !plan.finished, plan.phase == .practice,
              plan.steps.indices.contains(plan.index) else { return }
        var result = plan.steps[plan.index].outcome ?? PracticeStepOutcome()
        result.include(outcome)
        plan.steps[plan.index].outcome = result
        plan.lastPlayedIndex = plan.index
        if plan.isFinished {
            plan.finished = true
            plan.phase = .summary
        }
        save()
    }

    func reconcileReviews(progress: ProgressStore) {
        let previous = plan
        plan = plan.reconcilingReviews(with: progress.records)
        if !plan.finished {
            movePastPlayedSteps()
            if plan.isFinished {
                plan.finished = true
                plan.phase = .summary
            } else if plan.index != previous.index {
                updatePhaseAfterAdvance()
            }
        }
        if plan != previous { save() }
    }

    func leavePractice(progress: ProgressStore) {
        guard !plan.finished, plan.phase == .practice else { return }
        plan = plan.reconcilingReviews(with: progress.records)
        guard let step = currentStep else { return }
        postponeIfUnplayed(step, progress: progress)
        plan.lastPlayedIndex = plan.index
        advance()
    }

    func continueSession() {
        guard !plan.finished else { return }
        plan.phase = .practice
        save()
    }

    func replaceCurrentMixLessons(_ lessons: [Lesson]) {
        guard !plan.finished, plan.steps.indices.contains(plan.index),
              plan.steps[plan.index].kind == .mix,
              lessons.count >= LearningRules.minimumMixLessons else { return }
        plan.steps[plan.index].lessonIDs = lessons.map(\.id)
        save()
    }

    func skip(progress: ProgressStore) {
        guard !plan.finished else { return }
        plan = plan.reconcilingReviews(with: progress.records)
        guard let step = currentStep else { return }
        postponeIfUnplayed(step, progress: progress)
        advance()
    }

    func finish(progress: ProgressStore) {
        guard !plan.finished else { return }
        plan = plan.reconcilingReviews(with: progress.records)
        for step in plan.steps.dropFirst(plan.index) { postponeIfUnplayed(step, progress: progress) }
        plan.index = plan.steps.count
        plan.finished = true
        plan.phase = .summary
        save()
    }

    private func postponeIfUnplayed(_ step: TodayPlan.Step, progress: ProgressStore) {
        guard plan.day == AppCalendar.today(), step.kind == .review, step.outcome?.played != true,
              let id = step.lessonIDs.first else { return }
        progress.postponeReview(for: id, today: plan.day)
    }

    private func advance() {
        plan.index += 1
        movePastPlayedSteps()
        updatePhaseAfterAdvance()
        save()
    }

    private func movePastPlayedSteps() {
        while let step = currentStep, step.outcome?.played == true {
            plan.index += 1
        }
    }

    private func updatePhaseAfterAdvance() {
        plan.finished = plan.index >= plan.steps.count
        plan.phase = plan.finished ? .summary : .handoff
    }

    private func save() {
        guard let json = plan.encoded else { return }
        defaults.set(json, forKey: TodayPlan.storageKey)
    }
}

/// Decision for what Training's Continue button opens: the next daily step,
/// the day summary when finished/empty, or nil when no training steps exist yet.
enum TodayContinueTarget: Equatable {
    case step(TodayPlan)
    case summary(TodayPlan)

    var plan: TodayPlan {
        switch self {
        case .step(let plan), .summary(let plan):
            return plan
        }
    }

    static func resolve(
        currentPlan: TodayPlan?,
        today: String,
        nextLessonID: Int?,
        mixLessonIDs: [Int]
    ) -> TodayContinueTarget? {
        if var plan = currentPlan {
            while !plan.finished, plan.steps.indices.contains(plan.index),
                  plan.steps[plan.index].outcome?.played == true {
                plan.index += 1
            }
            if plan.isFinished {
                plan.index = plan.steps.count
                plan.finished = true
                plan.phase = .summary
                return .summary(plan)
            }
            return .step(plan)
        }
        var steps: [TodayPlan.Step] = []
        if let nextLessonID {
            steps.append(.init(kind: .newLesson, lessonIDs: [nextLessonID]))
        }
        if mixLessonIDs.count >= LearningRules.minimumMixLessons {
            steps.append(.init(kind: .mix, lessonIDs: mixLessonIDs))
        }
        guard !steps.isEmpty else { return nil }
        return .step(TodayPlan(day: today, steps: steps))
    }
}

