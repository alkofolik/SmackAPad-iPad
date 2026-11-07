//
//  ReviewScheduler.swift
//  SmackAPad
//
//  Spaced review schedule ("Due" / "Na řadě") following ticket 98.
//

import Foundation

/// Spaced review schedule rules:
/// - Step 0 → 1 day gap
/// - Step 1 → 3 days gap
/// - Step 2 → 7 days gap
/// - Step 3 → 21 days gap
/// - Passing step 3 marks the lesson settled ("upevněno")
public struct ReviewScheduler: Sendable {
    /// The review interval gaps in days corresponding to steps 0, 1, 2, 3.
    public static let gaps: [Int] = [1, 3, 7, 21]

    /// Encapsulates the review schedule state of a lesson.
    public struct ScheduleState: Equatable, Hashable, Sendable {
        public var reviewStep: Int?
        public var reviewDueDay: String?
        public var settled: Bool?
        public var lastReviewedDay: String?

        public init(
            reviewStep: Int? = nil,
            reviewDueDay: String? = nil,
            settled: Bool? = nil,
            lastReviewedDay: String? = nil
        ) {
            self.reviewStep = reviewStep
            self.reviewDueDay = reviewDueDay
            self.settled = settled
            self.lastReviewedDay = lastReviewedDay
        }

        public var isSettled: Bool {
            settled == true
        }

        public func isDue(on today: String) -> Bool {
            guard !isSettled, let reviewDueDay else { return false }
            return today >= reviewDueDay
        }
    }

    /// Feedback to present on the result card or announcement.
    public enum ReviewFeedback: Codable, Equatable, Hashable, Sendable {
        case passed(nextStep: Int, gapDays: Int)
        case settled
        case failed(newStep: Int)
        case doesNotCount(goalBpm: Int)

        /// Formats the feedback message in the specified app language.
        public func message(language: AppLanguage) -> String {
            switch self {
            case .passed(_, let gapDays):
                if language == .czech {
                    if gapDays == 1 {
                        return "Opakování splněno · další za 1 den"
                    } else if gapDays >= 2 && gapDays <= 4 {
                        return String(format: "Opakování splněno · další za %lld dny", gapDays)
                    } else {
                        return String(format: "Opakování splněno · další za %lld dní", gapDays)
                    }
                } else {
                    if gapDays == 1 {
                        return "Review passed · next in 1 day"
                    } else {
                        return String(format: "Review passed · next in %lld days", gapDays)
                    }
                }

            case .settled:
                return language == .czech ? "Lekce je upevněná" : "Lesson settled"

            case .failed:
                return language == .czech ? "Opakování nesplněno · znovu zítra" : "Review not passed · again tomorrow"

            case .doesNotCount(let goalBpm):
                return language == .czech
                    ? String(format: "Nepočítá se · hraj zpaměti při %lld BPM", goalBpm)
                    : String(format: "Does not count · play from memory at %lld BPM", goalBpm)
            }
        }
    }

    /// Result of evaluating a run against the review schedule.
    public struct Outcome: Equatable, Sendable {
        public let newSchedule: ScheduleState
        public let feedback: ReviewFeedback?

        public init(newSchedule: ScheduleState, feedback: ReviewFeedback?) {
            self.newSchedule = newSchedule
            self.feedback = feedback
        }
    }

    /// Ephemeral counts for one lesson's review attempt. Never persisted.
    public struct WindowState: Equatable, Sendable {
        public var successes = 0
        public var failures = 0

        public init() {}

        public var isDecided: Bool { successes >= 2 || failures >= 2 }
    }

    public struct WindowOutcome: Equatable, Sendable {
        public let window: WindowState
        public let outcome: Outcome?
    }

    /// Accumulates eligible pass results; only a certain majority commits a schedule.
    /// `evaluate` supplies the eligibility checks and the unchanged review gaps.
    public static func advanceWindow(_ window: WindowState, with passResult: Outcome) -> WindowOutcome {
        guard !window.isDecided else { return WindowOutcome(window: window, outcome: nil) }
        var next = window
        switch passResult.feedback {
        case .passed, .settled:
            next.successes += 1
        case .failed:
            next.failures += 1
        case .doesNotCount, nil:
            return WindowOutcome(window: window, outcome: nil)
        }
        return WindowOutcome(window: next, outcome: next.isDecided ? passResult : nil)
    }

    /// Ticket 143: Decides whether a review outcome earns Star 3.
    /// Star 3 is earned when a review outcome is passed/settled and the lesson
    /// has now passed two reviews in total (reviewStep reaches >= 2 or is settled).
    public static func mayEarnStar3(outcome: Outcome?, progress: LessonProgress?) -> Bool {
        guard let outcome, let feedback = outcome.feedback else { return false }
        guard progress?.memory != true else { return false }
        switch feedback {
        case .passed, .settled:
            let step = outcome.newSchedule.reviewStep ?? 0
            return step >= 2 || outcome.newSchedule.isSettled
        case .failed, .doesNotCount:
            return false
        }
    }

