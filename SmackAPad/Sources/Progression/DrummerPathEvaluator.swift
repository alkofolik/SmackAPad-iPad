import Foundation

// MARK: - Stage Exams, Milestones & Unlock Outcomes

/// Significant progress milestone (achievement, optionally awarding a Tuning Key).
public struct DrummerMilestone: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let rewardKeys: Int

    public init(id: String, title: String, description: String, rewardKeys: Int = 0) {
        self.id = id
        self.title = title
        self.description = description
        self.rewardKeys = rewardKeys
    }
}

/// Outcome of attempting to spend a key to unlock a drum kit.
public enum KitUnlockResult: Equatable, Sendable {
    case unlocked(kit: DrumKitDescriptor, remainingKeys: Int)
    case alreadyUnlocked(kit: DrumKitDescriptor)
    case insufficientKeys(kit: DrumKitDescriptor, needed: Int, available: Int)
    case unknownKit(kitId: String)
}

/// Result of evaluating updated play progress against the RPG state.
public struct DrummerPathEvaluationOutcome: Equatable, Sendable {
    public let updatedState: DrummerPathState
    public let newlyCompletedExamStageIDs: [String]
    public let newlyEarnedMilestoneIDs: [String]
    public let newlyAwardedKeySourceIDs: [String]
    public let newlyUnlockedSkinIDs: [String]
    public let newlyUnlockedBonusTrackIDs: [String]
    public let keysAwarded: Int
    public let card: DrummerCardSnapshot
    public let delta: DrummerProgressDelta
}

// MARK: - Evaluator

/// Pure game-progression evaluator for Drummer's Path & Studio Rig.
/// Computes XP, levels, ranks, 4 musical attributes, keys, kit unlocks, skins, bonus tracks, and legacy migration.
public enum DrummerPathEvaluator {
    public static let introExamStageId = "intro"
    public static let tenBossesMilestoneId = "ten-bosses"

    public static let keyAwardingExamStageIDs: Set<String> = [
        introExamStageId,
        "L1-groove",
        "L1-swing",
        "L2-sixteenths",
        "L3-ghost",
        "L4-fills"
    ]

    public static let suggestedKitIdByKeySource: [String: String] = [
        introExamStageId: "rock",
        "L1-groove": "808",
        "L1-swing": "jazz",
        "L2-sixteenths": "house",
        tenBossesMilestoneId: "brush",
        "L3-ghost": "world",
        "L4-fills": "worldperc"
    ]

    public static let milestones: [DrummerMilestone] = [
        DrummerMilestone(
            id: "intro-spark",
            title: "First Spark",
            description: "Pass 5 Intro exercises."
        ),
        DrummerMilestone(
            id: "intro-graduate",
            title: "Intro Graduate",
            description: "Pass all Intro exercises or the Intro boss lesson."
        ),
        DrummerMilestone(
            id: "first-mastery",
            title: "Goal Tempo",
            description: "Master your first lesson at goal tempo (2★)."
        ),
        DrummerMilestone(
            id: "ten-passed",
            title: "Ten Grooves",
            description: "Pass 10 different lessons."
        ),
        DrummerMilestone(
            id: "ten-mastered",
            title: "Tempo Builder",
            description: "Master 10 lessons at goal tempo (2★)."
        ),
        DrummerMilestone(
            id: "memory-specialist",
            title: "Memory Specialist",
            description: "Earn 5 Memory stars (3★)."
        ),
        DrummerMilestone(
            id: "review-habit",
            title: "Steady Recall",
            description: "Pass 5 spaced reviews."
        ),
        DrummerMilestone(
            id: "twenty-five-mastered",
            title: "Pocket Veteran",
            description: "Master 25 lessons at goal tempo (2★)."
        ),
        DrummerMilestone(
            id: tenBossesMilestoneId,
            title: "Boss Slayer",
            description: "Defeat 10 distinct stage bosses.",
            rewardKeys: 1
        )
    ]

    public static let keyAwardingMilestoneIDs: Set<String> = Set(
        milestones.filter { $0.rewardKeys > 0 }.map(\.id)
    )

