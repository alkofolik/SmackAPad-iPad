import Foundation

/// A calendar day's immutable selection, with the current position and outcomes saved alongside it.
struct TodayPlan: Codable, Equatable {
    static let storageKey = "smackapad.training.today"

    struct Step: Codable, Equatable {
        enum Kind: String, Codable { case review, newLesson, mix }
        let kind: Kind
        var lessonIDs: [Int]
        var outcome: PracticeStepOutcome?

        /// Shared by the step marks, handoff and summary. A score alone cannot pass a review.
        var status: PracticeStepOutcome.Status? {
            guard let outcome, outcome.played else { return nil }
            guard kind == .review else { return (outcome.bestScore ?? 0) >= Scoring.passMark ? .passed : .played }
            switch outcome.reviewFeedback {
            case .passed, .settled: return .passed
            case .failed: return .triedNotMet
            case .doesNotCount(let bpm): return .inProgress(.requirements(goalBpm: bpm))
            case nil: return .inProgress(outcome.reviewPendingReason ?? .unfinishedReview)
            }
        }

        var markerSymbol: String? {
            switch status {
            case .inProgress: return "exclamationmark.circle"
            case .triedNotMet: return "xmark"
            default: return nil
            }
        }
    }

    enum Phase: String, Codable { case practice, handoff, summary }
    let day: String
    var steps: [Step]
    var index = 0
    var finished = false
    var phase: Phase = .practice
    var lastPlayedIndex: Int?

    var reviewCount: Int { steps.filter { $0.kind == .review }.count }
    var hasNewLesson: Bool { steps.contains { $0.kind == .newLesson } }

    private var remainingSteps: [Step] {
        guard !finished else { return [] }
        return steps.dropFirst(index).filter { $0.outcome?.played != true }
    }

    var remainingStepCount: Int { remainingSteps.count }
    var isFinished: Bool { remainingStepCount == 0 }

    var estimatedMinutes: Int {
        let remaining = remainingSteps
        guard !remaining.isEmpty else { return 0 }
        let minutes = remaining.reduce(0.0) { total, step in
            total + (step.kind == .review ? 1.5 : 2.0)
        }
        return max(2, Int(minutes.rounded()))
    }

    struct ReviewSummary: Equatable {
        var played = 0
        var passed = 0
        var inProgress = 0
        var notPlayed = 0
        var triedNotMet = 0
    }

    var reviewSummary: ReviewSummary {
        steps.filter { $0.kind == .review }.reduce(into: ReviewSummary()) { summary, step in
            switch step.status {
            case .passed: summary.passed += 1; summary.played += 1
            case .inProgress: summary.inProgress += 1; summary.played += 1
            case .triedNotMet: summary.triedNotMet += 1; summary.played += 1
            case .played: summary.played += 1
            case nil: summary.notPlayed += 1
            }
        }
    }

    func reconcilingReviews(with records: [Int: LessonProgress]) -> Self {
        var plan = self
        for index in steps.indices {
            let step = steps[index]
            guard step.kind == .review, step.outcome?.played != true,
                  let id = step.lessonIDs.first, let record = records[id],
                  (record.reviewSchedule.lastReviewedDay == day || record.lastReviewFailDay == day) else { continue }

            let reviewStep = record.reviewStep ?? 0
            let feedback: ReviewScheduler.ReviewFeedback
            if record.lastReviewFailDay == day {
                feedback = .failed(newStep: reviewStep)
            } else if record.reviewSchedule.isSettled {
                feedback = .settled
            } else {
                let gap = record.reviewDueDay.flatMap { AppCalendar.daysBetween(day, $0) } ?? 0
                feedback = .passed(nextStep: reviewStep, gapDays: gap)
            }
            // Progress stores the decision but has no score for this specific run.
            plan.steps[index].outcome = PracticeStepOutcome(reviewFeedback: feedback)
        }
        return plan
    }

    /// Keep the saved daily selection stable as its lessons leave the due list.
    struct ReviewLoad {
        let todayIDs: [Int]
        let queueIDs: [Int]

        init(dueLessonIDs: [Int], plan: TodayPlan?) {
            todayIDs = plan.map { $0.steps.filter { $0.kind == .review }.flatMap(\.lessonIDs) }
                ?? Array(dueLessonIDs.prefix(LearningRules.dailyReviewLimit))
            let selected = Set(todayIDs)
            queueIDs = dueLessonIDs.filter { !selected.contains($0) }
        }
    }

    /// `dueLessonIDs` comes from `ReviewQueue.order`, already ordered by fragility (lowest reviewStep first, then most days late, then earlier masteryDay, then lesson id).
    static func make(
        day: String, dueLessonIDs: [Int], nextLessonID: Int?, followUpLessonID: Int? = nil
    ) -> TodayPlan? {
        var steps = dueLessonIDs.prefix(LearningRules.dailyReviewLimit).map { Step(kind: .review, lessonIDs: [$0]) }
        if let nextLessonID {
            steps.append(Step(kind: .newLesson, lessonIDs: [nextLessonID]))
            if dueLessonIDs.isEmpty, let followUpLessonID, followUpLessonID != nextLessonID {
                steps.append(Step(kind: .newLesson, lessonIDs: [followUpLessonID]))
            }
        }
        guard !steps.isEmpty else { return nil }
        return TodayPlan(day: day, steps: steps)
    }

