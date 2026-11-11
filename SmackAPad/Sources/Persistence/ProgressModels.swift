//
//  ProgressModels.swift
//  SmackAPad
//

import Foundation

// MARK: - Lesson Progress Model

/// Progress record for an individual lesson matching SPEC §4.3:
/// `{ passed: Bool, mastery: Bool, memory: Bool, currentBpm: Int, bestScore: Float }`
public struct LessonProgress: Codable, Equatable, Hashable, Sendable {
    public var hasPlayed: Bool
    public var passed: Bool
    public var mastery: Bool
    public var memory: Bool
    public var currentBpm: Int
    public var bestScore: Float
    public var lastPlayedDay: String?
    public var masteryDay: String?
    public var reviewStep: Int?
    public var reviewDueDay: String?
    public var settled: Bool?
    public var lastReviewedDay: String?
    public var lastReviewFailDay: String?
    var learningCreditByPadCount: [String: StarStreak] = [:]
    public var modifiedAt: Date?

    public static func == (lhs: LessonProgress, rhs: LessonProgress) -> Bool {
        lhs.hasPlayed == rhs.hasPlayed &&
        lhs.passed == rhs.passed &&
        lhs.mastery == rhs.mastery &&
        lhs.memory == rhs.memory &&
        lhs.currentBpm == rhs.currentBpm &&
        lhs.bestScore == rhs.bestScore &&
        lhs.lastPlayedDay == rhs.lastPlayedDay &&
        lhs.masteryDay == rhs.masteryDay &&
        lhs.reviewStep == rhs.reviewStep &&
        lhs.reviewDueDay == rhs.reviewDueDay &&
        lhs.settled == rhs.settled &&
        lhs.lastReviewedDay == rhs.lastReviewedDay &&
        lhs.lastReviewFailDay == rhs.lastReviewFailDay &&
        lhs.learningCreditByPadCount == rhs.learningCreditByPadCount
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(hasPlayed)
        hasher.combine(passed)
        hasher.combine(mastery)
        hasher.combine(memory)
        hasher.combine(currentBpm)
        hasher.combine(bestScore)
        hasher.combine(lastPlayedDay)
        hasher.combine(masteryDay)
        hasher.combine(reviewStep)
        hasher.combine(reviewDueDay)
        hasher.combine(settled)
        hasher.combine(lastReviewedDay)
        hasher.combine(lastReviewFailDay)
        hasher.combine(learningCreditByPadCount)
    }

    /// Imported stars remain earned; an untouched review chain is an invitation, not a failed counter.
    var isUnstartedLegacyReview: Bool {
        memory && (reviewStep ?? 0) == 0 && settled != true
            && lastReviewedDay == nil && lastReviewFailDay == nil
    }

    public var reviewSchedule: ReviewScheduler.ScheduleState {
        get {
            ReviewScheduler.ScheduleState(reviewStep: reviewStep, reviewDueDay: reviewDueDay, settled: settled,
                                          lastReviewedDay: lastReviewedDay)
        }
        set {
            self.reviewStep = newValue.reviewStep
            self.reviewDueDay = newValue.reviewDueDay
            self.settled = newValue.settled
            self.lastReviewedDay = newValue.lastReviewedDay
        }
    }

    public init(
        passed: Bool = false,
        mastery: Bool = false,
        memory: Bool = false,
        hasPlayed: Bool = false,
        currentBpm: Int = 0,
        bestScore: Float = 0.0,
        lastPlayedDay: String? = nil,
        masteryDay: String? = nil,
        reviewStep: Int? = nil,
        reviewDueDay: String? = nil,
        settled: Bool? = nil,
        lastReviewedDay: String? = nil,
        lastReviewFailDay: String? = nil,
        modifiedAt: Date? = nil
    ) {
        self.hasPlayed = hasPlayed || passed || mastery || memory
        self.passed = passed
        self.mastery = mastery
        self.memory = memory
        self.currentBpm = currentBpm
        self.bestScore = bestScore
        self.lastPlayedDay = lastPlayedDay
        self.masteryDay = masteryDay
        self.reviewStep = reviewStep
        self.reviewDueDay = reviewDueDay
        self.settled = settled
        self.lastReviewedDay = lastReviewedDay
        self.lastReviewFailDay = lastReviewFailDay
        self.modifiedAt = modifiedAt
    }