    public static func earnedKeyCount(exams: Set<String>, milestones: Set<String>) -> Int {
        exams.intersection(keyAwardingExamStageIDs).count
            + milestones.intersection(keyAwardingMilestoneIDs).count
    }

    public static func suggestedKit(forKeySource sourceId: String) -> DrumKitDescriptor? {
        guard let kitId = suggestedKitIdByKeySource[sourceId] else { return nil }
        return DrumKitCatalog.kit(forId: kitId)
    }

    // MARK: - XP, Level & Attributes

    /// Cumulative XP threshold required to reach `level` (1-based).
    public static func cumulativeXPRequired(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        var total = 0
        for current in 1..<level {
            total += 120 + (current - 1) * 60
        }
        return total
    }

    /// Computes level and XP bracket bounds for a given total XP.
    public static func levelBreakdown(forXP xp: Int) -> (level: Int, currentLevelXP: Int, nextLevelXP: Int) {
        let clampedXP = max(0, xp)
        var level = 1
        while clampedXP >= cumulativeXPRequired(forLevel: level + 1) {
            level += 1
        }
        let currentFloor = cumulativeXPRequired(forLevel: level)
        let nextFloor = cumulativeXPRequired(forLevel: level + 1)
        return (level, currentFloor, nextFloor)
    }