    var encoded: String? {
        (try? JSONEncoder().encode(self)).flatMap { String(data: $0, encoding: .utf8) }
    }

    static func decode(_ json: String, today: String) -> TodayPlan? {
        guard let plan = try? JSONDecoder().decode(Self.self, from: Data(json.utf8)),
              plan.day == today, !plan.steps.isEmpty,
              (0...plan.steps.count).contains(plan.index),
              plan.finished || plan.index < plan.steps.count,
              plan.steps.allSatisfy({ !$0.lessonIDs.isEmpty }) else { return nil }
        return plan
    }
}

/// Full runs only, accumulated across restarts of a single daily step.
struct PracticeStepOutcome: Codable, Equatable {
    var bestScore: Double?
    var reviewFeedback: ReviewScheduler.ReviewFeedback?
    var reviewPendingReason: Reason?

    enum Status: Equatable {
        case played, passed, inProgress(Reason), triedNotMet

        var titleKey: String {
            switch self {
            case .played: return "Played"
            case .passed: return "Passed"
            case .inProgress(let reason): return reason.titleKey
            case .triedNotMet: return "Tried today · not met yet"
            }
        }

        var reason: Reason? {
            if case .inProgress(let reason) = self { return reason }
            return nil
        }
    }

    enum Reason: Codable, Equatable {
        case notesVisible, peeked, unfinishedReview, reviewNotPassed, requirements(goalBpm: Int)

        var titleKey: String {
            switch self {
            case .notesVisible: return "Warm-up complete"
            case .peeked: return "Peek used"
            case .unfinishedReview: return "1 of 2 from memory"
            case .reviewNotPassed: return "Review not passed"
            case .requirements: return "Practice tempo"
            }
        }

        func title(language: AppLanguage, reviewSuccesses: Int? = nil) -> String {
            switch self {
            case .unfinishedReview where reviewSuccesses == 0:
                return language.localized("Warmed up")
            default:
                return language.localized(titleKey)
            }
        }

        func message(language: AppLanguage) -> String {
            switch self {
            case .notesVisible:
                return language.localized("Now play 2 passes from memory")
            case .peeked:
                return language.localized("Try the next pass from memory")
            case .unfinishedReview:
                return language.localized("One more clean memory pass to finish")
            case .reviewNotPassed:
                return PracticeStepOutcome.reviewFailureReason(feedback: .failed(newStep: 0), language: language)
                    ?? (language == .czech ? "Opakování zatím nesplněno · dnes ho ještě můžeš splnit" : "Review not met yet · you can still pass it today")
            case .requirements(let bpm):
                return language.localized("For review credit, play from memory at %lld BPM", bpm)
            }
        }
    }

    var hasDecidedReview: Bool {
        switch reviewFeedback {
        case .passed, .settled, .failed: return true
        case .doesNotCount, nil: return false
        }
    }

    var played: Bool { bestScore != nil || hasDecidedReview }

    mutating func include(_ other: Self) {
        bestScore = [bestScore, other.bestScore].compactMap { $0 }.max()
        // A pass or settled decision takes precedence over an open failure.
        if other.reviewFeedback?.isPassing == true {
            reviewFeedback = other.reviewFeedback
            reviewPendingReason = other.reviewPendingReason
        } else if !hasDecidedReview, other.played {
            reviewFeedback = other.reviewFeedback
            reviewPendingReason = other.reviewPendingReason
        }
    }
}

extension PracticeStepOutcome {
    /// Pure function returning the failure reason for a review step, or nil if the review counted (passed/settled).
    public static func reviewFailureReason(
        feedback: ReviewScheduler.ReviewFeedback?,
        language: AppLanguage
    ) -> String? {
        guard let feedback else {
            return language == .czech ? "Přeskočeno · zítra znovu" : "Skipped · again tomorrow"
        }
        switch feedback {
        case .passed, .settled:
            return nil
        case .failed:
            return language == .czech
                ? "Opakování zatím nesplněno · dnes ho ještě můžeš splnit"
                : "Review not met yet · you can still pass it today"
        case .doesNotCount:
            return language == .czech ? "Přeskočeno · zítra znovu" : "Skipped · again tomorrow"
        }
    }

    public static func reviewFailureReason(
        outcome: PracticeStepOutcome?,
        language: AppLanguage
    ) -> String? {
        reviewFailureReason(feedback: outcome?.reviewFeedback, language: language)
    }
}

extension TodayPlan.Step {
    /// Pure function returning the reason why a review did not count, or nil if it counted or is not a review.
    public func reviewFailureReason(language: AppLanguage) -> String? {
        guard kind == .review else { return nil }
        return PracticeStepOutcome.reviewFailureReason(outcome: outcome, language: language)
    }
}