    private enum CodingKeys: String, CodingKey {
        case hasPlayed, passed, mastery, memory, currentBpm, bestScore, masteryDay, lastPlayedDay, learningCreditByPadCount
        case reviewStep, reviewDueDay, settled, lastReviewedDay, lastReviewFailDay, modifiedAt
    }

    /// Existing progress files predate the memory star and review schedule.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        passed = try values.decode(Bool.self, forKey: .passed)
        mastery = try values.decode(Bool.self, forKey: .mastery)
        memory = try values.decodeIfPresent(Bool.self, forKey: .memory) ?? false
        currentBpm = try values.decode(Int.self, forKey: .currentBpm)
        bestScore = try values.decode(Float.self, forKey: .bestScore)
        lastPlayedDay = try values.decodeIfPresent(String.self, forKey: .lastPlayedDay)
        masteryDay = try values.decodeIfPresent(String.self, forKey: .masteryDay)
        learningCreditByPadCount = try values.decodeIfPresent([String: StarStreak].self, forKey: .learningCreditByPadCount) ?? [:]
        reviewStep = try values.decodeIfPresent(Int.self, forKey: .reviewStep)
        reviewDueDay = try values.decodeIfPresent(String.self, forKey: .reviewDueDay)
        settled = try values.decodeIfPresent(Bool.self, forKey: .settled)
        lastReviewedDay = try values.decodeIfPresent(String.self, forKey: .lastReviewedDay)
        lastReviewFailDay = try values.decodeIfPresent(String.self, forKey: .lastReviewFailDay)
        if let dateString = try? values.decodeIfPresent(String.self, forKey: .modifiedAt) {
            let formatter = ISO8601DateFormatter()
            modifiedAt = formatter.date(from: dateString)
        } else {
            modifiedAt = try values.decodeIfPresent(Date.self, forKey: .modifiedAt)
        }
        // Old records did not distinguish a saved tempo from an interrupted attempt.
        hasPlayed = try values.decodeIfPresent(Bool.self, forKey: .hasPlayed) ?? (passed || mastery || memory || currentBpm > 0 || bestScore > 0)
    }
}

// MARK: - TrainingLog & ProgressRoot

/// Cumulative training counts and session sets persisted in the progress file.
public struct TrainingLog: Codable, Equatable, Hashable, Sendable {
    public var reviewsPassed: Int
    public var bounceBacks: Int
    public var mixRounds: Int
    public var mixMemoryRounds: Int
    public var afterMeLessons: Set<Int>
    public var trainingDays: Set<String>

    public init(
        reviewsPassed: Int = 0,
        bounceBacks: Int = 0,
        mixRounds: Int = 0,
        mixMemoryRounds: Int = 0,
        afterMeLessons: Set<Int> = [],
        trainingDays: Set<String> = []
    ) {
        self.reviewsPassed = reviewsPassed
        self.bounceBacks = bounceBacks
        self.mixRounds = mixRounds
        self.mixMemoryRounds = mixMemoryRounds
        self.afterMeLessons = afterMeLessons
        self.trainingDays = trainingDays
    }

    public static func merging(_ existing: TrainingLog, with incoming: TrainingLog) -> TrainingLog {
        TrainingLog(
            reviewsPassed: max(existing.reviewsPassed, incoming.reviewsPassed),
            bounceBacks: max(existing.bounceBacks, incoming.bounceBacks),
            mixRounds: max(existing.mixRounds, incoming.mixRounds),
            mixMemoryRounds: max(existing.mixMemoryRounds, incoming.mixMemoryRounds),
            afterMeLessons: existing.afterMeLessons.union(incoming.afterMeLessons),
            trainingDays: existing.trainingDays.union(incoming.trainingDays)
        )
    }
}

