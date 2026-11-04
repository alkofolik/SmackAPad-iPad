import Foundation

/// Cumulative evaluation statistics across all lessons in the catalogue.
struct BadgeProgressStats: Equatable, Sendable {
    let passed: Int
    let mastered: Int
    let memory: Int
    let courses: Int
    let totalLessons: Int
    let groupTotals: [String: Int]
    let groupProgress: [String: Int]

    init(
        passed: Int = 0,
        mastered: Int = 0,
        memory: Int = 0,
        courses: Int = 0,
        totalLessons: Int = 0,
        groupTotals: [String: Int] = [:],
        groupProgress: [String: Int] = [:]
    ) {
        self.passed = passed
        self.mastered = mastered
        self.memory = memory
        self.courses = courses
        self.totalLessons = totalLessons
        self.groupTotals = groupTotals
        self.groupProgress = groupProgress
    }
}

/// Output of a badge evaluation pass.
struct BadgeEvaluationResult: Equatable, Sendable {
    let stats: BadgeProgressStats
    let newlyEarnedBadgeIds: [String]

    init(stats: BadgeProgressStats, newlyEarnedBadgeIds: [String]) {
        self.stats = stats
        self.newlyEarnedBadgeIds = newlyEarnedBadgeIds
    }
}

/// Pure evaluation function computing stats and earned badge IDs.
enum BadgeEvaluator {
    static func metric(for technique: LessonTechnique) -> String {
        switch technique {
        case .groove: return "tech-groove"
        case .sixteenths: return "tech-sixteenths"
        case .ghost: return "tech-ghost"
        case .swing: return "tech-swing"
        case .fills: return "tech-fills"
        }
    }

    static func metric(for genre: LessonGenre) -> String {
        "genre-\(genre.id)"
    }

    static func metric(forLevel level: Int) -> String {
        "level-\(level)"
    }

    static func evaluate(
        progress: [Int: LessonProgress],
        catalog: LibraryCatalog,
        definitions: [BadgeDefinition],
        currentlyEarned: Set<String>
    ) -> BadgeEvaluationResult {
        var passedCount = 0
        var masteredCount = 0
        var memoryCount = 0
        var groupTotals: [String: Int] = [:]
        var groupProgress: [String: Int] = [:]

        // Pre-initialize standard metrics
        for lvl in 1...5 {
            let key = metric(forLevel: lvl)
            groupTotals[key] = 0
            groupProgress[key] = 0
        }
        for genre in LessonGenre.allCases {
            let key = metric(for: genre)
            groupTotals[key] = 0
            groupProgress[key] = 0
        }
        for technique in LessonTechnique.allCases {
            let key = metric(for: technique)
            groupTotals[key] = 0
            groupProgress[key] = 0
        }

        for lesson in catalog.lessons {
            let record = progress[lesson.id]
            let hasStar1 = record?.passed == true || record?.mastery == true
            let hasStar2 = record?.mastery == true
            let hasStar3 = record?.memory == true

            if hasStar1 { passedCount += 1 }
            if hasStar2 { masteredCount += 1 }
            if hasStar3 { memoryCount += 1 }

            let levelKey = metric(forLevel: lesson.level)
            groupTotals[levelKey, default: 0] += 1
            if hasStar1 {
                groupProgress[levelKey, default: 0] += 1
            }

            let genre = LessonGenre.classify(lesson)
            let genreKey = metric(for: genre)
            groupTotals[genreKey, default: 0] += 1
            if hasStar1 {
                groupProgress[genreKey, default: 0] += 1
            }

            let technique = LessonTechnique.classify(lesson)
            let techKey = metric(for: technique)
            groupTotals[techKey, default: 0] += 1
            if hasStar1 {
                groupProgress[techKey, default: 0] += 1
            }
        }

        let completedStages = catalog.stages.filter { stage in
            !stage.lessons.isEmpty && stage.lessons.allSatisfy { progress[$0.id]?.mastery == true }
        }.count

        let stats = BadgeProgressStats(
            passed: passedCount,
            mastered: masteredCount,
            memory: memoryCount,
            courses: completedStages,
            totalLessons: catalog.lessons.count,
            groupTotals: groupTotals,
            groupProgress: groupProgress
        )

        var newlyEarned: [String] = []
        for badge in definitions {
            guard !currentlyEarned.contains(badge.id) else { continue }
            let goal = targetGoal(for: badge, in: stats)
            let current = currentProgress(for: badge, in: stats)
            if goal > 0 && current >= goal {
                newlyEarned.append(badge.id)
            }
        }

        return BadgeEvaluationResult(stats: stats, newlyEarnedBadgeIds: newlyEarned)
    }

    static func targetGoal(for badge: BadgeDefinition, in stats: BadgeProgressStats) -> Int {
        switch badge.goal {
        case .count(let count):
            return count
        case .catalogue:
            return stats.totalLessons
        case .group:
            return stats.groupTotals[badge.metric] ?? 0
        }
    }

    static func currentProgress(for badge: BadgeDefinition, in stats: BadgeProgressStats) -> Int {
        switch badge.metric {
        case "passed":
            return stats.passed
        case "mastered":
            return stats.mastered
        case "memory":
            return stats.memory
        case "courses":
            return stats.courses
        default:
            return stats.groupProgress[badge.metric] ?? 0
        }
    }
}
