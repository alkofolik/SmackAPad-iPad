import XCTest
@testable import SmackAPad

final class LibraryCatalogTests: XCTestCase {
    private func lesson(_ id: Int, cat: String = "eighth", genre: String = "Rock", tags: [String] = [],
                        division: Int = 16, level: Int = 1) -> Lesson {
        Lesson(id: id, cat: cat, title: "Lesson \(id)", genre: genre, tags: tags, text: "", division: division,
               bars: 1, startBpm: 60, targetBpm: 100, level: level, src: "Test", hits: [])
    }

    private struct Source: LessonContentSource {
        let sourceIdentifier = "library-tests"
        let lessons: [Lesson]
        func loadLessons() throws -> [Lesson] { lessons }
    }

    private func environment(_ lessons: [Lesson], oldUnlocks: [String] = [],
                             oldProgress: [Int: LessonProgress] = [:]) throws -> (ProgressionManager, ProgressStore, SettingsManager) {
        let suite = "LibraryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        defaults.set(oldUnlocks, forKey: ProgressionConstant.softUnlockedCategoriesStorageKey)
        let progress = ProgressStore(fileURL: directory.appendingPathComponent("progress.json"), autoLoad: false)
        for (id, record) in oldProgress { progress.setProgress(record, for: id, autoSave: false) }
        let store = LessonStore(sources: [Source(lessons: lessons)])
        let settings = SettingsManager(userDefaults: defaults)
        return (ProgressionManager(lessonStore: store, progressStore: progress, settingsManager: settings, userDefaults: defaults), progress, settings)
    }

    func testTechniquePrecedenceAndExactGenreLists() {
        XCTAssertEqual(LessonTechnique.classify(lesson(1, tags: ["toms", "ghost notes", "16ths"], division: 12)), .fills)
        XCTAssertEqual(LessonTechnique.classify(lesson(1, cat: "fills")), .fills)
        XCTAssertEqual(LessonTechnique.classify(lesson(1, tags: ["triplet feel", "ghost notes", "16ths"])), .swing)
        XCTAssertEqual(LessonTechnique.classify(lesson(1, division: 12)), .swing)
        XCTAssertEqual(LessonTechnique.classify(lesson(1, tags: ["ghost notes", "16ths"])), .ghost)
        XCTAssertEqual(LessonTechnique.classify(lesson(1, tags: ["16ths"])), .sixteenths)
        XCTAssertEqual(LessonTechnique.classify(lesson(1)), .groove)
        let genres: [(LessonGenre, [String])] = [
            (.rock, ["Rock", "Punk"]), (.funk, ["Funk", "Soul", "Gospel", "Blues"]),
            (.jazz, ["Jazz", "New Orleans"]), (.hiphop, ["Hip hop", "Trap", "Lo-fi", "Trip hop"]),
            (.world, ["Latin", "Afrobeat", "Afro-Cuban", "Highlife", "Reggae", "Reggaeton", "Middle Eastern", "Moombahton"]),
            (.pop, ["Pop", "Country"]), (.electronic, ["House", "Jersey club", "Footwork / juke", "Unknown", "rock", ""])
        ]
        for (expected, names) in genres {
            for name in names { XCTAssertEqual(LessonGenre.classify(lesson(1, genre: name)), expected, name) }
        }
    }

    func testStageOrderKeepsStarterFirstAndRoundRobinsFirstSeenGenres() {
        let input = [lesson(1, genre: "Jazz"), lesson(2, genre: "Rock"), lesson(3, genre: "Funk"),
                     lesson(4, genre: "Jazz"), lesson(5, cat: "starter"), lesson(6, genre: "Punk"),
                     lesson(7, cat: "intro"), lesson(8, genre: "Jazz")]
        XCTAssertEqual(LibraryCatalog.orderStage(input).map(\.id), [5, 7, 1, 2, 3, 4, 6, 8])
        XCTAssertEqual(input.map(\.id), Array(1...8))
        XCTAssertTrue(LibraryCatalog.orderStage([]).isEmpty)
    }

    func testStagesOmitEmptyGroupsAndHigherLevelGrooveAndSeparateExtensions() {
        let input = [lesson(1), lesson(2, tags: ["16ths"]), lesson(3, level: 4),
                     lesson(4, tags: ["16ths"], level: 4), lesson(5, cat: "jersey"), lesson(6, cat: "footwork")]
        let catalog = LibraryCatalog(lessons: input)
        XCTAssertEqual(catalog.stages.map(\.id), ["L1-groove", "L1-sixteenths", "L4-sixteenths"])
        for mode in LibraryViewMode.allCases {
            let groups = catalog.groups(in: mode)
            XCTAssertEqual(Set(groups.flatMap(\.lessons).map(\.id)), [1, 2, 4, 5, 6])
            XCTAssertEqual(Set(groups.filter(\.isExtension).flatMap(\.lessons).map(\.id)), [5, 6])
        }
    }

    func testBundledCatalogueHasSameLessonPopulationInAllViews() {
        let catalog = LessonStore.shared.libraryCatalog
        XCTAssertEqual(catalog.lessons.count, 595)
        XCTAssertEqual(catalog.path.count, 583)
        XCTAssertEqual(catalog.stages.count, 23)
        for mode in LibraryViewMode.allCases {
            let ids = catalog.groups(in: mode).flatMap(\.lessons).map(\.id)
            XCTAssertEqual(ids.count, 595)
            XCTAssertEqual(Set(ids), Set(catalog.lessons.map(\.id)))
        }
    }

