import Foundation

public enum ProgressMerge {
    /// Pure merge of two LessonProgress records with "never lose anything" rules.
    public static func mergeLesson(local: LessonProgress, incoming: LessonProgress) -> LessonProgress {
        var result = local
        result.passed = local.passed || incoming.passed
        result.mastery = local.mastery || incoming.mastery
        result.memory = local.memory || incoming.memory
        result.hasPlayed = local.hasPlayed || incoming.hasPlayed
        result.bestScore = max(local.bestScore, incoming.bestScore)

        // learningCreditByPadCount: union by key, max of streaks
        var mergedCredit = local.learningCreditByPadCount
        for (key, incomingStreak) in incoming.learningCreditByPadCount {
            if let localStreak = mergedCredit[key] {
                mergedCredit[key] = StarStreak(
                    passedRuns: max(localStreak.passedRuns, incomingStreak.passedRuns),
                    masteryRuns: max(localStreak.masteryRuns, incomingStreak.masteryRuns),
                    memoryRuns: max(localStreak.memoryRuns, incomingStreak.memoryRuns)
                )
            } else {
                mergedCredit[key] = incomingStreak
            }
        }
        result.learningCreditByPadCount = mergedCredit

        // masteryDay: earlier non-nil
        if let d1 = local.masteryDay, let d2 = incoming.masteryDay {
            result.masteryDay = min(d1, d2)
        } else {
            result.masteryDay = local.masteryDay ?? incoming.masteryDay
        }

        // lastPlayedDay: later non-nil
        if let d1 = local.lastPlayedDay, let d2 = incoming.lastPlayedDay {
            result.lastPlayedDay = max(d1, d2)
        } else {
            result.lastPlayedDay = local.lastPlayedDay ?? incoming.lastPlayedDay
        }

        // lastReviewFailDay: later non-nil
        if let d1 = local.lastReviewFailDay, let d2 = incoming.lastReviewFailDay {
            result.lastReviewFailDay = max(d1, d2)
        } else {
            result.lastReviewFailDay = local.lastReviewFailDay ?? incoming.lastReviewFailDay
        }

        // currentBpm: from record with later lastPlayedDay (tie -> higher BPM)
        if local.currentBpm <= 0 {
            result.currentBpm = incoming.currentBpm
        } else if incoming.currentBpm <= 0 {
            result.currentBpm = local.currentBpm
        } else {
            let dayLocal = local.lastPlayedDay
            let dayIncoming = incoming.lastPlayedDay
            if let dl = dayLocal, let di = dayIncoming {
                if dl > di {
                    result.currentBpm = local.currentBpm
                } else if di > dl {
                    result.currentBpm = incoming.currentBpm
                } else {
                    result.currentBpm = max(local.currentBpm, incoming.currentBpm)
                }
            } else if dayLocal != nil {
                result.currentBpm = local.currentBpm
            } else if dayIncoming != nil {
                result.currentBpm = incoming.currentBpm
            } else {
                result.currentBpm = max(local.currentBpm, incoming.currentBpm)
            }
        }

        // Review schedule: taken as an indivisible group from the record reviewed more recently
        result.reviewSchedule = mergeReviewSchedule(local: local, incoming: incoming)

        // modifiedAt: max of non-nil dates
        if let m1 = local.modifiedAt, let m2 = incoming.modifiedAt {
            result.modifiedAt = max(m1, m2)
        } else {
            result.modifiedAt = local.modifiedAt ?? incoming.modifiedAt
        }

        return result
    }