/// Root structure of the progress JSON file.
/// Decodes both legacy flat dictionary format (`[String: LessonProgress]`) and the structured format.
public struct ProgressRoot: Codable, Equatable, Sendable {
    public var formatVersion: Int
    public var lessons: [Int: LessonProgress]
    public var trainingLog: TrainingLog

    public init(formatVersion: Int = 1, lessons: [Int: LessonProgress] = [:], trainingLog: TrainingLog = TrainingLog()) {
        self.formatVersion = formatVersion
        self.lessons = lessons
        self.trainingLog = trainingLog
    }

    private enum CodingKeys: String, CodingKey {
        case formatVersion
        case lessons
        case trainingLog
        case reviewsPassed
        case bounceBacks
        case mixRounds
        case mixMemoryRounds
        case afterMeLessons
        case trainingDays
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self),
           container.contains(.lessons) {
            let version = try container.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
            if version > 1 {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unsupported formatVersion: \(version)"
                    )
                )
            }
            self.formatVersion = version

            let stringLessons = try container.decode([String: LessonProgress].self, forKey: .lessons)
            var convertedLessons: [Int: LessonProgress] = [:]
            for (k, v) in stringLessons {
                if let id = Int(k) { convertedLessons[id] = v }
            }
            self.lessons = convertedLessons

            if let nested = try? container.decodeIfPresent(TrainingLog.self, forKey: .trainingLog) {
                self.trainingLog = nested
            } else {
                let reviews = try container.decodeIfPresent(Int.self, forKey: .reviewsPassed) ?? 0
                let bounce = try container.decodeIfPresent(Int.self, forKey: .bounceBacks) ?? 0
                let rounds = try container.decodeIfPresent(Int.self, forKey: .mixRounds) ?? 0
                let memRounds = try container.decodeIfPresent(Int.self, forKey: .mixMemoryRounds) ?? 0
                let afterMe = try container.decodeIfPresent(Set<Int>.self, forKey: .afterMeLessons) ?? []
                let days = try container.decodeIfPresent(Set<String>.self, forKey: .trainingDays) ?? []
                self.trainingLog = TrainingLog(
                    reviewsPassed: reviews,
                    bounceBacks: bounce,
                    mixRounds: rounds,
                    mixMemoryRounds: memRounds,
                    afterMeLessons: afterMe,
                    trainingDays: days
                )
            }
        } else {
            let container = try decoder.singleValueContainer()
            let stringLessons = try container.decode([String: LessonProgress].self)
            var convertedLessons: [Int: LessonProgress] = [:]
            for (k, v) in stringLessons {
                if let id = Int(k) { convertedLessons[id] = v }
            }
            self.formatVersion = 1
            self.lessons = convertedLessons
            self.trainingLog = TrainingLog()
        }

        // Old progress: reviewsPassed starts at least at the passes implied by the schedule
        let impliedPasses = self.lessons.values.reduce(0) { sum, record in
            sum + (record.settled == true ? LearningRules.settledReviewPasses : (record.reviewStep ?? 0))
        }
        self.trainingLog.reviewsPassed = max(self.trainingLog.reviewsPassed, impliedPasses)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(formatVersion, forKey: .formatVersion)
        var stringLessons: [String: LessonProgress] = [:]
        for (id, record) in lessons {
            stringLessons[String(id)] = record
        }
        try container.encode(stringLessons, forKey: .lessons)
        try container.encode(trainingLog.reviewsPassed, forKey: .reviewsPassed)
        try container.encode(trainingLog.bounceBacks, forKey: .bounceBacks)
        try container.encode(trainingLog.mixRounds, forKey: .mixRounds)
        try container.encode(trainingLog.mixMemoryRounds, forKey: .mixMemoryRounds)
        try container.encode(Array(trainingLog.afterMeLessons).sorted(), forKey: .afterMeLessons)
        try container.encode(Array(trainingLog.trainingDays).sorted(), forKey: .trainingDays)
    }
}

