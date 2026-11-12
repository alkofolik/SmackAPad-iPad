//
//  ProgressionTests.swift
//  SmackAPadTests
//
//  Unit tests for category unlock logic, soft unlock, 8-pad mode rules, and intro accessibility.
//

import XCTest
@testable import SmackAPad

final class ProgressionTests: XCTestCase {

    private var tempDirectory: URL!
    private var testUserDefaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "cz.kju.SmackAPad.Tests.Progression.\(UUID().uuidString)"
        testUserDefaults = UserDefaults(suiteName: suiteName)!
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let suiteName = suiteName {
            testUserDefaults.removePersistentDomain(forName: suiteName)
        }
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        super.tearDown()
    }

    private func makeIsolatedEnvironment(
        lessonsToUnlock: Int = ProgressionConstant.kLessonsToUnlock,
        padCount: Int = 16,
        useSyntheticStarter: Bool = false
    ) -> (ProgressionManager, ProgressStore, LessonStore) {
        let progressFileURL = tempDirectory.appendingPathComponent("progress.json")
        let progressStore = ProgressStore(fileURL: progressFileURL, autoLoad: false)
        let lessonStore: LessonStore
        if useSyntheticStarter {
            // The historical category migration rule needs five starter fixtures.
            // The bundled source retains lesson 6; the catalogue projects it into Intro.
            let template = LessonStore.shared.lessons.first { $0.cat == "starter" }!
            let starters = (0..<5).map { index in
                Lesson(id: 90000 + index, cat: "starter", title: "Starter fixture \(index)", genre: template.genre,
                       tags: template.tags, text: "", division: template.division, bars: template.bars,
                       startBpm: template.startBpm, targetBpm: template.targetBpm, level: template.level,
                       src: "Test", hits: template.hits)
            }
            lessonStore = LessonStore(sources: [FixtureSource(lessons:
                starters + LessonStore.shared.lessons.filter { $0.cat != "starter" })])
        } else { lessonStore = LessonStore.shared }
        let settingsManager = SettingsManager(userDefaults: testUserDefaults)

        // Set pad count profile
        if padCount == 8 {
            settingsManager.activeProfileName = ControllerProfile.standard8.profileName
        } else {
            settingsManager.activeProfileName = ControllerProfile.standard16.profileName
        }

        let progression = ProgressionManager(
            lessonStore: lessonStore,
            progressStore: progressStore,
            settingsManager: settingsManager,
            userDefaults: testUserDefaults,
            lessonsToUnlock: lessonsToUnlock,
            categoryOrder: useSyntheticStarter ? ["starter"] + CategoryOrder.categories : CategoryOrder.categories
        )

        return (progression, progressStore, lessonStore)
    }

    private struct FixtureSource: LessonContentSource {
        let sourceIdentifier = "category-migration-fixture"
        let lessons: [Lesson]
        func loadLessons() throws -> [Lesson] { lessons }
    }

    // MARK: - Task 1: Category Order

    func testCategoryOrderMatchesSpec() {
        let expectedCategories = [
            "eighth",
            "sixteenth",
            "electronic",
            "ghost",
            "swing",
            "world",
            "fills"
        ]
        XCTAssertEqual(CategoryOrder.categories, expectedCategories)
        XCTAssertEqual(ProgressionConstant.defaultCategoryOrder, expectedCategories)

        XCTAssertEqual(CategoryOrder.initialUnlockedCategory, "eighth")
        XCTAssertFalse(CategoryOrder.contains("starter"))
        XCTAssertEqual(CategoryOrder.nextCategory(after: "eighth"), "sixteenth")
        XCTAssertEqual(CategoryOrder.nextCategory(after: "world"), "fills")
        XCTAssertNil(CategoryOrder.nextCategory(after: "fills"))

        XCTAssertEqual(CategoryOrder.previousCategory(before: "sixteenth"), "eighth")
        XCTAssertNil(CategoryOrder.previousCategory(before: "eighth"))
    }

    // MARK: - Task 2: First Category Unlocked by Default

    func testFirstCategoryUnlockedByDefault() {
        let (progression, _, _) = makeIsolatedEnvironment()

        XCTAssertTrue(progression.isCategoryUnlocked("eighth"))
        XCTAssertTrue(progression.isIntroAccessible)

        let lockedCategories = ["sixteenth", "electronic", "ghost", "swing", "world", "fills"]
        for cat in lockedCategories {
            XCTAssertFalse(progression.isCategoryUnlocked(cat), "\(cat) must be locked initially")
        }
    }

    // MARK: - Task 3: Unlock Rule (5 Passed Lessons)

    func testProgressionUnlocksAfterFivePassedLessons() {
        let (progression, progressStore, lessonStore) = makeIsolatedEnvironment(lessonsToUnlock: 5, useSyntheticStarter: true)

        let starterLessons = lessonStore.lessons(in: "starter")
        XCTAssertGreaterThanOrEqual(starterLessons.count, 5, "Starter must have at least 5 lessons")

        // Pass 4 lessons in starter -> eighth should still be locked
        for i in 0..<4 {
            progressStore.recordPass(lessonId: starterLessons[i].id)
        }
        XCTAssertEqual(progression.passedLessonCount(in: "starter"), 4)
        XCTAssertFalse(progression.isCategoryUnlocked("eighth"), "Eighth must remain locked with only 4 passed lessons")

        // Pass 5th lesson -> eighth unlocks immediately
        progressStore.recordPass(lessonId: starterLessons[4].id)
        XCTAssertEqual(progression.passedLessonCount(in: "starter"), 5)
        XCTAssertTrue(progression.isCategoryUnlocked("eighth"), "Eighth must unlock after 5 passed lessons in starter")

        // sixteenth remains locked until 5 lessons in eighth are passed
        XCTAssertFalse(progression.isCategoryUnlocked("sixteenth"))

        let eighthLessons = lessonStore.lessons(in: "eighth")
        for i in 0..<5 {
            progressStore.recordPass(lessonId: eighthLessons[i].id)
        }
        XCTAssertTrue(progression.isCategoryUnlocked("sixteenth"), "Sixteenth must unlock after 5 passed lessons in eighth")
    }

    func testConfigurableLessonsToUnlockConstant() {
        XCTAssertEqual(ProgressionConstant.kLessonsToUnlock, 5)

        // Test custom threshold (e.g. 3)
        let (progression, progressStore, lessonStore) = makeIsolatedEnvironment(lessonsToUnlock: 3, useSyntheticStarter: true)
        let starterLessons = lessonStore.lessons(in: "starter")

        for i in 0..<2 {
            progressStore.recordPass(lessonId: starterLessons[i].id)
        }
        XCTAssertFalse(progression.isCategoryUnlocked("eighth"))

        progressStore.recordPass(lessonId: starterLessons[2].id)
        XCTAssertTrue(progression.isCategoryUnlocked("eighth"), "Unlocks at configured threshold 3")
    }

    // MARK: - Task 4: Soft Unlock Workflow

    func testSoftUnlockWorkflowWithConfirmation() {
        let (progression, _, _) = makeIsolatedEnvironment()

        XCTAssertFalse(progression.isCategoryUnlocked("swing"))
        XCTAssertNil(progression.categoryPendingSoftUnlock)

        // User taps locked category -> alert requested
        progression.requestSoftUnlock(for: "swing")
        XCTAssertEqual(progression.categoryPendingSoftUnlock, "swing")
        XCTAssertFalse(progression.isCategoryUnlocked("swing"), "Not unlocked until confirmed")

        // User cancels
        progression.cancelSoftUnlock()
        XCTAssertNil(progression.categoryPendingSoftUnlock)
        XCTAssertFalse(progression.isCategoryUnlocked("swing"))

        // User requests again and confirms
        progression.requestSoftUnlock(for: "swing")
        progression.confirmSoftUnlock()

        XCTAssertNil(progression.categoryPendingSoftUnlock)
        XCTAssertTrue(progression.isCategoryUnlocked("swing"), "Immediately unlocked after confirmation")
        XCTAssertTrue(progression.isSoftUnlocked("swing"))

        // Verify soft unlock is persisted
        let (progression2, _, _) = makeIsolatedEnvironment()
        XCTAssertTrue(progression2.isCategoryUnlocked("swing"), "Soft unlock must persist across instances")
    }

    func testSoftUnlockedCategoryCanCascadeUnlockNextCategory() {
        let (progression, progressStore, lessonStore) = makeIsolatedEnvironment(lessonsToUnlock: 5)

        // Soft-unlock "ghost" directly without passing previous categories
        progression.softUnlock(category: "ghost")
        XCTAssertTrue(progression.isCategoryUnlocked("ghost"))
        XCTAssertFalse(progression.isCategoryUnlocked("swing"))

        // Pass 5 lessons in ghost
        let ghostLessons = lessonStore.lessons(in: "ghost")
        for i in 0..<5 {
            progressStore.recordPass(lessonId: ghostLessons[i].id)
        }

        // Now swing should unlock because its previous category is unlocked and has 5 passes
        XCTAssertTrue(progression.isCategoryUnlocked("swing"))
    }

    // MARK: - Task 5: 8-Pad Mode Unlocking and Layout Exclusion

    func testAllBundledLessonsHaveEightPadLayoutAndUnlockInEightPadMode() {
        let (progression8, progressStore, lessonStore) = makeIsolatedEnvironment(padCount: 8)

        // All 587 bundled lessons must have an 8-pad layout (SPEC §6)
        for lesson in lessonStore.lessons {
            XCTAssertNotNil(
                EightPadLayout.slots(for: lesson),
                "Bundled lesson \(lesson.id) (\(lesson.title)) must have 8-pad layout"
            )
        }

        // Production uses two-star Path stages; the retired category has no visible lessons.
        XCTAssertTrue(lessonStore.lessons(in: "starter").isEmpty)
        XCTAssertTrue(progression8.catalog.introLessons.contains { $0.id == 6 })
        XCTAssertFalse(progression8.catalog.path.contains { $0.id == 6 })
        let stages = progression8.catalog.stages
        let requirement = progression8.unlockProgress(for: stages[1])
        for lesson in stages[0].lessons.prefix(requirement.needed) {
            progressStore.recordPass(lessonId: lesson.id, mastery: true)
        }
        XCTAssertEqual(progression8.unlockProgress(for: stages[1]).completed, requirement.needed)
        XCTAssertTrue(progression8.isStageOpen(stages[1]))
    }

    func testLessonWithoutEightPadLayoutExcludedFromEightPadUnlockCount() throws {
        let progressFileURL = tempDirectory.appendingPathComponent("progress-synth.json")
        let progressStore = ProgressStore(fileURL: progressFileURL, autoLoad: false)
        let settingsManager = SettingsManager(userDefaults: testUserDefaults)

        // Create an unplayable synthetic lesson (requires 9 distinct pads without hits8)
        let unplayableLesson = Lesson(
            id: 88801,
            cat: "starter",
            title: "9-pad synthetic",
            genre: "Test",
            tags: [],
            text: "",
            division: 16,
            bars: 1,
            startBpm: 60,
            targetBpm: 80,
            level: 1,
            src: "Test",
            hits: (0...8).map { LessonHit(step: $0, padIndex: $0, hand: "R", velocity: 100) },
            hits8: nil
        )
        XCTAssertNil(EightPadLayout.slots(for: unplayableLesson), "Synthetic lesson must not have 8-pad layout")

        // 5 playable starter lessons
        let playableLessons = (1...5).map { i in
            Lesson(
                id: 88800 + i + 1,
                cat: "starter",
                title: "Playable \(i)",
                genre: "Test",
                tags: [],
                text: "",
                division: 16,
                bars: 1,
                startBpm: 60,
                targetBpm: 80,
                level: 1,
                src: "Test",
                hits: [LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)]
            )
        }

        let customStore = LessonStore(sources: [], autoLoad: false)
        let tempLessonsURL = tempDirectory.appendingPathComponent("synthetic-starter.json")
        let allSynth = [unplayableLesson] + playableLessons
        let data = try JSONEncoder().encode(allSynth)
        try data.write(to: tempLessonsURL)

        try customStore.register(source: ExternalJSONContentSource(sourceIdentifier: "synth", fileURL: tempLessonsURL))

        let progression = ProgressionManager(
            lessonStore: customStore,
            progressStore: progressStore,
            settingsManager: settingsManager,
            userDefaults: testUserDefaults,
            lessonsToUnlock: 5,
            categoryOrder: ["starter"] + CategoryOrder.categories
        )

        // Pass 4 playable lessons + the 1 unplayable lesson
        for lesson in playableLessons.prefix(4) {
            progressStore.recordPass(lessonId: lesson.id)
        }
        progressStore.recordPass(lessonId: unplayableLesson.id)

        // In 16-pad mode: 4 + 1 = 5 passed -> eighth unlocks
        XCTAssertEqual(progression.passedLessonCount(in: "starter", padCount: 16), 5)
        XCTAssertTrue(progression.isCategoryUnlocked("eighth", padCount: 16))

        // In 8-pad mode: unplayable lesson is excluded -> count is 4 -> eighth remains locked
        XCTAssertEqual(progression.passedLessonCount(in: "starter", padCount: 8), 4)
        XCTAssertFalse(progression.isCategoryUnlocked("eighth", padCount: 8))

        // Pass the 5th playable lesson -> now 8-pad mode reaches 5 and unlocks
        progressStore.recordPass(lessonId: playableLessons[4].id)
        XCTAssertEqual(progression.passedLessonCount(in: "starter", padCount: 8), 5)
        XCTAssertTrue(progression.isCategoryUnlocked("eighth", padCount: 8), "Unplayable lesson never blocks unlocking")
    }

    // MARK: - Task 6: Intro Section Always Accessible

    func testIntroSectionAlwaysAccessible() {
        let (progression, progressStore, lessonStore) = makeIsolatedEnvironment()

        // Fresh environment with 0 passes
        XCTAssertTrue(progression.isIntroAccessible)
        XCTAssertTrue(progression.isCategoryUnlocked("intro"))
        XCTAssertTrue(progression.isIntro(category: "intro"))

        // Intro is not in sequential categoryOrder
        XCTAssertFalse(progression.categoryOrder.contains("intro"))

        // Intro status
        let introStatus = progression.status(for: "intro")
        XCTAssertTrue(introStatus.isUnlocked)
        XCTAssertTrue(introStatus.isIntro)
        XCTAssertEqual(introStatus.categoryId, "intro")

        // 25 projected Intro exercises exist; the bundled file still contains 24.
        let introLessons = lessonStore.lessons(in: "intro")
        XCTAssertEqual(introLessons.count, 25)

        // Intro progress does not alter the always-open first category.
        progressStore.recordPass(lessonId: introLessons[0].id)
        XCTAssertTrue(progression.isCategoryUnlocked("eighth"))
    }

    // MARK: - Task 7: Electronic Path Folded into Electronic Category

    func testElectronicPathLessonsFoldedIntoElectronicCategory() {
        let (progression, progressStore, _) = makeIsolatedEnvironment(lessonsToUnlock: 5)

        // Canonical mapping tests
        XCTAssertEqual(ProgressionManager.canonicalCategory(forCategory: "uk-club"), "electronic")
        XCTAssertEqual(ProgressionManager.canonicalCategory(forCategory: "broken-techno"), "electronic")
        XCTAssertEqual(ProgressionManager.canonicalCategory(forCategory: "hardgroove"), "electronic")
        XCTAssertEqual(ProgressionManager.canonicalCategory(forCategory: "starter"), "starter")

        // Electronic category contains core electronic (45) + electronic-path (12) + extensions (12)
        let electronicLessons = progression.lessons(in: "electronic")
        XCTAssertEqual(electronicLessons.count, 69, "Expected 45 core + 12 electronic-path + 12 extensions")

        // Electronic path lessons are present in electronic query
        XCTAssertTrue(electronicLessons.contains(where: { $0.id == 13001 })) // hardgroove
        XCTAssertTrue(electronicLessons.contains(where: { $0.id == 14001 })) // broken-techno
        XCTAssertTrue(electronicLessons.contains(where: { $0.id == 15001 })) // uk-club

        // Soft-unlock electronic to test passing electronic-path lessons
        progression.softUnlock(category: "electronic")
        XCTAssertTrue(progression.isCategoryUnlocked("electronic"))
        XCTAssertFalse(progression.isCategoryUnlocked("ghost"))

        // Pass 5 electronic-path lessons
        let electronicPathIds = [13001, 13002, 13003, 14001, 14002]
        for id in electronicPathIds {
            progressStore.recordPass(lessonId: id)
        }

        XCTAssertEqual(progression.passedLessonCount(in: "electronic"), 5)
        XCTAssertTrue(progression.isCategoryUnlocked("ghost"), "Ghost must unlock after 5 electronic lessons passed")
    }

    // MARK: - Category Status and Localization

    func testCategoryProgressionStatusAndTitles() {
        let (progression, _, _) = makeIsolatedEnvironment()

        let firstStatus = progression.status(for: "eighth")
        XCTAssertTrue(firstStatus.isFirstCategory)
        XCTAssertTrue(firstStatus.isUnlocked)
        // Default language is English (DECISIONS §19)
        XCTAssertEqual(firstStatus.title, "Eighth-note grooves")

        // Test English titles
        XCTAssertEqual(progression.title(for: "eighth", language: .english), "Eighth-note grooves")
        XCTAssertEqual(progression.title(for: "sixteenth", language: .english), "Sixteenth-note grooves")
        XCTAssertEqual(progression.title(for: "electronic", language: .english), "Electronic styles")
        XCTAssertEqual(progression.title(for: "intro", language: .english), "Intro exercises")
    }
}
