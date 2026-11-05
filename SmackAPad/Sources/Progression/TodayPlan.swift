import Foundation

/// A calendar day's immutable selection, with the current position and outcomes saved alongside it.
struct TodayPlan: Codable, Equatable {
    static let storageKey = "smackapad.training.today"

    struct Step: Codable, Equatable {
        enum Kind: String, Codable { case review, newLesson, mix }
        let kind: Kind
        let lessonIDs: [Int]
        var outcome: PracticeStepOutcome?
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

    /// `dueLessonIDs` comes from ProgressStore.dueLessonIds, already ordered oldest first.
    static func make(day: String, dueLessonIDs: [Int], nextLessonID: Int?, mixLessonIDs: [Int]) -> TodayPlan? {
        guard !dueLessonIDs.isEmpty else { return nil }
        var steps = dueLessonIDs.prefix(2).map { Step(kind: .review, lessonIDs: [$0]) }
        if let nextLessonID { steps.append(Step(kind: .newLesson, lessonIDs: [nextLessonID])) }
        if mixLessonIDs.count >= 2 { steps.append(Step(kind: .mix, lessonIDs: mixLessonIDs)) }
        return TodayPlan(day: day, steps: steps)
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

    var played: Bool { bestScore != nil }

    mutating func include(_ other: Self) {
        bestScore = [bestScore, other.bestScore].compactMap { $0 }.max()
        if let feedback = other.reviewFeedback { reviewFeedback = feedback }
    }
}
