import Foundation

/// Shared helper that returns the requirement descriptions for each star
/// and the next missing star guidance.
public enum StarRequirement {
    /// 0: Star 1 (Passed), 1: Star 2 (Goal tempo), 2: Star 3 (Two reviews in Training).
    public static func nextMissingStarIndex(progress: LessonProgress?) -> Int? {
        guard let progress else { return 0 }
        if !progress.passed { return 0 }
        if !progress.mastery { return 1 }
        if !progress.memory { return 2 }
        return nil
    }

    /// Number of reviews passed in Training toward Star 3 (0, 1, or 2).
    public static func reviewsPassedCount(progress: LessonProgress?) -> Int {
        guard let progress else { return 0 }
        if progress.reviewSchedule.isSettled { return 2 }
        return min(2, max(0, progress.reviewStep ?? 0))
    }

    /// Returns the text for an individual star requirement.
    public static func requirementText(
        for starIndex: Int,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        language: AppLanguage = .english,
        mode: PracticeMode = .learning,
        reviewsPassed: Int = 0
    ) -> String {
        switch starIndex {
        case 0:
            if requiredRuns > 1 {
                return language.localized(mode == .challenge ? "Pass the lesson, %lld times in a row" : "Pass the lesson, %lld times", requiredRuns)
            } else {
                return language.localized("Pass the lesson")
            }
        case 1:
            if let bpm = targetBpm {
                if requiredRuns > 1 {
                    return language.localized(mode == .challenge ? "Reach %lld BPM cleanly, %lld times in a row" : "Reach %lld BPM cleanly, %lld times", bpm, requiredRuns)
                } else {
                    return language.localized("Reach %lld BPM cleanly", bpm)
                }
            } else {
                if requiredRuns > 1 {
                    return language.localized(mode == .challenge ? "Reach the goal tempo cleanly, %lld times in a row" : "Reach the goal tempo cleanly, %lld times", requiredRuns)
                } else {
                    return language.localized("Reach the goal tempo cleanly")
                }
            }
        case 2:
            return language.localized("Star 3: two reviews in Training · %lld of 2", reviewsPassed)
        default:
            return ""
        }
    }

    /// Convenience overload using LessonProgress.
    public static func requirementText(
        for starIndex: Int,
        progress: LessonProgress?,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        language: AppLanguage = .english,
        mode: PracticeMode = .learning
    ) -> String {
        requirementText(for: starIndex, requiredRuns: requiredRuns, targetBpm: targetBpm, language: language, mode: mode, reviewsPassed: reviewsPassedCount(progress: progress))
    }

    /// Convenience overload using SettingsManager.
    public static func requirementText(
        for starIndex: Int,
        progress: LessonProgress? = nil,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        settings: SettingsManager? = nil
    ) -> String {
        requirementText(for: starIndex, requiredRuns: requiredRuns, targetBpm: targetBpm, language: settings?.languagePreference ?? .english, mode: settings?.practiceMode ?? .learning, reviewsPassed: reviewsPassedCount(progress: progress))
    }

    /// Convenience overload for a Lesson.
    public static func requirementText(
        for starIndex: Int,
        lesson: Lesson,
        progress: LessonProgress? = nil,
        padCount: Int = 16,
        settings: SettingsManager? = nil
    ) -> String {
        let expectedHits = lesson.hits(forPadCount: padCount).count
        let runs = StarStreak.requiredRuns(expectedHits: expectedHits, isIntro: lesson.cat == "intro" && starIndex != 0)
        return requirementText(for: starIndex, requiredRuns: runs, targetBpm: lesson.targetBpm, language: settings?.languagePreference ?? .english, mode: settings?.practiceMode ?? .learning, reviewsPassed: reviewsPassedCount(progress: progress))
    }

    /// Returns the guidance line for the next missing star,
    /// or nil if all three stars have already been earned.
    public static func nextMissingStarText(
        progress: LessonProgress?,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        language: AppLanguage = .english,
        mode: PracticeMode = .learning
    ) -> String? {
        guard let index = nextMissingStarIndex(progress: progress) else { return nil }
        let text = requirementText(for: index, progress: progress, requiredRuns: requiredRuns, targetBpm: targetBpm, language: language, mode: mode)
        guard !text.isEmpty else { return nil }
        if index == 2 {
            return text
        }
        let lowered = text.prefix(1).lowercased() + text.dropFirst()
        return language.localized("Next: %@", lowered)
    }

    /// Convenience overload using SettingsManager.
    public static func nextMissingStarText(
        progress: LessonProgress?,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        settings: SettingsManager? = nil
    ) -> String? {
        nextMissingStarText(progress: progress, requiredRuns: requiredRuns, targetBpm: targetBpm, language: settings?.languagePreference ?? .english, mode: settings?.practiceMode ?? .learning)
    }

    /// Convenience overload for a Lesson.
    public static func nextMissingStarText(
        progress: LessonProgress?,
        lesson: Lesson,
        padCount: Int = 16,
        settings: SettingsManager? = nil
    ) -> String? {
        let expectedHits = lesson.hits(forPadCount: padCount).count
        let first = nextMissingStarIndex(progress: progress) == 0
        let runs = StarStreak.requiredRuns(expectedHits: expectedHits, isIntro: lesson.cat == "intro" && !first)
        return nextMissingStarText(progress: progress, requiredRuns: runs, targetBpm: lesson.targetBpm, settings: settings)
    }
}