    func testUnlockThresholdRoundsUpCapsAtTenAndDoesNotRequireEarlierStageOpen() throws {
        for count in [1, 3, 20, 25] {
            let first = (1...count).map { lesson($0) }
            let input = first + [lesson(100, tags: ["16ths"]), lesson(101, tags: ["ghost notes"])]
            let (manager, progress, _) = try environment(input)
            let stages = manager.catalog.stages
            let needed = min((count + 1) / 2, 10)
            XCTAssertTrue(manager.isStageOpen(stages[0]))
            XCTAssertEqual(manager.unlockProgress(for: stages[1]).needed, needed)
            XCTAssertFalse(manager.isStageOpen(stages[1]))
            for item in first.prefix(needed - 1) { progress.recordPass(lessonId: item.id, mastery: true, autoSave: false) }
            XCTAssertFalse(manager.isStageOpen(stages[1]))
            progress.recordPass(lessonId: first[needed - 1].id, mastery: true, autoSave: false)
            XCTAssertTrue(manager.isStageOpen(stages[1]))
        }
        let (manager, progress, _) = try environment([lesson(1), lesson(2, tags: ["16ths"]), lesson(3, tags: ["ghost notes"])])
        XCTAssertFalse(manager.isStageOpen(manager.catalog.stages[1]))
        progress.recordPass(lessonId: 2, mastery: true, autoSave: false)
        XCTAssertTrue(manager.isStageOpen(manager.catalog.stages[2]))
    }

    func testPlayedLessonAndSoftUnlockOpenWholeStageAndPersist() throws {
        let input = [lesson(1), lesson(2, tags: ["16ths"]), lesson(3, tags: ["16ths"]), lesson(4, tags: ["ghost notes"])]
        let (manager, progress, settings) = try environment(input)
        progress.setProgress(LessonProgress(hasPlayed: true), for: 2, autoSave: false)
        XCTAssertTrue(manager.isLessonOpen(input[2]))
        XCTAssertFalse(manager.isLessonOpen(input[3]))
        manager.requestSoftUnlock(for: "L1-ghost")
        manager.cancelSoftUnlock()
        XCTAssertFalse(manager.isLessonOpen(input[3]))
        manager.requestSoftUnlock(for: "L1-ghost")
        manager.confirmSoftUnlock()
        XCTAssertTrue(manager.isLessonOpen(input[3]))
        let restored = ProgressionManager(lessonStore: manager.lessonStore, progressStore: progress,
                                          settingsManager: settings, userDefaults: manager.userDefaults)
        XCTAssertTrue(restored.isLessonOpen(input[3]))
    }

    func testCategoryMigrationPreservesManualAndAutomaticAccessOnce() throws {
        let starters = (1...5).map { lesson($0, cat: "starter") }
        let input = starters + [lesson(10, level: 2), lesson(11, cat: "ghost", tags: ["ghost notes"], level: 3),
                                lesson(12, cat: "swing", division: 12, level: 4)]
        let (manager, progress, settings) = try environment(input, oldUnlocks: ["swing"],
            oldProgress: Dictionary(uniqueKeysWithValues: starters.map { ($0.id, LessonProgress(passed: true)) }))
        XCTAssertTrue(manager.softUnlockedStages.contains("L2-groove"))
        XCTAssertTrue(manager.softUnlockedStages.contains("L4-swing"))
        XCTAssertFalse(manager.isLessonOpen(input[6]))
        manager.resetProgression()
        let restored = ProgressionManager(lessonStore: manager.lessonStore, progressStore: progress,
                                          settingsManager: settings, userDefaults: manager.userDefaults)
        XCTAssertTrue(restored.softUnlockedStages.isEmpty)
    }

    func testCombinedFiltersCountsEmptySelectionAndSettingsRestore() throws {
        let (manager, progress, settings) = try environment([lesson(1), lesson(2, genre: "Jazz"), lesson(3, tags: ["16ths"])])
        progress.setProgress(LessonProgress(passed: true, mastery: true), for: 1, autoSave: false)
        let matching = manager.catalog.matching(manager.catalog.path, view: .path, query: "Rock", cross: "rock", language: .english)
        XCTAssertEqual(matching.map(\.id), [1, 3])
        XCTAssertEqual(matching.filter { LibraryStarFilter.classify(progress.progress(for: $0.id)) == .two }.map(\.id), [1])
        XCTAssertTrue(manager.catalog.matching(manager.catalog.path, view: .genre, query: "", cross: "ghost", language: .english).isEmpty)
        settings.libraryView = "genre"
        settings.libraryStarFilters = []
        settings.nextLessonSource = "technique"
        let restored = SettingsManager(userDefaults: manager.userDefaults)
        XCTAssertEqual(restored.libraryView, "genre")
        XCTAssertTrue(restored.libraryStarFilters.isEmpty)
        XCTAssertEqual(restored.nextLessonSource, "technique")
    }

    func testNextLessonResumesUnpassedAnchorWrapsAndFallsBackToPath() throws {
        let input = [lesson(1, genre: "Jazz"), lesson(2), lesson(3, genre: "Jazz"), lesson(4, cat: "jersey")]
        let (manager, progress, _) = try environment(input)
        XCTAssertEqual(manager.nextLesson(after: input[0], source: .genre)?.id, 1)
        progress.recordPass(lessonId: 1, autoSave: false)
        XCTAssertEqual(manager.nextLesson(after: input[0], source: .genre)?.id, 3)
        progress.recordPass(lessonId: 3, autoSave: false)
        XCTAssertEqual(manager.nextLesson(after: input[2], source: .genre)?.id, 2)
        // All also rotates after the anchor, so the extension follows before wraparound.
        XCTAssertEqual(manager.nextLesson(after: input[2], source: .all)?.id, 4)
        progress.recordPass(lessonId: 2, autoSave: false)
        XCTAssertEqual(manager.nextLesson(after: input[2], source: .all)?.id, 4)
    }
}
