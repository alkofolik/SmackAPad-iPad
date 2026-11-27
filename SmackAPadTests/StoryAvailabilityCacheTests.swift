import XCTest
@testable import SmackAPad

final class StoryAvailabilityCacheTests: XCTestCase {

    private var tempDir: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("StoryAvailabilityCacheTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        suiteName = "cz.kju.SmackAPad.Tests.StoryAvailabilityCache.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        if let suiteName {
            defaults.removePersistentDomain(forName: suiteName)
        }
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    private func makeEnvironment() -> (ProgressionManager, ProgressStore, SettingsManager) {
        let store = ProgressStore(fileURL: tempDir.appendingPathComponent("progress.json"), autoLoad: false)
        let settings = SettingsManager(userDefaults: defaults)
        let progression = ProgressionManager(
            lessonStore: .shared,
            progressStore: store,
            settingsManager: settings,
            userDefaults: defaults
        )
        return (progression, store, settings)
    }

    private func seedMidProgress(store: ProgressStore, catalog: LibraryCatalog) {
        for lesson in catalog.introLessons {
            store.recordResult(
                lessonId: lesson.id,
                passed: true,
                mastery: true,
                bpm: lesson.targetBpm,
                score: 0.92,
                autoSave: false
            )
        }
        for stage in catalog.stages.prefix(6) {
            for lesson in stage.lessons.prefix(10) {
                store.recordResult(
                    lessonId: lesson.id,
                    passed: true,
                    mastery: false,
                    bpm: lesson.startBpm + 10,
                    score: 0.85,
                    autoSave: false
                )
            }
            try? store.recordBossVictory(stageID: stage.id, catalog: catalog)
        }
    }

    private func seedFullProgress(store: ProgressStore, catalog: LibraryCatalog) {
        for lesson in catalog.lessons {
            store.recordResult(
                lessonId: lesson.id,
                passed: true,
                mastery: true,
                bpm: lesson.targetBpm,
                score: 0.95,
                autoSave: false
            )
        }
        for stage in catalog.stages {
            try? store.recordBossVictory(stageID: stage.id, catalog: catalog)
        }
    }

    private func assertMatchesUncachedReference(
        progression: ProgressionManager,
        store: ProgressStore,
        settings: SettingsManager,
        label: String
    ) {
        let catalog = progression.catalog
        let openStageIDs = progression.storyOpenStageIDs
        for lesson in catalog.lessons {
            let expected: Bool
            switch settings.playMode {
            case .free:
                expected = true
            case .story:
                expected = DrummerPathMapBuilder.isOpenInStory(
                    lesson: lesson,
                    catalog: catalog,
                    progress: store.records,
                    pathState: store.drummerPath,
                    openStageIDs: openStageIDs
                )
            }
            XCTAssertEqual(
                progression.isLessonOpen(lesson),
                expected,
                "Mismatch for lesson \(lesson.id) in \(label) (\(settings.playMode))"
            )
        }
    }

    // MARK: - Rule 1: Measure buildStages count

    func testBuildStagesCountDuringFullCatalogLessonScan() {
        let (progression, store, settings) = makeEnvironment()
        XCTAssertEqual(settings.playMode, .story)
        seedMidProgress(store: store, catalog: progression.catalog)

        let allLessons = progression.catalog.lessons
        XCTAssertGreaterThan(allLessons.count, 500)

        DrummerPathMapBuilder.resetBuildStagesCountForTesting()
        for lesson in allLessons {
            _ = progression.isLessonOpen(lesson)
        }
        let count = DrummerPathMapBuilder.buildStagesCountForTesting
        print("MEASURE_AFTER buildStages count for \(allLessons.count) lessons: \(count)")
        XCTAssertEqual(count, 1)

        // Second full scan without any state changes should trigger 0 rebuilds.
        for lesson in allLessons {
            _ = progression.isLessonOpen(lesson)
        }
        XCTAssertEqual(DrummerPathMapBuilder.buildStagesCountForTesting, 1)
    }

    // MARK: - Rule 4: Equality across fresh, mid, and full profiles in both modes

    func testCachedAvailabilityMatchesReferenceAcrossProfilesAndModes() {
        // Fresh
        do {
            let (progression, store, settings) = makeEnvironment()
            settings.playMode = .story
            assertMatchesUncachedReference(progression: progression, store: store, settings: settings, label: "fresh")
            settings.playMode = .free
            assertMatchesUncachedReference(progression: progression, store: store, settings: settings, label: "fresh")
        }

        // Mid progress
        do {
            let (progression, store, settings) = makeEnvironment()
            seedMidProgress(store: store, catalog: progression.catalog)
            settings.playMode = .story
            assertMatchesUncachedReference(progression: progression, store: store, settings: settings, label: "mid")
            settings.playMode = .free
            assertMatchesUncachedReference(progression: progression, store: store, settings: settings, label: "mid")
        }

        // Full progress
        do {
            let (progression, store, settings) = makeEnvironment()
            seedFullProgress(store: store, catalog: progression.catalog)
            settings.playMode = .story
            assertMatchesUncachedReference(progression: progression, store: store, settings: settings, label: "full")
            settings.playMode = .free
            assertMatchesUncachedReference(progression: progression, store: store, settings: settings, label: "full")
        }
    }

    // MARK: - Rule 3: Invalidation tests

    func testInvalidatesAfterStar1AndStar2Progress() throws {
        let (progression, store, _) = makeEnvironment()
        let firstStage = try XCTUnwrap(progression.catalog.stages.first)
        let storyMap = try StoryMap.loadBundled()
        let mapNodes = storyMap.nodes(for: firstStage.id)
        let byId = Dictionary(firstStage.lessons.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        let firstLesson = try XCTUnwrap(byId[try XCTUnwrap(mapNodes.first?.lessonIds.first)])
        let secondLesson = try XCTUnwrap(byId[try XCTUnwrap(mapNodes.dropFirst().first?.lessonIds.first)])

        XCTAssertTrue(progression.isLessonOpen(firstLesson))
        XCTAssertFalse(progression.isLessonOpen(secondLesson))

        // ★1 on first lesson immediately opens second lesson (no stale cache).
        store.recordResult(
            lessonId: firstLesson.id,
            passed: true,
            mastery: false,
            bpm: firstLesson.startBpm,
            score: 0.85,
            autoSave: false
        )
        XCTAssertTrue(progression.isLessonOpen(secondLesson))

        // ★2 on enough lessons to open the next node also updates immediately.
        store.recordResult(
            lessonId: firstLesson.id,
            passed: true,
            mastery: true,
            bpm: firstLesson.targetBpm,
            score: 0.95,
            autoSave: false
        )
        XCTAssertTrue(progression.isLessonOpen(secondLesson))
    }

    func testInvalidatesAfterStageExamVictory() throws {
        let (progression, store, _) = makeEnvironment()
        let stages = progression.catalog.stages
        let firstStage = try XCTUnwrap(stages.first)
        let secondStage = try XCTUnwrap(stages.dropFirst().first)
        let storyMap = try StoryMap.loadBundled()
        let secondStageFirstId = try XCTUnwrap(storyMap.nodes(for: secondStage.id).first?.lessonIds.first)
        let secondStageFirstLesson = try XCTUnwrap(secondStage.lessons.first { $0.id == secondStageFirstId })

        XCTAssertFalse(progression.isLessonOpen(secondStageFirstLesson))

        try store.recordBossVictory(stageID: firstStage.id, catalog: progression.catalog)
        XCTAssertTrue(progression.isLessonOpen(secondStageFirstLesson))
    }

    func testInvalidatesAfterForkRouteChoice() throws {
        let (progression, store, _) = makeEnvironment()
        let firstStage = try XCTUnwrap(progression.catalog.stages.first)
        let storyMap = try StoryMap.loadBundled()
        let mapNodes = storyMap.nodes(for: firstStage.id)
        let forkIndex = try XCTUnwrap(mapNodes.firstIndex(where: \.isFork))
        let forkIds = mapNodes[forkIndex].lessonIds
        XCTAssertGreaterThanOrEqual(forkIds.count, 2)
        let byId = Dictionary(firstStage.lessons.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        for idx in 0..<forkIndex {
            for lid in mapNodes[idx].lessonIds {
                store.recordResult(
                    lessonId: lid,
                    passed: true,
                    mastery: false,
                    bpm: 80,
                    score: 0.85,
                    autoSave: false
                )
            }
        }
        let forkA = try XCTUnwrap(byId[forkIds[0]])
        let mergeId = try XCTUnwrap(mapNodes[forkIndex + 1].lessonIds.first)
        let mergeLesson = try XCTUnwrap(byId[mergeId])

        // Pass forkA before choosing fork route -> merge lesson is not yet reached if fork isn't chosen?
        // Let's warm the cache first, then pass forkA and choose fork route.
        _ = progression.isLessonOpen(mergeLesson)

        store.recordResult(
            lessonId: forkA.id,
            passed: true,
            mastery: false,
            bpm: 80,
            score: 0.85,
            autoSave: false
        )
        store.selectStoryFork(stageId: firstStage.id, nodeIndex: forkIndex, lessonId: forkA.id)

        XCTAssertTrue(progression.isLessonOpen(mergeLesson))
        assertMatchesUncachedReference(progression: progression, store: store, settings: SettingsManager(userDefaults: defaults), label: "after-fork")
    }

    func testInvalidatesAfterSwitchingPlayMode() throws {
        let (progression, _, settings) = makeEnvironment()
        let laterStage = try XCTUnwrap(progression.catalog.stages.last)
        let lockedLesson = try XCTUnwrap(laterStage.lessons.first)

        XCTAssertEqual(settings.playMode, .story)
        XCTAssertFalse(progression.isLessonOpen(lockedLesson))

        settings.playMode = .free
        XCTAssertTrue(progression.isLessonOpen(lockedLesson))

        settings.playMode = .story
        XCTAssertFalse(progression.isLessonOpen(lockedLesson))
    }
}