    /// Computes the full Drummer Card snapshot deterministically from real play data.
    static func computeCard(
        progress: [Int: LessonProgress],
        catalog: LibraryCatalog,
        trainingLog: TrainingLog,
        state: DrummerPathState
    ) -> DrummerCardSnapshot {
        let lessonsById = Dictionary(catalog.lessons.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var xp = 0
        var timingPoints = 0.0
        var peakCleanBpm = 0
        var fastMasteredCount = 0
        var techniquePoints = 0.0
        var practicedTechniques: Set<LessonTechnique> = []
        var memoryPoints = 0.0
        var totalStars = 0

        for (lessonId, record) in progress {
            let lesson = lessonsById[lessonId]
            let level = max(1, min(5, lesson?.level ?? 1))

            let hasPass = record.passed || record.mastery
            let hasMastery = record.mastery
            let hasMemory = record.memory

            if hasPass { totalStars += 1 }
            if hasMastery { totalStars += 1 }
            if hasMemory { totalStars += 1 }

            // XP from stars and high accuracy
            if hasPass {
                xp += 50 + (level - 1) * 15
            }
            if hasMastery {
                xp += 70 + (level - 1) * 20
            }
            if hasMemory {
                xp += 90 + (level - 1) * 25
            }
            if hasPass && record.bestScore >= 0.90 {
                let extraPercent = Int(((Double(record.bestScore) - 0.90) * 100.0).rounded())
                xp += max(0, min(20, extraPercent * 2))
            }

            // TIMING points: non-decreasing accuracy contribution
            let clampedScore = min(1.0, max(0.0, Double(record.bestScore)))
            if hasPass || clampedScore >= 0.60 {
                if clampedScore >= LearningRules.passMark {
                    timingPoints += 0.40 + (clampedScore - LearningRules.passMark) * 3.0
                } else {
                    timingPoints += clampedScore * 0.30
                }
            }

            // SPEED: highest cleanly played BPM + fast mastery breadth
            let cleanPass = hasPass || clampedScore >= LearningRules.passMark
            if cleanPass && record.currentBpm > 0 {
                if record.currentBpm > peakCleanBpm {
                    peakCleanBpm = record.currentBpm
                }
                if (hasMastery && record.currentBpm >= 110) || (hasPass && record.currentBpm >= 120) {
                    fastMasteredCount += 1
                }
            }

            // TECHNIQUE: mastery across techniques & levels
            if hasPass || hasMastery {
                let levelWeight = 1.0 + 0.1 * Double(level - 1)
                var lessonTech = 0.0
                if hasPass { lessonTech += 0.35 }
                if hasMastery { lessonTech += 0.65 }
                techniquePoints += lessonTech * levelWeight
                if let lesson {
                    practicedTechniques.insert(LessonTechnique.classify(lesson))
                }
            }

            // MEMORY: 3★ memory runs & settled mastery
            if hasMemory {
                memoryPoints += 1.2
            }
            if record.settled == true {
                memoryPoints += 0.8
            }
        }

        // Training contributions
        xp += trainingLog.reviewsPassed * 25
        xp += trainingLog.bounceBacks * 15
        xp += trainingLog.mixRounds * 30
        xp += trainingLog.mixMemoryRounds * 20
        xp += trainingLog.afterMeLessons.count * 25
        xp += trainingLog.practiceDays.count * 10

        // Exam & milestone XP
        xp += state.completedExamStageIDs.count * 150
        xp += state.earnedMilestoneIDs.count * 100

        timingPoints += Double(trainingLog.afterMeLessons.count) * 0.25
        techniquePoints += Double(practicedTechniques.count) * 2.0
        techniquePoints += Double(state.completedExamStageIDs.count) * 3.0
        memoryPoints += Double(trainingLog.reviewsPassed) * 0.50
        memoryPoints += Double(trainingLog.mixMemoryRounds) * 0.80
        memoryPoints += Double(trainingLog.afterMeLessons.count) * 0.40

        let timingScore = saturateAttribute(timingPoints, scale: 28.0)
        let speedScore: Int = {
            guard peakCleanBpm > 0 else { return 0 }
            let peakNormalized = min(1.0, max(0.0, Double(peakCleanBpm - 40) / 140.0))
            let peakComponent = peakNormalized * 85.0
            let breadthComponent = 15.0 * (1.0 - exp(-Double(fastMasteredCount) / 15.0))
            return min(100, max(1, Int((peakComponent + breadthComponent).rounded())))
        }()
        let techniqueScore = saturateAttribute(techniquePoints, scale: 45.0)
        let memoryScore = saturateAttribute(memoryPoints, scale: 25.0)

        let breakdown = levelBreakdown(forXP: xp)
        let rank = DrummerRank.forLevel(breakdown.level)

        return DrummerCardSnapshot(
            xp: xp,
            level: breakdown.level,
            rank: rank,
            currentLevelXP: breakdown.currentLevelXP,
            nextLevelXP: breakdown.nextLevelXP,
            attributes: DrummerAttributes(
                timing: timingScore,
                speed: speedScore,
                technique: techniqueScore,
                memory: memoryScore
            ),
            peakCleanBpm: peakCleanBpm,
            totalStars: totalStars
        )
    }

    private static func saturateAttribute(_ points: Double, scale: Double) -> Int {
        guard points > 0 else { return 0 }
        let raw = 100.0 * (1.0 - exp(-points / scale))
        return min(100, max(1, Int(raw.rounded())))
    }

    // MARK: - Stage Exams, Milestones & Rewards

    private static func passedExamLesson(_ lesson: Lesson?, progress: [Int: LessonProgress]) -> Bool {
        guard let lesson, let record = progress[lesson.id] else { return false }
        return record.passed || record.mastery
    }

    /// Returns all milestone IDs currently satisfied by `progress`, `trainingLog`, and defeated stage bosses.
    static func satisfiedMilestoneIDs(
        progress: [Int: LessonProgress],
        trainingLog: TrainingLog,
        catalog: LibraryCatalog,
        completedExamStageIDs: Set<String> = []
    ) -> Set<String> {
        let introIDs = Set(catalog.introLessons.map(\.id))
        let passedIntroCount = introIDs.filter {
            let r = progress[$0]
            return r?.passed == true || r?.mastery == true
        }.count
        let introBossPassed = catalog.introLessons.last.map {
            let r = progress[$0.id]
            return r?.passed == true || r?.mastery == true
        } ?? false

        let passedCount = progress.values.filter { $0.passed || $0.mastery }.count
        let masteredCount = progress.values.filter { $0.mastery }.count
        let memoryCount = progress.values.filter { $0.memory }.count
        let stageBossCount = completedExamStageIDs.filter { $0 != introExamStageId }.count

        var earned: Set<String> = []
        if passedIntroCount >= 5 { earned.insert("intro-spark") }
        if (!introIDs.isEmpty && passedIntroCount >= introIDs.count) || introBossPassed {
            earned.insert("intro-graduate")
        }
        if masteredCount >= 1 { earned.insert("first-mastery") }
        if passedCount >= 10 { earned.insert("ten-passed") }
        if masteredCount >= 10 { earned.insert("ten-mastered") }
        if memoryCount >= 5 { earned.insert("memory-specialist") }
        if trainingLog.reviewsPassed >= 5 { earned.insert("review-habit") }
        if masteredCount >= 25 { earned.insert("twenty-five-mastered") }
        if stageBossCount >= 10 { earned.insert(tenBossesMilestoneId) }
        return earned
    }

    /// Evaluates updated play progress, awarding newly earned stage exam keys, milestone keys, skins, bonus tracks, and computing the post-lesson delta.
    static func evaluateProgressUpdate(
        previousState: DrummerPathState,
        previousProgress: [Int: LessonProgress],
        previousTrainingLog: TrainingLog,
        currentProgress: [Int: LessonProgress],
        currentTrainingLog: TrainingLog,
        catalog: LibraryCatalog,
        completedBossStageID: String? = nil,
        now: Date = AppCalendar.now()
    ) -> DrummerPathEvaluationOutcome {
        let beforeCard = computeCard(
            progress: previousProgress,
            catalog: catalog,
            trainingLog: previousTrainingLog,
            state: previousState
        )

        var nextState = previousState
        var satisfiedExams: Set<String> = []
        if passedExamLesson(catalog.introLessons.last, progress: currentProgress) {
            satisfiedExams.insert(introExamStageId)
        }
        if let completedBossStageID, catalog.stages.contains(where: { $0.id == completedBossStageID }) {
            satisfiedExams.insert(completedBossStageID)
        }
        let newExams = satisfiedExams.subtracting(nextState.completedExamStageIDs).sorted()
        nextState.completedExamStageIDs.formUnion(newExams)

        let satisfiedMilestones = satisfiedMilestoneIDs(
            progress: currentProgress,
            trainingLog: currentTrainingLog,
            catalog: catalog,
            completedExamStageIDs: nextState.completedExamStageIDs
        )
        let newMilestones = satisfiedMilestones.subtracting(nextState.earnedMilestoneIDs).sorted()
        nextState.earnedMilestoneIDs.formUnion(newMilestones)

        // Compute card after exam/milestone updates so rank-gated rewards also evaluate accurately.
        let afterCard = computeCard(
            progress: currentProgress,
            catalog: catalog,
            trainingLog: currentTrainingLog,
            state: nextState
        )

        var newSkins: [String] = []
        for skin in StudioRigCatalog.skins where !nextState.isSkinUnlocked(skin.id) {
            if skin.unlockRequirement.isSatisfied(by: nextState, card: afterCard) {
                nextState.unlockedSkinIds.insert(skin.id)
                newSkins.append(skin.id)
            }
        }

        var newTracks: [String] = []
        for track in StudioRigCatalog.bonusTracks where !nextState.isBonusTrackUnlocked(track.id) {
            if track.unlockRequirement.isSatisfied(by: nextState, card: afterCard) {
                nextState.unlockedBonusTrackIds.insert(track.id)
                newTracks.append(track.id)
            }
        }

        if !newExams.isEmpty || !newMilestones.isEmpty || !newSkins.isEmpty || !newTracks.isEmpty {
            nextState.modifiedAt = now
        }

        let newKeySources = newExams.filter { keyAwardingExamStageIDs.contains($0) }
            + newMilestones.filter { keyAwardingMilestoneIDs.contains($0) }
        let keysAwarded = max(0, nextState.totalKeysEarned - previousState.totalKeysEarned)
        let delta = DrummerProgressDelta.between(previous: beforeCard, current: afterCard)

        return DrummerPathEvaluationOutcome(
            updatedState: nextState,
            newlyCompletedExamStageIDs: newExams,
            newlyEarnedMilestoneIDs: newMilestones,
            newlyAwardedKeySourceIDs: newKeySources,
            newlyUnlockedSkinIDs: newSkins,
            newlyUnlockedBonusTrackIDs: newTracks,
            keysAwarded: keysAwarded,
            card: afterCard,
            delta: delta
        )
    }

    // MARK: - Spending Keys on Drum Kits

    /// Spends 1 key to unlock any locked drum kit in `DrumKitCatalog`.
    public static func unlockKit(
        _ kitId: String,
        in state: inout DrummerPathState,
        now: Date = AppCalendar.now()
    ) -> KitUnlockResult {
        guard let kit = DrumKitCatalog.kit(forId: kitId) else {
            return .unknownKit(kitId: kitId)
        }
        if state.isKitUnlocked(kitId) {
            return .alreadyUnlocked(kit: kit)
        }
        let cost = max(1, kit.unlockCost)
        let available = state.availableKeys
        guard available >= cost else {
            return .insufficientKeys(kit: kit, needed: cost, available: available)
        }
        state.unlockedKitIds.insert(kitId)
        state.keysSpent += cost
        state.modifiedAt = now
        return .unlocked(kit: kit, remainingKeys: state.availableKeys)
    }

    // MARK: - Safe Migration for Existing Players

    /// Automatically migrates an existing player's saved stars, completed stages, and training log
    /// into initial XP, attributes, completed exams, earned keys, unlocked kits, skins, and bonus tracks.
    /// Safe and idempotent: once `migratedFromLegacyProgress` is true, it does not overwrite user-spent keys.
    static func migrateLegacyProgress(
        existingState: DrummerPathState,
        progress: [Int: LessonProgress],
        trainingLog: TrainingLog,
        catalog: LibraryCatalog,
        now: Date = AppCalendar.now()
    ) -> DrummerPathState {
        guard !existingState.migratedFromLegacyProgress else { return existingState }

        var state = existingState
        let hasExistingPlay = progress.values.contains { $0.passed || $0.mastery || $0.memory }
            || trainingLog.reviewsPassed > 0
            || trainingLog.mixRounds > 0
            || !trainingLog.afterMeLessons.isEmpty

        guard hasExistingPlay else {
            state.migratedFromLegacyProgress = true
            return state
        }

        // 1. Credit completed stage exams & earned milestones
        if passedExamLesson(catalog.introLessons.last, progress: progress) {
            state.completedExamStageIDs.insert(introExamStageId)
        }
        state.completedExamStageIDs.formUnion(catalog.stages.compactMap { stage in
            passedExamLesson(stage.lessons.last, progress: progress) ? stage.id : nil
        })
        state.earnedMilestoneIDs.formUnion(
            satisfiedMilestoneIDs(
                progress: progress,
                trainingLog: trainingLog,
                catalog: catalog,
                completedExamStageIDs: state.completedExamStageIDs
            )
        )

        // 2. Preserve access to every kit where the player already earned stars
        let lessonsById = Dictionary(catalog.lessons.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for (lessonId, record) in progress where record.passed || record.mastery || record.memory {
            if let lesson = lessonsById[lessonId] {
                let kitId = DrumKitCatalog.requiredKitId(for: lesson)
                state.unlockedKitIds.insert(kitId)
            }
        }

        // 3. Account for keys spent on migrated non-starter kits without ever making keys negative
        let nonStarterUnlockedCount = state.unlockedKitIds.subtracting([DrumKitCatalog.starterKitId]).count
        state.keysSpent = max(state.keysSpent, min(state.totalKeysEarned, nonStarterUnlockedCount))

        // 4. Unlock skins and bonus jam tracks already earned
        let card = computeCard(progress: progress, catalog: catalog, trainingLog: trainingLog, state: state)
        for skin in StudioRigCatalog.skins where skin.unlockRequirement.isSatisfied(by: state, card: card) {
            state.unlockedSkinIds.insert(skin.id)
        }
        for track in StudioRigCatalog.bonusTracks where track.unlockRequirement.isSatisfied(by: state, card: card) {
            state.unlockedBonusTrackIds.insert(track.id)
        }

        // 5. Infer provisional story fork routes from best-starred alternatives
        migrateStoryForkChoices(state: &state, progress: progress, catalog: catalog)

        state.migratedFromLegacyProgress = true
        state.modifiedAt = now
        return state
    }

    /// Populates unset story fork routes from existing lesson progress:
    /// picks the alternative with the most stars (ties broken by lesson order in the fork).
    static func migrateStoryForkChoices(
        state: inout DrummerPathState,
        progress: [Int: LessonProgress],
        catalog: LibraryCatalog,
        storyMap: StoryMap = .bundled
    ) {
        for stage in catalog.stages {
            let nodes = storyMap.nodes(for: stage.id)
            for (nodeIndex, node) in nodes.enumerated() {
                guard case .fork(let ids) = node, !ids.isEmpty else { continue }
                let key = StoryMap.forkChoiceKey(stageId: stage.id, nodeIndex: nodeIndex)
                guard state.storyForkChoices[key] == nil else { continue }
                var bestId: Int?
                var bestStars = 0
                for id in ids {
                    let stars = LibraryStarFilter.stars(progress[id])
                    if stars > bestStars {
                        bestStars = stars
                        bestId = id
                    }
                }
                if let bestId, bestStars > 0 {
                    state.storyForkChoices[key] = bestId
                }
            }
        }
    }

    // MARK: - Backup Merge

    /// "Never lose anything" merge for backup imports.
    public static func merge(_ local: DrummerPathState, with incoming: DrummerPathState) -> DrummerPathState {
        let mergedKits = local.unlockedKitIds.union(incoming.unlockedKitIds)
        let mergedSkins = local.unlockedSkinIds.union(incoming.unlockedSkinIds)
        let mergedTracks = local.unlockedBonusTrackIds.union(incoming.unlockedBonusTrackIds)
        let mergedExams = local.completedExamStageIDs.union(incoming.completedExamStageIDs)
        let mergedMilestones = local.earnedMilestoneIDs.union(incoming.earnedMilestoneIDs)
        let mergedSeenStoryCards = local.seenStoryCardStageIDs.union(incoming.seenStoryCardStageIDs)

        let preferIncomingChoices: Bool = {
            switch (local.modifiedAt, incoming.modifiedAt) {
            case let (d1?, d2?): return d2 > d1
            case (nil, _?): return true
            default: return false
            }
        }()
        var mergedForkChoices = local.storyForkChoices
        for (key, value) in incoming.storyForkChoices {
            if mergedForkChoices[key] == nil || preferIncomingChoices {
                mergedForkChoices[key] = value
            }
        }

        let mergedLegacyBonus = max(local.legacyKeysBonus, incoming.legacyKeysBonus)
        let totalEarned = mergedLegacyBonus + earnedKeyCount(exams: mergedExams, milestones: mergedMilestones)
        let localNonStarter = local.unlockedKitIds.subtracting([DrumKitCatalog.starterKitId])
        let incomingNonStarter = incoming.unlockedKitIds.subtracting([DrumKitCatalog.starterKitId])
        let candidateSpent = max(local.keysSpent, incoming.keysSpent)
        let reconciledSpent: Int
        if localNonStarter.isSubset(of: incomingNonStarter) || incomingNonStarter.isSubset(of: localNonStarter) {
            reconciledSpent = min(totalEarned, candidateSpent)
        } else {
            let mergedNonStarterCount = mergedKits.subtracting([DrumKitCatalog.starterKitId]).count
            reconciledSpent = min(totalEarned, max(candidateSpent, min(totalEarned, mergedNonStarterCount)))
        }

        let modifiedAt: Date? = {
            switch (local.modifiedAt, incoming.modifiedAt) {
            case let (d1?, d2?): return max(d1, d2)
            case (let d1?, nil): return d1
            case (nil, let d2?): return d2
            case (nil, nil): return nil
            }
        }()

        return DrummerPathState(
            unlockedKitIds: mergedKits,
            unlockedSkinIds: mergedSkins,
            unlockedBonusTrackIds: mergedTracks,
            completedExamStageIDs: mergedExams,
            earnedMilestoneIDs: mergedMilestones,
            keysSpent: reconciledSpent,
            legacyKeysBonus: mergedLegacyBonus,
            migratedFromLegacyProgress: local.migratedFromLegacyProgress || incoming.migratedFromLegacyProgress,
            storyForkChoices: mergedForkChoices,
            seenStoryCardStageIDs: mergedSeenStoryCards,
            modifiedAt: modifiedAt
        )
    }
}