    /// Selects the review schedule as a single group from whichever record has the most up-to-date review state.
    public static func mergeReviewSchedule(local: LessonProgress, incoming: LessonProgress) -> ReviewScheduler.ScheduleState {
        let localSchedule = local.reviewSchedule
        let incomingSchedule = incoming.reviewSchedule

        let localHasSchedule = localSchedule.reviewStep != nil || localSchedule.reviewDueDay != nil || localSchedule.settled == true || localSchedule.lastReviewedDay != nil
        let incomingHasSchedule = incomingSchedule.reviewStep != nil || incomingSchedule.reviewDueDay != nil || incomingSchedule.settled == true || incomingSchedule.lastReviewedDay != nil

        if !localHasSchedule && !incomingHasSchedule {
            return localSchedule
        }
        if !localHasSchedule {
            return incomingSchedule
        }
        if !incomingHasSchedule {
            return localSchedule
        }

        // Settled logic: A settled lesson has graduated. It is never un-settled by an older backup.
        if localSchedule.isSettled && !incomingSchedule.isSettled {
            if let settledDay = localSchedule.lastReviewedDay,
               let incDay = incomingSchedule.lastReviewedDay,
               incDay > settledDay {
                return incomingSchedule
            }
            return localSchedule
        }
        if incomingSchedule.isSettled && !localSchedule.isSettled {
            if let settledDay = incomingSchedule.lastReviewedDay,
               let locDay = localSchedule.lastReviewedDay,
               locDay > settledDay {
                return localSchedule
            }
            return incomingSchedule
        }
        if localSchedule.isSettled && incomingSchedule.isSettled {
            if let d1 = localSchedule.lastReviewedDay, let d2 = incomingSchedule.lastReviewedDay {
                return d2 > d1 ? incomingSchedule : localSchedule
            }
            return localSchedule
        }

        // Compare lastReviewedDay
        let d1 = localSchedule.lastReviewedDay
        let d2 = incomingSchedule.lastReviewedDay

        if let d1 = d1, let d2 = d2 {
            if d1 > d2 { return localSchedule }
            if d2 > d1 { return incomingSchedule }
        } else if d1 != nil {
            return localSchedule
        } else if d2 != nil {
            return incomingSchedule
        }

        // Compare modifiedAt
        if let m1 = local.modifiedAt, let m2 = incoming.modifiedAt {
            if m1 > m2 { return localSchedule }
            if m2 > m1 { return incomingSchedule }
        } else if local.modifiedAt != nil {
            return localSchedule
        } else if incoming.modifiedAt != nil {
            return incomingSchedule
        }

        // Tie-break: pick higher reviewStep
        let step1 = local.reviewStep ?? 0
        let step2 = incoming.reviewStep ?? 0
        if step1 > step2 { return localSchedule }
        if step2 > step1 { return incomingSchedule }

        // Tie-break: earlier reviewDueDay (sooner review)
        if let due1 = local.reviewDueDay, let due2 = incoming.reviewDueDay {
            if due1 < due2 { return localSchedule }
            if due2 < due1 { return incomingSchedule }
        } else if local.reviewDueDay != nil {
            return localSchedule
        } else if incoming.reviewDueDay != nil {
            return incomingSchedule
        }

        return localSchedule
    }

    /// Merges cumulative training counts and days using max of counters and union of sets.
    public static func mergeTrainingLog(local: TrainingLog, incoming: TrainingLog) -> TrainingLog {
        TrainingLog.merging(local, with: incoming)
    }

    /// Merges badges by union of IDs, preserving the earlier earned date for existing badges.
    public static func mergeBadges(local: [String: Date], incoming: [String: Date]) -> [String: Date] {
        var result = local
        for (badgeId, incomingDate) in incoming {
            if let localDate = result[badgeId] {
                result[badgeId] = min(localDate, incomingDate)
            } else {
                result[badgeId] = incomingDate
            }
        }
        return result
    }

    /// Determines whether the local device has no earned progress yet.
    public static func isFreshDevice(
        records: [Int: LessonProgress],
        trainingLog: TrainingLog,
        earnedBadgesCount: Int
    ) -> Bool {
        let hasStars = records.values.contains { $0.passed || $0.mastery || $0.memory }
        let hasTraining = !trainingLog.trainingDays.isEmpty ||
            trainingLog.reviewsPassed > 0 ||
            trainingLog.bounceBacks > 0 ||
            trainingLog.mixRounds > 0
        return !hasStars && !hasTraining && earnedBadgesCount == 0
    }

    /// Merges an incoming dictionary of lesson progress into local lessons, applying migrations and filtering unknown catalog IDs.
    public static func mergeLessons(
        localLessons: [Int: LessonProgress],
        incomingLessons: [Int: LessonProgress],
        validLessonIds: Set<Int>? = nil
    ) -> (merged: [Int: LessonProgress], updatedCount: Int, unrecognizedCount: Int) {
        var incoming = incomingLessons

        // Apply migrations to incoming data
        ProgressStore.migrateDuplicateIntroProgress(in: &incoming)
        ProgressStore.migrateLegacyMasteredReviewSchedule(in: &incoming)
        ProgressStore.migrateTwoReviewsStar3(in: &incoming)

        var validIncoming: [Int: LessonProgress] = [:]
        var unrecognizedCount = 0

        for (id, record) in incoming {
            if let validLessonIds {
                if validLessonIds.contains(id) {
                    validIncoming[id] = record
                } else {
                    unrecognizedCount += 1
                }
            } else {
                validIncoming[id] = record
            }
        }

        var merged = localLessons
        var updatedCount = 0

        for (id, incomingRecord) in validIncoming {
            let localRecord = merged[id] ?? LessonProgress()
            let mergedRecord = mergeLesson(local: localRecord, incoming: incomingRecord)
            if mergedRecord != localRecord {
                updatedCount += 1
                merged[id] = mergedRecord
            }
        }

        return (merged, updatedCount, unrecognizedCount)
    }
}
