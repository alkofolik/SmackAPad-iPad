import Foundation

/// Shared helper that returns the requirement descriptions for each star
/// and the next missing star guidance.
public enum StarRequirement {
    /// 0: Star 1 (Passed), 1: Star 2 (Goal tempo), 2: Star 3 (From memory).
    public static func nextMissingStarIndex(progress: LessonProgress?) -> Int? {
        guard let progress else { return 0 }
        if !progress.passed { return 0 }
        if !progress.mastery { return 1 }
        if !progress.memory { return 2 }
        return nil
    }

    /// Returns the text for an individual star requirement.
    public static func requirementText(
        for starIndex: Int,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        language: AppLanguage = .english
    ) -> String {
        switch starIndex {
        case 0:
            if requiredRuns > 1 {
                return language.localized("Pass the lesson, %lld times in a row", requiredRuns)
            } else {
                return language.localized("Pass the lesson")
            }
        case 1:
            if let bpm = targetBpm {
                if requiredRuns > 1 {
                    return language.localized("Reach %lld BPM cleanly, %lld times in a row", bpm, requiredRuns)
                } else {
                    return language.localized("Reach %lld BPM cleanly", bpm)
                }
            } else {
                if requiredRuns > 1 {
                    return language.localized("Reach the goal tempo cleanly, %lld times in a row", requiredRuns)
                } else {
                    return language.localized("Reach the goal tempo cleanly")
                }
            }
        case 2:
            if let bpm = targetBpm {
                if requiredRuns > 1 {
                    return language.localized("Play it from memory at %lld BPM, 80 %% or better, %lld times in a row", bpm, requiredRuns)
                } else {
                    return language.localized("Play it from memory at %lld BPM, 80 %% or better", bpm)
                }
            } else {
                if requiredRuns > 1 {
                    return language.localized("Play it from memory at goal tempo, 80 %% or better, %lld times in a row", requiredRuns)
                } else {
                    return language.localized("Play it from memory at goal tempo, 80 % or better")
                }
            }
        default:
            return ""
        }
    }

    /// Convenience overload using SettingsManager.
    public static func requirementText(
        for starIndex: Int,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        settings: SettingsManager? = nil
    ) -> String {
        requirementText(for: starIndex, requiredRuns: requiredRuns, targetBpm: targetBpm, language: settings?.languagePreference ?? .english)
    }

    /// Convenience overload for a Lesson.
    public static func requirementText(
        for starIndex: Int,
        lesson: Lesson,
        padCount: Int = 16,
        settings: SettingsManager? = nil
    ) -> String {
        let expectedHits = lesson.hits(forPadCount: padCount).count
        let runs = StarStreak.requiredRuns(expectedHits: expectedHits, isIntro: lesson.cat == "intro" && starIndex != 0)
        return requirementText(for: starIndex, requiredRuns: runs, targetBpm: lesson.targetBpm, settings: settings)
    }

    /// Returns the guidance line for the next missing star (e.g. "Next: play it from memory at 85 BPM, 80 % or better"),
    /// or nil if all three stars have already been earned.
    public static func nextMissingStarText(
        progress: LessonProgress?,
        requiredRuns: Int = 1,
        targetBpm: Int? = nil,
        language: AppLanguage = .english
    ) -> String? {
        guard let index = nextMissingStarIndex(progress: progress) else { return nil }
        let text = requirementText(for: index, requiredRuns: requiredRuns, targetBpm: targetBpm, language: language)
        guard !text.isEmpty else { return nil }
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
        nextMissingStarText(progress: progress, requiredRuns: requiredRuns, targetBpm: targetBpm, language: settings?.languagePreference ?? .english)
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
