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
    let settled: Int
    let reviewsPassed: Int
    let bounceBacks: Int
    let mixRounds: Int
    let mixMemoryRounds: Int
    let afterMeLessons: Int
    let trainingDays: Int

    init(
        passed: Int = 0,
        mastered: Int = 0,
        memory: Int = 0,
        courses: Int = 0,
        totalLessons: Int = 0,
        groupTotals: [String: Int] = [:],
        groupProgress: [String: Int] = [:],
        settled: Int = 0,
        reviewsPassed: Int = 0,
        bounceBacks: Int = 0,
        mixRounds: Int = 0,
        mixMemoryRounds: Int = 0,
        afterMeLessons: Int = 0,
        trainingDays: Int = 0
    ) {
        self.passed = passed
        self.mastered = mastered
        self.memory = memory
        self.courses = courses
        self.totalLessons = totalLessons
        self.groupTotals = groupTotals
        self.groupProgress = groupProgress
        self.settled = settled
        self.reviewsPassed = reviewsPassed
        self.bounceBacks = bounceBacks
        self.mixRounds = mixRounds
        self.mixMemoryRounds = mixMemoryRounds
        self.afterMeLessons = afterMeLessons
        self.trainingDays = trainingDays
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
        currentlyEarned: Set<String>,
        trainingLog: TrainingLog = TrainingLog()
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

        let settledCount = progress.values.filter { $0.settled == true }.count

        let stats = BadgeProgressStats(
            passed: passedCount,
            mastered: masteredCount,
            memory: memoryCount,
            courses: completedStages,
            totalLessons: catalog.lessons.count,
            groupTotals: groupTotals,
            groupProgress: groupProgress,
            settled: settledCount,
            reviewsPassed: trainingLog.reviewsPassed,
            bounceBacks: trainingLog.bounceBacks,
            mixRounds: trainingLog.mixRounds,
            mixMemoryRounds: trainingLog.mixMemoryRounds,
            afterMeLessons: trainingLog.afterMeLessons.count,
            trainingDays: trainingLog.trainingDays.count
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
        case "settled":
            return stats.settled
        case "reviewsPassed":
            return stats.reviewsPassed
        case "bounceBacks":
            return stats.bounceBacks
        case "mixRounds":
            return stats.mixRounds
        case "mixMemoryRounds":
            return stats.mixMemoryRounds
        case "afterMeLessons":
            return stats.afterMeLessons
        case "trainingDays":
            return stats.trainingDays
        default:
            return stats.groupProgress[badge.metric] ?? 0
        }
    }
}
