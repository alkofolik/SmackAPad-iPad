import XCTest
@testable import SmackAPad

final class DrummerPathTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("DrummerPathTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        BadgeStore.shared.resetAll()
        SettingsManager.shared.resetToDefaults()
    }

    override func tearDown() {
        BadgeStore.shared.resetAll()
        SettingsManager.shared.resetToDefaults()
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    private func makeLesson(
        id: Int,
        cat: String = "eighth",
        genre: String = "Rock",
        tags: [String] = [],
        level: Int = 1,
        startBpm: Int = 70,
        targetBpm: Int = 100
    ) -> Lesson {
        Lesson(
            id: id,
            cat: cat,
            title: "Lesson \(id)",
            genre: genre,
            tags: tags,
            text: "",
            division: tags.contains("triplet feel") ? 12 : 16,
            bars: 1,
            startBpm: startBpm,
            targetBpm: targetBpm,
            level: level,
            src: "Test",
            hits: [
                LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100),
                LessonHit(step: 4, padIndex: 13, hand: "R", velocity: 100)
            ]
        )
    }

    private func makeIntroLesson(id: Int, number: Int, genre: String = "Rock") -> Lesson {
        Lesson(
            id: id,
            cat: "intro",
            title: "Intro \(number)",
            genre: genre,
            tags: [],
            text: "",
            division: 16,
            bars: 1,
            startBpm: 60,
            targetBpm: 90,
            level: 1,
            src: "Test",
            hits: [LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)],
            intro: IntroMetadata(number: number, stage: "Basics", goal: "Goal", watch: "Watch")
        )
    }

    // MARK: - 1. Drummer Card: XP, Rank, 4 Attributes & Deltas

    func testEmptyProgressStartsAtZeroAndPadRookie() {
        let catalog = LibraryCatalog(lessons: [makeLesson(id: 1)])
        let card = DrummerPathEvaluator.computeCard(
            progress: [:],
            catalog: catalog,
            trainingLog: TrainingLog(),
            state: DrummerPathState()
        )

        XCTAssertEqual(card.xp, 0)
        XCTAssertEqual(card.level, 1)
        XCTAssertEqual(card.rank, .padRookie)
        XCTAssertEqual(card.attributes, .zero)
        XCTAssertEqual(card.peakCleanBpm, 0)
        XCTAssertEqual(card.totalStars, 0)
    }

    func testAttributesComputeFromRealPlayAndProducePostLessonDeltas() {
        let l1 = makeLesson(id: 1, genre: "Funk", tags: [], level: 1, targetBpm: 90)
        let l2 = makeLesson(id: 2, genre: "Rock", tags: ["16ths"], level: 2, targetBpm: 140)
        let l3 = makeLesson(id: 3, genre: "Jazz", tags: ["triplet feel"], level: 3, targetBpm: 150)
        let catalog = LibraryCatalog(lessons: [l1, l2, l3])

        let beforeProgress: [Int: LessonProgress] = [
            1: LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.84)
        ]
        let afterProgress: [Int: LessonProgress] = [
            1: LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.84),
            2: LessonProgress(passed: true, mastery: true, memory: true, currentBpm: 140, bestScore: 0.96),
            3: LessonProgress(passed: true, mastery: true, memory: false, currentBpm: 150, bestScore: 0.94)
        ]
        let afterLog = TrainingLog(reviewsPassed: 2, mixMemoryRounds: 1, practiceDays: ["2026-11-25"])

        let outcome = DrummerPathEvaluator.evaluateProgressUpdate(
            previousState: DrummerPathState(),
            previousProgress: beforeProgress,
            previousTrainingLog: TrainingLog(),
            currentProgress: afterProgress,
            currentTrainingLog: afterLog,
            catalog: catalog
        )

        XCTAssertGreaterThan(outcome.delta.xpGained, 0)
        XCTAssertGreaterThan(outcome.delta.timingDelta, 0)
        XCTAssertGreaterThan(outcome.delta.speedDelta, 0)
        XCTAssertGreaterThan(outcome.delta.techniqueDelta, 0)
        XCTAssertGreaterThan(outcome.delta.memoryDelta, 0)
        XCTAssertFalse(outcome.delta.formattedAttributeDeltas.isEmpty)
        XCTAssertTrue(outcome.delta.formattedAttributeDeltas.contains("SPEED"))
        XCTAssertTrue(outcome.delta.formattedAttributeDeltas.contains("TIMING"))
        XCTAssertEqual(outcome.card.peakCleanBpm, 150)

        // Attributes remain monotonic and bounded in 0...100 even if a harder lesson is passed at lower score/BPM
        let l4 = makeLesson(id: 4, genre: "Rock", tags: ["ghost notes"], level: 4, targetBpm: 75)
        let extendedCatalog = LibraryCatalog(lessons: [l1, l2, l3, l4])
        var nextProgress = afterProgress
        nextProgress[4] = LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 75, bestScore: 0.80)

        let secondOutcome = DrummerPathEvaluator.evaluateProgressUpdate(
            previousState: outcome.updatedState,
            previousProgress: afterProgress,
            previousTrainingLog: afterLog,
            currentProgress: nextProgress,
            currentTrainingLog: afterLog,
            catalog: extendedCatalog
        )

        XCTAssertGreaterThanOrEqual(secondOutcome.card.attributes.timing, outcome.card.attributes.timing)
        XCTAssertGreaterThanOrEqual(secondOutcome.card.attributes.speed, outcome.card.attributes.speed)
        XCTAssertGreaterThanOrEqual(secondOutcome.card.attributes.technique, outcome.card.attributes.technique)
        XCTAssertGreaterThanOrEqual(secondOutcome.card.attributes.memory, outcome.card.attributes.memory)
        XCTAssertLessThanOrEqual(secondOutcome.card.attributes.speed, 100)
    }

    func testRankProgressionCoversStarterToGrooveArchitect() {
        XCTAssertEqual(DrummerRank.forLevel(1), .padRookie)
        XCTAssertEqual(DrummerRank.forLevel(3), .beatKeeper)
        XCTAssertEqual(DrummerRank.forLevel(6), .pocketPlayer)
        XCTAssertEqual(DrummerRank.forLevel(15), .grooveArchitect)
        XCTAssertTrue(DrummerRank.padRookie < .beatKeeper)
        XCTAssertTrue(DrummerRank.beatKeeper < .pocketPlayer)
        XCTAssertTrue(DrummerRank.pocketPlayer < .grooveArchitect)
    }

    // MARK: - 2. Keys from Stage Exams & Milestones, and Unlocking 8 Kits

    func testAllEightBundledKitsAreMappedWithStarterUnlocked() throws {
        let bundled = try DataLoader.shared.loadSampleKits()
        XCTAssertEqual(DrumKitCatalog.allKits.count, 8)
        XCTAssertEqual(Set(DrumKitCatalog.allKits.map(\.kitId)), Set(bundled.keys))

        let initial = DrummerPathState()
        XCTAssertTrue(initial.isKitUnlocked("acoustic"))
        for kit in DrumKitCatalog.allKits where kit.kitId != "acoustic" {
            XCTAssertFalse(initial.isKitUnlocked(kit.kitId), "\(kit.kitId) should start locked")
            XCTAssertEqual(kit.unlockCost, 1)
        }
        XCTAssertEqual(initial.availableKeys, 0)
    }

    func testEveryBundledLessonMapsToOneOfEightKits() {
        let lessons = LessonStore.shared.lessons
        XCTAssertFalse(lessons.isEmpty)
        let validIds = Set(DrumKitCatalog.allKits.map(\.kitId))
        for lesson in lessons {
            let kitId = DrumKitCatalog.requiredKitId(for: lesson)
            XCTAssertTrue(validIds.contains(kitId), "Lesson \(lesson.id) (\(lesson.genre)) mapped to invalid kit \(kitId)")
            if lesson.cat == "intro" || (lesson.id == 6 && lesson.cat == "starter") {
                XCTAssertEqual(kitId, DrumKitCatalog.starterKitId)
            }
        }
    }

    func testStageExamAndMilestonesAwardKeysAndAllowUnlockingAnyKit() {
        let introLessons = (1...5).map { makeIntroLesson(id: 10000 + $0, number: $0) }
        let stage1A = makeLesson(id: 101, cat: "eighth", genre: "Funk", level: 1)
        let stage1Boss = makeLesson(id: 102, cat: "eighth", genre: "Funk", level: 1)
        let catalog = LibraryCatalog(lessons: introLessons + [stage1A, stage1Boss])

        // Pass 5 intro lessons -> earns "intro-spark" milestone (1 key) + Intro exam (boss 10005 -> 1 key)
        // Win the Groove boss to earn the L1-groove stage exam (1 key).
        var progress: [Int: LessonProgress] = [:]
        for l in introLessons {
            progress[l.id] = LessonProgress(passed: true, currentBpm: 90, bestScore: 0.90)
        }
        progress[stage1Boss.id] = LessonProgress(passed: true, currentBpm: 100, bestScore: 0.91)

        let outcome = DrummerPathEvaluator.evaluateProgressUpdate(
            previousState: DrummerPathState(),
            previousProgress: [:],
            previousTrainingLog: TrainingLog(),
            currentProgress: progress,
            currentTrainingLog: TrainingLog(),
            catalog: catalog,
            completedBossStageID: "L1-groove"
        )

        var state = outcome.updatedState
        XCTAssertTrue(state.earnedMilestoneIDs.contains("intro-spark"))
        XCTAssertTrue(state.earnedMilestoneIDs.contains("intro-graduate"))
        XCTAssertTrue(state.completedExamStageIDs.contains("intro"))
        XCTAssertTrue(state.completedExamStageIDs.contains("L1-groove"))
        XCTAssertEqual(outcome.keysAwarded, 4)
        XCTAssertEqual(state.availableKeys, 4)

        // Player can spend 1 key to unlock ANY locked kit (e.g. jazz first, then 808)
        let jazzUnlock = DrummerPathEvaluator.unlockKit("jazz", in: &state)
        XCTAssertEqual(jazzUnlock, .unlocked(kit: DrumKitCatalog.kit(forId: "jazz")!, remainingKeys: 3))
        XCTAssertTrue(state.isKitUnlocked("jazz"))
        XCTAssertFalse(state.isKitUnlocked("rock"))

        // Re-unlocking an already unlocked kit does not spend another key
        let repeatUnlock = DrummerPathEvaluator.unlockKit("jazz", in: &state)
        XCTAssertEqual(repeatUnlock, .alreadyUnlocked(kit: DrumKitCatalog.kit(forId: "jazz")!))
        XCTAssertEqual(state.availableKeys, 3)

        // Insufficient keys check
        var emptyState = DrummerPathState()
        let failedUnlock = DrummerPathEvaluator.unlockKit("rock", in: &emptyState)
        XCTAssertEqual(
            failedUnlock,
            .insufficientKeys(kit: DrumKitCatalog.kit(forId: "rock")!, needed: 1, available: 0)
        )
        XCTAssertFalse(emptyState.isKitUnlocked("rock"))
    }

    func testKitToLessonAccessStatusReportsClearRequirementUntilUnlocked() {
        let introRock = makeIntroLesson(id: 10001, number: 1, genre: "Rock")
        let rockLesson = makeLesson(id: 200, cat: "eighth", genre: "Rock", level: 1)
        let jazzLesson = makeLesson(id: 201, cat: "swing", genre: "Jazz", tags: ["triplet feel"], level: 2)

        var state = DrummerPathState(
            earnedMilestoneIDs: ["intro-spark"] // 1 key available
        )

        // Intro stays unlocked on Starter even with Rock genre
        XCTAssertTrue(DrumKitCatalog.accessStatus(for: introRock, state: state).isUnlocked)

        // Non-intro Rock & Jazz lessons report clear locked kit status
        let rockStatusEn = DrumKitCatalog.accessStatus(for: rockLesson, state: state, language: .english)
        XCTAssertFalse(rockStatusEn.isUnlocked)
        XCTAssertTrue(rockStatusEn.canUnlockNow)
        XCTAssertEqual(rockStatusEn.statusMessage, "Requires Rock kit (unlock for 1 key)")

        let jazzStatusCs = DrumKitCatalog.accessStatus(for: jazzLesson, state: state, language: .czech)
        XCTAssertFalse(jazzStatusCs.isUnlocked)
        XCTAssertEqual(jazzStatusCs.statusMessage, "Vyžaduje sadu Jazz (odemkni za 1 klíč)")

        // Unlock Rock with 1 key -> Rock lesson becomes unlocked, Jazz stays locked (0 keys left)
        _ = DrummerPathEvaluator.unlockKit("rock", in: &state)
        XCTAssertTrue(DrumKitCatalog.accessStatus(for: rockLesson, state: state).isUnlocked)

        let jazzAfterSpend = DrumKitCatalog.accessStatus(for: jazzLesson, state: state, language: .english)
        XCTAssertFalse(jazzAfterSpend.isUnlocked)
        XCTAssertFalse(jazzAfterSpend.canUnlockNow)
    }

    // MARK: - 3. Instrument Skins & Bonus Jam Tracks

    func testSkinsAndBonusJamTracksUnlockOnMilestonesAndStageExams() {
        XCTAssertEqual(StudioRigCatalog.skins.count, 4)
        XCTAssertEqual(StudioRigCatalog.skins.first(where: \.isDefault)?.id, "smack-orange")
        XCTAssertFalse(StudioRigCatalog.bonusTracks.isEmpty)

        let introLessons = (1...24).map { makeIntroLesson(id: 10000 + $0, number: $0) }
        let l1Boss = makeLesson(id: 500, cat: "eighth", genre: "Funk", level: 1)
        let catalog = LibraryCatalog(lessons: introLessons + [l1Boss])

        var progress: [Int: LessonProgress] = [:]
        for l in introLessons {
            progress[l.id] = LessonProgress(passed: true, mastery: true, currentBpm: 95, bestScore: 0.93)
        }
        progress[l1Boss.id] = LessonProgress(passed: true, mastery: true, currentBpm: 105, bestScore: 0.94)

        let outcome = DrummerPathEvaluator.evaluateProgressUpdate(
            previousState: DrummerPathState(),
            previousProgress: [:],
            previousTrainingLog: TrainingLog(),
            currentProgress: progress,
            currentTrainingLog: TrainingLog(),
            catalog: catalog,
            completedBossStageID: "L1-groove"
        )

        // Default skin + ten-passed ("midnight-mpc") + ten-mastered ("cream-vintage") unlocked
        XCTAssertTrue(outcome.updatedState.isSkinUnlocked("smack-orange"))
        XCTAssertTrue(outcome.updatedState.isSkinUnlocked("midnight-mpc"))
        XCTAssertTrue(outcome.updatedState.isSkinUnlocked("cream-vintage"))
        XCTAssertFalse(outcome.updatedState.isSkinUnlocked("acid-rack"))

        // Bonus tracks for intro-graduate and Level 1 stage exam unlocked
        XCTAssertTrue(outcome.updatedState.isBonusTrackUnlocked("jam-pocket-starter"))
        XCTAssertTrue(outcome.updatedState.isBonusTrackUnlocked("jam-rock-basement"))
        XCTAssertFalse(outcome.updatedState.isBonusTrackUnlocked("jam-jazz-lounge"))

        // Bonus track converts to playable Lesson
        let bonusLesson = StudioRigCatalog.bonusTrack(forId: "jam-pocket-starter")?.asLesson()
        XCTAssertEqual(bonusLesson?.cat, "bonus")
        XCTAssertEqual(bonusLesson?.targetBpm, 96)
    }

    // MARK: - 4. Legacy Player Migration & Persistence / Backup Round-Trip

    func testLegacyProgressMigrationPreservesStarsKitsAndCalculatesInitialRPGState() throws {
        let realCatalog = LessonStore.shared.libraryCatalog
        let rockLesson = try XCTUnwrap(realCatalog.lessons.first { $0.cat != "intro" && $0.genre == "Rock" })
        let jazzLesson = try XCTUnwrap(realCatalog.lessons.first { $0.cat != "intro" && $0.genre == "Jazz" })
        let stage1 = try XCTUnwrap(realCatalog.stages.first)
        let stage1Boss = try XCTUnwrap(stage1.lessons.last)

        // Write a legacy progress.json without `drummerPath`
        let legacyLessons: [Int: LessonProgress] = [
            10001: LessonProgress(passed: true, mastery: true, currentBpm: 90, bestScore: 0.95),
            10002: LessonProgress(passed: true, mastery: true, currentBpm: 95, bestScore: 0.92),
            10003: LessonProgress(passed: true, mastery: false, currentBpm: 80, bestScore: 0.88),
            10004: LessonProgress(passed: true, mastery: false, currentBpm: 85, bestScore: 0.85),
            10005: LessonProgress(passed: true, mastery: false, currentBpm: 85, bestScore: 0.87),
            10024: LessonProgress(passed: true, mastery: true, currentBpm: 100, bestScore: 0.93),
            rockLesson.id: LessonProgress(passed: true, mastery: true, currentBpm: 120, bestScore: 0.94),
            jazzLesson.id: LessonProgress(passed: true, mastery: false, currentBpm: 110, bestScore: 0.89),
            stage1Boss.id: LessonProgress(passed: true, mastery: true, currentBpm: 115, bestScore: 0.91)
        ]

        let progressURL = tempDir.appendingPathComponent("progress.json")
        let legacyRoot = ProgressRoot(formatVersion: 1, lessons: legacyLessons, trainingLog: TrainingLog(reviewsPassed: 5))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(legacyRoot).write(to: progressURL)

        // Loading ProgressStore runs automatic one-time migration
        let store = ProgressStore(fileURL: progressURL, autoLoad: true)
        XCTAssertTrue(store.drummerPath.migratedFromLegacyProgress)
        XCTAssertTrue(store.drummerPath.isKitUnlocked("acoustic"))
        XCTAssertTrue(store.drummerPath.isKitUnlocked("rock"), "Already played Rock stars must keep Rock kit unlocked")
        XCTAssertTrue(store.drummerPath.isKitUnlocked("jazz"), "Already played Jazz stars must keep Jazz kit unlocked")
        XCTAssertTrue(store.drummerPath.completedExamStageIDs.contains("intro"))
        XCTAssertTrue(store.drummerPath.completedExamStageIDs.contains(stage1.id))
        XCTAssertTrue(store.drummerPath.earnedMilestoneIDs.contains("intro-spark"))
        XCTAssertTrue(store.drummerPath.earnedMilestoneIDs.contains("review-habit"))
        XCTAssertGreaterThanOrEqual(store.drummerPath.availableKeys, 0)

        let card = store.drummerCard(catalog: realCatalog)
        XCTAssertGreaterThan(card.xp, 0)
        XCTAssertGreaterThan(card.attributes.timing, 0)
        XCTAssertGreaterThan(card.attributes.speed, 0)
        XCTAssertGreaterThan(card.attributes.technique, 0)
        XCTAssertGreaterThan(card.attributes.memory, 0)

        // Re-loading from disk does not overwrite or double-migrate
        let snapshotBeforeReload = store.drummerPath
        let reloadedStore = ProgressStore(fileURL: progressURL, autoLoad: true)
        XCTAssertEqual(reloadedStore.drummerPath, snapshotBeforeReload)
    }

    func testBackupExportImportRoundTripsAndMergesRPGState() throws {
        let progressURL = tempDir.appendingPathComponent("progress.json")
        let store = ProgressStore(fileURL: progressURL, autoLoad: false)

        // Simulate earning keys & unlocking 808 kit + skin selection
        store.recordResult(lessonId: 10001, passed: true, mastery: true, bpm: 100, score: 0.95, autoSave: false)
        store.recordResult(lessonId: 10002, passed: true, mastery: false, bpm: 95, score: 0.90, autoSave: false)
        store.recordResult(lessonId: 10003, passed: true, mastery: false, bpm: 95, score: 0.90, autoSave: false)
        store.recordResult(lessonId: 10004, passed: true, mastery: false, bpm: 95, score: 0.90, autoSave: false)
        store.recordResult(lessonId: 10005, passed: true, mastery: false, bpm: 95, score: 0.90, autoSave: false)
        XCTAssertGreaterThanOrEqual(store.drummerPath.availableKeys, 2)

        let unlock808 = store.unlockKit("808", autoSave: true)
        if case .unlocked(let kit, _) = unlock808 {
            XCTAssertEqual(kit.kitId, "808")
        } else {
            XCTFail("Expected 808 kit to unlock, got \(unlock808)")
        }

        SettingsManager.shared.selectedInstrumentSkinId = "midnight-mpc"

        let exportedData = try store.exportData()
        let savedPath = store.drummerPath

        // Fresh device state
        try store.resetAll(deleteFile: true)
        SettingsManager.shared.resetToDefaults()
        XCTAssertFalse(store.drummerPath.isKitUnlocked("808"))
        XCTAssertEqual(SettingsManager.shared.selectedInstrumentSkinId, StudioRigCatalog.defaultSkinId)

        let summary = try store.importFromData(exportedData)
        XCTAssertTrue(summary.isFreshDevice)
        XCTAssertEqual(store.drummerPath.unlockedKitIds, savedPath.unlockedKitIds)
        XCTAssertEqual(store.drummerPath.earnedMilestoneIDs, savedPath.earnedMilestoneIDs)
        XCTAssertEqual(store.drummerPath.keysSpent, savedPath.keysSpent)
        XCTAssertEqual(store.drummerPath.availableKeys, savedPath.availableKeys)
        XCTAssertEqual(SettingsManager.shared.selectedInstrumentSkinId, "midnight-mpc")

        // Merging two DrummerPathStates never loses unlocked kits, exams, milestones, skins, or bonus tracks
        let local = DrummerPathState(
            unlockedKitIds: ["acoustic", "rock"],
            unlockedSkinIds: ["smack-orange", "midnight-mpc"],
            unlockedBonusTrackIds: ["jam-pocket-starter"],
            completedExamStageIDs: ["intro"],
            earnedMilestoneIDs: ["intro-spark", "first-mastery"],
            keysSpent: 1
        )
        let incoming = DrummerPathState(
            unlockedKitIds: ["acoustic", "jazz"],
            unlockedSkinIds: ["smack-orange", "cream-vintage"],
            unlockedBonusTrackIds: ["jam-rock-basement"],
            completedExamStageIDs: ["L1-groove"],
            earnedMilestoneIDs: ["intro-spark", "ten-passed"],
            keysSpent: 1
        )
        let merged = ProgressMerge.mergeDrummerPath(local: local, incoming: incoming)
        XCTAssertEqual(merged.unlockedKitIds, ["acoustic", "rock", "jazz"])
        XCTAssertEqual(merged.unlockedSkinIds, ["smack-orange", "midnight-mpc", "cream-vintage"])
        XCTAssertEqual(merged.unlockedBonusTrackIds, ["jam-pocket-starter", "jam-rock-basement"])
        XCTAssertEqual(merged.completedExamStageIDs, ["intro", "L1-groove"])
        XCTAssertEqual(merged.earnedMilestoneIDs, ["intro-spark", "first-mastery", "ten-passed"])
        XCTAssertGreaterThanOrEqual(merged.availableKeys, 0)
    }

    func testDrummerPathMapTopologiesAndNodeStates() {
        XCTAssertEqual(DrummerStageTopology.allCases.count, 6)
        XCTAssertFalse(DrummerStageTopology.allCases.map(\.rawValue).contains("circuitLoop"))

        // Adjacent stages never share the same topology and stages build deterministically from stageId
        let builtStages = DrummerPathMapBuilder.buildStages(
            catalog: LessonStore.shared.libraryCatalog,
            progress: [:],
            pathState: DrummerPathState(),
            language: .english
        )
        for idx in 1..<builtStages.count {
            XCTAssertNotEqual(
                builtStages[idx].topology,
                builtStages[idx - 1].topology,
                "Adjacent stages \(builtStages[idx - 1].id) and \(builtStages[idx].id) must not share topology"
            )
        }

        // Consecutive blocks in a multi-block stage never repeat, <4-node blocks never use splitFork,
        // and final >=4-node Boss blocks prefer diagonalClimb or splitFork.
        let baseIntro = DrummerStageTopology.topology(forStageId: "intro")
        let introPageTopologies = DrummerStageTopology.topologiesForStage(
            stageId: "intro",
            pageCount: 5,
            bossPageIndex: 4,
            stageBaseTopology: baseIntro,
            nodeCounts: [6, 6, 6, 6, 7]
        )
        XCTAssertEqual(introPageTopologies.count, 5)
        for pIdx in 1..<introPageTopologies.count {
            XCTAssertNotEqual(introPageTopologies[pIdx], introPageTopologies[pIdx - 1])
        }
        XCTAssertTrue(
            introPageTopologies[4] == .diagonalClimb || introPageTopologies[4] == .splitFork,
            "Multi-block Boss page should use diagonalClimb or splitFork, got \(introPageTopologies[4])"
        )

        let shortPageTopologies = DrummerStageTopology.topologiesForStage(
            stageId: "short-stage",
            pageCount: 2,
            bossPageIndex: 1,
            stageBaseTopology: .splitFork,
            nodeCounts: [6, 3]
        )
        XCTAssertTrue(
            shortPageTopologies[1] == .signalLine || shortPageTopologies[1] == .diagonalClimb,
            "Blocks with < 4 nodes must use signalLine or diagonalClimb, got \(shortPageTopologies[1])"
        )

        let lessons = (1...5).map { idx in
            Lesson(
                id: 900 + idx,
                cat: "rock",
                title: "Rock \(idx)",
                genre: "Rock",
                tags: [],
                text: "",
                division: 8,
                bars: 2,
                startBpm: 70,
                targetBpm: 100,
                level: 1,
                score: 1,
                src: "",
                hits: [],
                hits8: nil,
                eightNote: nil,
                intro: nil,
                access: nil
            )
        }

        // Locked Rock kit never blocks path nodes (nodes activate normally regardless of kit unlock)
        let stageWithLockedKit = DrummerPathMapBuilder.buildStage(
            id: "L1-groove",
            index: 1,
            level: 1,
            title: "Rock",
            lessons: lessons,
            topology: .splitFork,
            progress: [:],
            pathState: DrummerPathState()
        )
        XCTAssertNil(stageWithLockedKit.lockedKit)
        XCTAssertEqual(stageWithLockedKit.nodes[0].state, .active)

        // Unlocked Rock kit with first 2 trunk lessons completed activates both parallel fork branches
        var progress: [Int: LessonProgress] = [:]
        progress[901] = LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.9)
        progress[902] = LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.9)

        let forkStage = DrummerPathMapBuilder.buildStage(
            id: "L1-groove",
            index: 1,
            level: 1,
            title: "Rock",
            lessons: lessons,
            topology: .splitFork,
            progress: progress,
            pathState: DrummerPathState(unlockedKitIds: ["acoustic", "rock"])
        )
        XCTAssertNil(forkStage.lockedKit)
        XCTAssertEqual(forkStage.nodes.count, 6)
        XCTAssertEqual(forkStage.nodes[0].state, .completed)
        XCTAssertEqual(forkStage.nodes[1].state, .completed)
        XCTAssertEqual(forkStage.nodes[2].state, .active)
        XCTAssertEqual(forkStage.nodes[3].state, .active)
        XCTAssertEqual(forkStage.nodes[4].state, .locked)
        XCTAssertFalse(forkStage.nodes[4].isBoss)
        XCTAssertTrue(forkStage.nodes[5].isBoss)
        XCTAssertNotEqual(forkStage.nodes[4].id, forkStage.nodes[5].id)

        // Stepped Arc preserves all 5 lessons as regular nodes and appends a dedicated Boss node
        let arcStage = DrummerPathMapBuilder.buildStage(
            id: "L2-fills",
            index: 3,
            level: 2,
            title: "Fills",
            lessons: lessons,
            topology: .steppedArc,
            progress: progress,
            pathState: DrummerPathState(unlockedKitIds: ["acoustic", "rock"])
        )
        XCTAssertEqual(arcStage.nodes.count, 6)
        XCTAssertFalse(arcStage.nodes[4].isBoss)
        XCTAssertTrue(arcStage.nodes[5].isBoss)
    }

    func testEndOfRunRpgLineFormatting() {
        let delta = DrummerProgressDelta(
            xpGained: 40,
            previousLevel: 4,
            newLevel: 4,
            previousRank: .beatKeeper,
            newRank: .beatKeeper,
            timingDelta: 1,
            speedDelta: 2,
            techniqueDelta: 0,
            memoryDelta: 0
        )
        let attrLine = EndOfRunCardModel.formattedRpgLine(delta: delta, keysAwarded: 0, language: .czech)
        XCTAssertEqual(attrLine?.text, "+2 SPEED · +1 TIMING · +40 XP")
        XCTAssertEqual(attrLine?.highlighted, false)

        let keyLineCs = EndOfRunCardModel.formattedRpgLine(delta: delta, keysAwarded: 1, language: .czech)
        XCTAssertEqual(keyLineCs?.text, "Získán +1 klíč! · +40 XP")
        XCTAssertEqual(keyLineCs?.highlighted, true)

        let keyLineEn = EndOfRunCardModel.formattedRpgLine(delta: delta, keysAwarded: 1, language: .english)
        XCTAssertEqual(keyLineEn?.text, "Earned +1 key! · +40 XP")
        XCTAssertEqual(keyLineEn?.highlighted, true)
    }

    func testPlayModeDefaultsToStoryForFreshAndMigratedSettings() {
        let suiteName = "DrummerPathTests.playMode.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Fresh settings default to .story
        let fresh = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(fresh.playMode, .story)

        // Existing/migrated settings without playMode key also default to .story
        defaults.set("free", forKey: SettingsKey.practiceMode.rawValue)
        defaults.removeObject(forKey: SettingsKey.playMode.rawValue)
        let migrated = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(migrated.playMode, .story)

        // Persisted .free survives reload
        migrated.playMode = .free
        let reloaded = SettingsManager(userDefaults: defaults)
        XCTAssertEqual(reloaded.playMode, .free)
    }

    func testStoryGatingOpensIntroAndCompletedOrActivePathNodesAndFreeModeOpensAll() throws {
        let catalog = LessonStore.shared.libraryCatalog
        let introLesson = try XCTUnwrap(catalog.introLessons.first)
        let firstStage = try XCTUnwrap(catalog.stages.first)
        let firstActiveLesson = try XCTUnwrap(firstStage.lessons.first { $0.cat != "intro" } ?? firstStage.lessons.first)
        let laterNodeInFirstStage = try XCTUnwrap(firstStage.lessons.last { $0.cat != "intro" && $0.id != firstActiveLesson.id })
        let laterStage = try XCTUnwrap(catalog.stages.dropFirst().first)
        let laterStageLesson = try XCTUnwrap(laterStage.lessons.first { $0.cat != "intro" })

        let progressURL = tempDir.appendingPathComponent("story-gating.json")
        let store = ProgressStore(fileURL: progressURL, autoLoad: false)
        let suiteName = "DrummerPathTests.gating.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let settings = SettingsManager(userDefaults: defaults)
        let progression = ProgressionManager(
            lessonStore: .shared,
            progressStore: store,
            settingsManager: settings,
            userDefaults: defaults
        )

        // Story mode (default): Intro is open; later locked nodes & stages are locked
        XCTAssertEqual(settings.playMode, .story)
        XCTAssertTrue(progression.isLessonOpen(introLesson))
        XCTAssertFalse(progression.isLessonOpen(laterNodeInFirstStage))
        XCTAssertFalse(progression.isLessonOpen(laterStageLesson))

        // Completing all preceding lessons in firstStage opens laterNodeInFirstStage
        for lesson in firstStage.lessons where lesson.id != laterNodeInFirstStage.id {
            store.recordResult(
                lessonId: lesson.id,
                passed: true,
                mastery: false,
                bpm: lesson.targetBpm,
                score: 0.9,
                autoSave: false
            )
        }
        XCTAssertTrue(progression.isLessonOpen(laterNodeInFirstStage))

        // Locked kit never blocks a lesson on the Path
        XCTAssertFalse(store.drummerPath.isKitUnlocked("jazz"))
        let jazzLesson = try XCTUnwrap(catalog.lessons.first {
            DrumKitCatalog.requiredKitId(for: $0) == "jazz"
        })
        store.recordResult(
            lessonId: jazzLesson.id,
            passed: true,
            mastery: false,
            bpm: jazzLesson.targetBpm,
            score: 0.9,
            autoSave: false
        )
        XCTAssertTrue(progression.isLessonOpen(jazzLesson))

        // Free mode: no story gating, all lessons open (purchase tier checked separately by StoreManager)
        settings.playMode = .free
        XCTAssertTrue(progression.isLessonOpen(laterStageLesson))
        XCTAssertTrue(progression.isLessonOpen(laterNodeInFirstStage))
    }

    func testStoryAvailabilityFollowsStoryMapFreshMidStageAndSideTrails() throws {
        let catalog = LessonStore.shared.libraryCatalog
        let storyMap = try StoryMap.loadBundled()
        let firstStage = try XCTUnwrap(catalog.stages.first)
        let mapNodes = storyMap.nodes(for: firstStage.id)
        let firstKeystoneId = try XCTUnwrap(mapNodes.first?.lessonIds.first)
        let firstForkIndex = try XCTUnwrap(mapNodes.firstIndex(where: \.isFork))
        let forkIds = mapNodes[firstForkIndex].lessonIds
        XCTAssertGreaterThanOrEqual(forkIds.count, 2)

        let byId = Dictionary(firstStage.lessons.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let firstKeystone = try XCTUnwrap(byId[firstKeystoneId])
        let forkLessonA = try XCTUnwrap(byId[forkIds[0]])
        let forkLessonB = try XCTUnwrap(byId[forkIds[1]])

        // Fresh: first keystone is open, fork is locked
        XCTAssertTrue(DrummerPathMapBuilder.isOpenInStory(
            lesson: firstKeystone, catalog: catalog, progress: [:], pathState: DrummerPathState(), storyMap: storyMap
        ))
        XCTAssertFalse(DrummerPathMapBuilder.isOpenInStory(
            lesson: forkLessonA, catalog: catalog, progress: [:], pathState: DrummerPathState(), storyMap: storyMap
        ))

        // Mid-stage: pass keystones up to the fork -> all fork alternatives open
        var progress: [Int: LessonProgress] = [:]
        for idx in 0..<firstForkIndex {
            for lid in mapNodes[idx].lessonIds {
                progress[lid] = LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85)
            }
        }
        for fid in forkIds {
            let fLesson = try XCTUnwrap(byId[fid])
            XCTAssertTrue(DrummerPathMapBuilder.isOpenInStory(
                lesson: fLesson, catalog: catalog, progress: progress, pathState: DrummerPathState(), storyMap: storyMap
            ))
        }

        // Choosing A and passing A opens the merge keystone after the fork, while B stays open as a side trail
        progress[forkLessonA.id] = LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85)
        var pathState = DrummerPathState()
        pathState.storyForkChoices[StoryMap.forkChoiceKey(stageId: firstStage.id, nodeIndex: firstForkIndex)] = forkLessonA.id

        let built = DrummerPathMapBuilder.buildStages(
            catalog: catalog, progress: progress, pathState: pathState, storyMap: storyMap
        ).first { $0.id == firstStage.id }
        let nodeA = built?.nodes.first { $0.lesson.id == forkLessonA.id }
        let nodeB = built?.nodes.first { $0.lesson.id == forkLessonB.id }
        XCTAssertEqual(nodeA?.isChosenRoute, true)
        XCTAssertEqual(nodeA?.isSideQuest, false)
        XCTAssertEqual(nodeB?.isChosenRoute, false)
        XCTAssertEqual(nodeB?.isSideQuest, true)
        XCTAssertEqual(nodeB?.state, .active)
        XCTAssertTrue(DrummerPathMapBuilder.isOpenInStory(
            lesson: forkLessonB, catalog: catalog, progress: progress, pathState: pathState, storyMap: storyMap
        ))

        if firstForkIndex + 1 < mapNodes.count, let mergeId = mapNodes[firstForkIndex + 1].lessonIds.first, let mergeLesson = byId[mergeId] {
            XCTAssertTrue(DrummerPathMapBuilder.isOpenInStory(
                lesson: mergeLesson, catalog: catalog, progress: progress, pathState: pathState, storyMap: storyMap
            ))
        }
    }

    func testStoryRouteChoiceResolverAllSituations() throws {
        let catalog = LessonStore.shared.libraryCatalog
        let storyMap = try StoryMap.loadBundled()
        let firstStage = try XCTUnwrap(catalog.stages.first)
        let mapNodes = storyMap.nodes(for: firstStage.id)
        let byId = Dictionary(firstStage.lessons.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        // 1. Keystone before fork (passed at ★1) -> fork options + Reach goal tempo (max 3)
        let firstForkIdx = try XCTUnwrap(mapNodes.firstIndex(where: \.isFork))
        let preForkKeystoneId = try XCTUnwrap(mapNodes[firstForkIdx - 1].lessonIds.first)
        let preForkKeystone = try XCTUnwrap(byId[preForkKeystoneId])
        let forkIds = mapNodes[firstForkIdx].lessonIds

        var progress: [Int: LessonProgress] = [
            preForkKeystone.id: LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85)
        ]
        let forkPromptActions = StoryRouteChoiceResolver.resolve(
            lesson: preForkKeystone, catalog: catalog, progress: progress, pathState: DrummerPathState(), storyMap: storyMap
        )
        XCTAssertLessThanOrEqual(forkPromptActions.count, 3)
        XCTAssertEqual(forkPromptActions.filter {
            if case .forkOption = $0.kind { return true }
            return false
        }.count, min(3, forkIds.count))
        if forkIds.count == 2 {
            XCTAssertTrue(forkPromptActions.contains { $0.kind == .reachGoalTempo })
        }

        // 2. Branch passed at ★1 -> Rejoin the trail / Other branch / Reach goal tempo
        let branchA = try XCTUnwrap(byId[forkIds[0]])
        progress[branchA.id] = LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85)
        let branchActions1 = StoryRouteChoiceResolver.resolve(
            lesson: branchA, catalog: catalog, progress: progress, pathState: DrummerPathState(), storyMap: storyMap
        )
        XCTAssertEqual(branchActions1.count, 3)
        XCTAssertTrue(branchActions1.contains { if case .rejoinTrail = $0.kind { return true }; return false })
        XCTAssertTrue(branchActions1.contains { if case .otherBranch = $0.kind { return true }; return false })
        XCTAssertTrue(branchActions1.contains { $0.kind == .reachGoalTempo })

        // Branch passed at ★2 -> no Reach goal tempo
        progress[branchA.id] = LessonProgress(passed: true, mastery: true, memory: false, currentBpm: branchA.targetBpm, bestScore: 0.95)
        let branchActions2 = StoryRouteChoiceResolver.resolve(
            lesson: branchA, catalog: catalog, progress: progress, pathState: DrummerPathState(), storyMap: storyMap
        )
        XCTAssertFalse(branchActions2.contains { $0.kind == .reachGoalTempo })

        // 3. Consecutive keystones (if present in any stage) -> Continue the trail / Reach goal tempo
        if let seqStage = catalog.stages.first(where: { stage in
            let nodes = storyMap.nodes(for: stage.id)
            return zip(nodes, nodes.dropFirst()).contains { $0.isKeystone && $1.isKeystone }
        }) {
            let nodes = storyMap.nodes(for: seqStage.id)
            let pairIdx = try XCTUnwrap(zip(nodes, nodes.dropFirst()).enumerated().first { $0.element.0.isKeystone && $0.element.1.isKeystone }?.offset)
            let kLesson = try XCTUnwrap(seqStage.lessons.first { $0.id == nodes[pairIdx].lessonIds.first })
            let seqProgress = [kLesson.id: LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85)]
            let seqActions = StoryRouteChoiceResolver.resolve(
                lesson: kLesson, catalog: catalog, progress: seqProgress, pathState: DrummerPathState(), storyMap: storyMap
            )
            XCTAssertTrue(seqActions.contains { if case .continueTrail = $0.kind { return true }; return false })
            XCTAssertTrue(seqActions.contains { $0.kind == .reachGoalTempo })
        }

        // 4. Boss available -> Face the boss offered
        let threshold = ProgressionConstant.requiredStageCompletions(lessonCount: firstStage.lessons.count)
        var bossProgress: [Int: LessonProgress] = [:]
        for l in firstStage.lessons.prefix(threshold) {
            bossProgress[l.id] = LessonProgress(passed: true, mastery: true, memory: false, currentBpm: l.targetBpm, bestScore: 0.95)
        }
        let lastKeystoneId = try XCTUnwrap(mapNodes.last?.lessonIds.first)
        let lastKeystone = try XCTUnwrap(byId[lastKeystoneId])
        bossProgress[lastKeystone.id] = LessonProgress(passed: true, mastery: true, memory: false, currentBpm: lastKeystone.targetBpm, bestScore: 0.95)
        let bossActions = StoryRouteChoiceResolver.resolve(
            lesson: lastKeystone, catalog: catalog, progress: bossProgress, pathState: DrummerPathState(), storyMap: storyMap
        )
        XCTAssertTrue(bossActions.contains { if case .faceBoss = $0.kind { return true }; return false })
    }

    func testStoryBossOpensAtExistingThresholdAndShowsMissingCount() throws {
        let catalog = LessonStore.shared.libraryCatalog
        let storyMap = try StoryMap.loadBundled()
        let firstStage = try XCTUnwrap(catalog.stages.first)
        let threshold = ProgressionConstant.requiredStageCompletions(lessonCount: firstStage.lessons.count)

        var progress: [Int: LessonProgress] = [:]
        for lesson in firstStage.lessons.prefix(threshold - 1) {
            progress[lesson.id] = LessonProgress(passed: true, mastery: true, memory: false, currentBpm: lesson.targetBpm, bestScore: 0.95)
        }
        let lockedModel = try XCTUnwrap(
            DrummerPathMapBuilder.buildStages(catalog: catalog, progress: progress, pathState: DrummerPathState(), storyMap: storyMap)
                .first { $0.id == firstStage.id }
        )
        XCTAssertEqual(lockedModel.missingMasteriesForBoss, 1)
        XCTAssertEqual(lockedModel.bossNode?.state, .locked)

        let nthLesson = firstStage.lessons[threshold - 1]
        progress[nthLesson.id] = LessonProgress(passed: true, mastery: true, memory: false, currentBpm: nthLesson.targetBpm, bestScore: 0.95)
        let openModel = try XCTUnwrap(
            DrummerPathMapBuilder.buildStages(catalog: catalog, progress: progress, pathState: DrummerPathState(), storyMap: storyMap)
                .first { $0.id == firstStage.id }
        )
        XCTAssertEqual(openModel.missingMasteriesForBoss, 0)
        XCTAssertEqual(openModel.bossNode?.state, .active)
    }

    func testStoryMigrationPicksBestStarredAlternativeAndNeverRelocks() throws {
        let catalog = LessonStore.shared.libraryCatalog
        let storyMap = try StoryMap.loadBundled()
        let firstStage = try XCTUnwrap(catalog.stages.first)
        let mapNodes = storyMap.nodes(for: firstStage.id)
        let forkIndices = mapNodes.enumerated().compactMap { $0.element.isFork ? $0.offset : nil }
        XCTAssertGreaterThanOrEqual(forkIndices.count, 2)

        let fork0Idx = forkIndices[0]
        let fork0Ids = mapNodes[fork0Idx].lessonIds
        let fork1Idx = forkIndices[1]
        let fork1Ids = mapNodes[fork1Idx].lessonIds

        var progress: [Int: LessonProgress] = [
            // Fork 0: second alternative has more stars (★2 vs ★1) -> picks second
            fork0Ids[0]: LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85),
            fork0Ids[1]: LessonProgress(passed: true, mastery: true, memory: false, currentBpm: 100, bestScore: 0.95),
            // Fork 1: tie (both ★1) -> picks first
            fork1Ids[0]: LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85),
            fork1Ids[1]: LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85)
        ]

        // Also play a lesson in stage 2 so stage 2 stays open (never relocks)
        let secondStage = try XCTUnwrap(catalog.stages.dropFirst().first)
        let secondStageLesson = try XCTUnwrap(secondStage.lessons.first)
        progress[secondStageLesson.id] = LessonProgress(passed: true, mastery: false, memory: false, currentBpm: 80, bestScore: 0.85)

        let migrated = DrummerPathEvaluator.migrateLegacyProgress(
            existingState: DrummerPathState(),
            progress: progress,
            trainingLog: TrainingLog(),
            catalog: catalog
        )
        XCTAssertEqual(migrated.storyForkChoices[StoryMap.forkChoiceKey(stageId: firstStage.id, nodeIndex: fork0Idx)], fork0Ids[1])
        XCTAssertEqual(migrated.storyForkChoices[StoryMap.forkChoiceKey(stageId: firstStage.id, nodeIndex: fork1Idx)], fork1Ids[0])

        let builtStages = DrummerPathMapBuilder.buildStages(
            catalog: catalog,
            progress: progress,
            pathState: migrated,
            storyMap: storyMap,
            openStageIDs: [secondStage.id]
        )
        let builtSecond = try XCTUnwrap(builtStages.first { $0.id == secondStage.id })
        XCTAssertTrue(builtSecond.isStageOpen)
        XCTAssertTrue(DrummerPathMapBuilder.isOpenInStory(
            lesson: secondStageLesson,
            catalog: catalog,
            progress: progress,
            pathState: migrated,
            storyMap: storyMap,
            openStageIDs: [secondStage.id]
        ))
    }
}