    public static func mayEarnStar3(outcome: Outcome, progress: LessonProgress?) -> Bool {
        mayEarnStar3(outcome: Optional(outcome), progress: progress)
    }

    /// Pure function: schedule + run result + today → new schedule and feedback.
    /// Under ticket 99, when fadeNotes is on, only hidden passes (pass >= 3) count as reviews.
    public static func evaluate(
        schedule: ScheduleState,
        today: String,
        isFullRun: Bool,
        fromMemory: Bool,
        bpm: Int,
        targetBpm: Int,
        score: Float,
        pass: Int = 3,
        fadeNotes: Bool = true
    ) -> Outcome {
        guard schedule.isDue(on: today), schedule.lastReviewedDay != today else {
            return Outcome(newSchedule: schedule, feedback: nil)
        }

        // Section loops or non-full runs do not count as review runs
        guard isFullRun else {
            return Outcome(newSchedule: schedule, feedback: nil)
        }
        // When notes fade out over the first passes in From memory, passes 1–2 do not count as reviews
        if fadeNotes && pass < 3 {
            return Outcome(newSchedule: schedule, feedback: nil)
        }

        let atGoalTempo = bpm >= targetBpm
        if !fromMemory || !atGoalTempo {
            return Outcome(newSchedule: schedule, feedback: .doesNotCount(goalBpm: targetBpm))
        }

        let currentStep = schedule.reviewStep ?? 0
        let passed = score >= 0.80

        if passed {
            if currentStep >= 3 {
                let newSched = ScheduleState(reviewStep: 3, reviewDueDay: nil, settled: true, lastReviewedDay: today)
                return Outcome(newSchedule: newSched, feedback: .settled)
            } else {
                let nextStep = currentStep + 1
                let gapDays = gaps[nextStep]
                let nextDueDay = AppCalendar.addingDays(gapDays, to: today) ?? today
                let newSched = ScheduleState(reviewStep: nextStep, reviewDueDay: nextDueDay, settled: false, lastReviewedDay: today)
                return Outcome(newSchedule: newSched, feedback: .passed(nextStep: nextStep, gapDays: gapDays))
            }
        } else {
            let newStep = max(0, currentStep - 1)
            let tomorrow = AppCalendar.addingDays(1, to: today) ?? today
            let newSched = ScheduleState(reviewStep: newStep, reviewDueDay: tomorrow, settled: false, lastReviewedDay: today)
            return Outcome(newSchedule: newSched, feedback: .failed(newStep: newStep))
        }
    }

    /// Defers an unplayed due review without changing its progress.
    public static func postpone(_ schedule: ScheduleState, today: String) -> ScheduleState {
        guard schedule.isDue(on: today), schedule.lastReviewedDay != today else { return schedule }
        var postponed = schedule
        postponed.reviewDueDay = AppCalendar.addingDays(1, to: today) ?? today
        return postponed
    }

    /// Initial schedule when star 2 is first earned: scheduled for masteryDay + 1.
    public static func initialSchedule(masteryDay: String) -> ScheduleState {
        let firstDue = AppCalendar.addingDays(1, to: masteryDay) ?? masteryDay
        return ScheduleState(reviewStep: 0, reviewDueDay: firstDue, settled: false)
    }

    /// Migration schedule for lessons that already had star 2 before this update: first review tomorrow.
    public static func migrationSchedule(today: String) -> ScheduleState {
        let tomorrow = AppCalendar.addingDays(1, to: today) ?? today
        return ScheduleState(reviewStep: 0, reviewDueDay: tomorrow, settled: false)
    }

    /// Merges two schedules keeping the further-progressed schedule.
    public static func merge(_ a: ScheduleState, _ b: ScheduleState) -> ScheduleState {
        var result = mergedSchedule(a, b)
        result.lastReviewedDay = [a.lastReviewedDay, b.lastReviewedDay].compactMap { $0 }.max()
        return result
    }

    private static func mergedSchedule(_ a: ScheduleState, _ b: ScheduleState) -> ScheduleState {
        if a.isSettled || b.isSettled {
            let maxStep = max(a.reviewStep ?? 0, b.reviewStep ?? 0)
            return ScheduleState(reviewStep: maxStep, reviewDueDay: nil, settled: true)
        }
        guard let aDue = a.reviewDueDay else { return b }
        guard let bDue = b.reviewDueDay else { return a }

        let stepA = a.reviewStep ?? 0
        let stepB = b.reviewStep ?? 0
        if stepA > stepB { return a }
        if stepB > stepA { return b }
        return aDue >= bDue ? a : b
    }
}
