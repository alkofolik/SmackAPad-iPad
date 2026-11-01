import XCTest
@testable import SmackAPad

final class StageCompletionTests: XCTestCase {
    private struct Source: LessonContentSource {
        let sourceIdentifier = "two-star-tests"
        let lessons: [Lesson]
        func loadLessons() throws -> [Lesson] { lessons }
    }

    private func lessons(unplayableID: Int? = nil) -> [Lesson] {
        (1...11).map { id in
            Lesson(id: id, cat: id <= 10 ? "eighth" : "sixteenth", title: "Lesson \(id)", genre: "Rock",
                   tags: id <= 10 ? [] : ["16ths"], text: "", division: 16, bars: 1,
                   startBpm: 60, targetBpm: 100, level: 1, src: "Test",
                   hits: (0..<(id == unplayableID ? 9 : 1)).map { LessonHit(step: $0, padIndex: $0, hand: "R", velocity: 100) })
        }
    }

    private func environment(unplayableID: Int? = nil, oldProgress: [Int: LessonProgress] = [:]) -> ProgressionManager {
        let suite = "StageCompletionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: directory)
        }
        // Represents ticket 19's stage model, with no category migration still pending.
        defaults.set(true, forKey: "smackapad.settings.stageMigrationV1")
        let progress = ProgressStore(fileURL: directory.appendingPathComponent("progress.json"), autoLoad: false)
        for (id, record) in oldProgress { progress.setProgress(record, for: id, autoSave: false) }
        return ProgressionManager(lessonStore: LessonStore(sources: [Source(lessons: lessons(unplayableID: unplayableID))]),
                                  progressStore: progress, settingsManager: SettingsManager(userDefaults: defaults), userDefaults: defaults)
    }

    private func restored(_ manager: ProgressionManager) -> ProgressionManager {
        ProgressionManager(lessonStore: manager.lessonStore, progressStore: manager.progressStore,
                           settingsManager: manager.settingsManager, userDefaults: manager.userDefaults)
    }

    func testCompletionRequiresBothFirstAndSecondStarsAndIgnoresMemory() {
        let progress = environment().progressStore
        XCTAssertFalse(progress.isCompleted(lessonId: 99))
        for passed in [false, true] {
            for mastery in [false, true] {
                for memory in [false, true] {
                    progress.setProgress(LessonProgress(passed: passed, mastery: mastery, memory: memory), for: 1, autoSave: false)
                    XCTAssertEqual(progress.isCompleted(lessonId: 1), passed && mastery)
                }
            }
        }
    }

    func testFiveOneStarLessonsStayLockedAndFiveTwoStarLessonsOpen() {
        let manager = environment()
        let next = manager.catalog.stages[1]
        XCTAssertEqual(manager.unlockProgress(for: next).needed, 5)
        for id in 1...5 { manager.progressStore.recordPass(lessonId: id, autoSave: false) }
        XCTAssertEqual(manager.unlockProgress(for: next).completed, 0)
        XCTAssertFalse(manager.isStageOpen(next))
        for id in 1...4 { manager.progressStore.recordPass(lessonId: id, mastery: true, autoSave: false) }
        XCTAssertFalse(manager.isStageOpen(next))
        manager.progressStore.recordPass(lessonId: 5, mastery: true, autoSave: false)
        XCTAssertEqual(manager.unlockProgress(for: next).completed, 5)
        XCTAssertTrue(manager.isStageOpen(next))
        for id in 1...5 {
            manager.progressStore.setProgress(LessonProgress(passed: true, mastery: true, memory: true), for: id, autoSave: false)
        }
        XCTAssertEqual(manager.unlockProgress(for: next).completed, 5)
        XCTAssertEqual(manager.passedLessonCount(in: "eighth"), 5)
    }

    func testPreviouslyOneStarUnlockedStageSurvivesMigrationAndRestart() {
        let oldProgress = Dictionary(uniqueKeysWithValues: (1...5).map { ($0, LessonProgress(passed: true)) })
        let manager = environment(oldProgress: oldProgress)
        let stage = manager.catalog.stages[1]
        XCTAssertEqual(manager.unlockProgress(for: stage).completed, 0)
        XCTAssertTrue(manager.isStageOpen(stage))
        for id in 1...5 { manager.progressStore.setProgress(LessonProgress(), for: id, autoSave: false) }
        XCTAssertTrue(restored(manager).isStageOpen(stage))
    }

    func testNewlyOpenedStageStaysOpenAfterProgressChangesAndRestart() {
        let manager = environment()
        let stage = manager.catalog.stages[1]
        XCTAssertFalse(manager.isStageOpen(stage))
        for id in 1...5 { manager.progressStore.recordPass(lessonId: id, mastery: true, autoSave: false) }
        XCTAssertTrue(manager.isStageOpen(stage))
        for id in 1...5 { manager.progressStore.setProgress(LessonProgress(), for: id, autoSave: false) }
        XCTAssertTrue(restored(manager).isStageOpen(stage))
        manager.resetProgression()
        XCTAssertFalse(restored(manager).isStageOpen(stage))
    }

    func testEightPadModeExcludesCompletedLessonWithoutLayout() {
        let manager = environment(unplayableID: 10)
        manager.settingsManager.activeProfileName = ControllerProfile.standard8.profileName
        let stage = manager.catalog.stages[1]
        for id in [1, 2, 3, 4, 10] { manager.progressStore.recordPass(lessonId: id, mastery: true, autoSave: false) }
        XCTAssertEqual(manager.unlockProgress(for: stage).completed, 4)
        XCTAssertFalse(manager.isStageOpen(stage))
        manager.progressStore.recordPass(lessonId: 5, mastery: true, autoSave: false)
        XCTAssertTrue(manager.isStageOpen(stage))
    }

    func testSoftUnlockPlayedStageAndIntroStayAccessible() {
        let manager = environment()
        let stage = manager.catalog.stages[1]
        XCTAssertTrue(manager.isStageOpen(manager.catalog.stages[0]))
        XCTAssertTrue(manager.isIntroAccessible)
        XCTAssertTrue(manager.isCategoryUnlocked("intro"))
        manager.requestSoftUnlock(for: stage.id)
        manager.cancelSoftUnlock()
        XCTAssertFalse(manager.isStageOpen(stage))
        manager.requestSoftUnlock(for: stage.id)
        manager.confirmSoftUnlock()
        XCTAssertTrue(restored(manager).isStageOpen(stage))
        manager.resetProgression()
        manager.progressStore.setProgress(LessonProgress(hasPlayed: true), for: 11, autoSave: false)
        XCTAssertTrue(manager.isStageOpen(stage))
        XCTAssertEqual(manager.unlockProgress(for: stage).completed, 0)
    }

    func testInlineUnlockAndRelockRequireConfirmationAndPersistWithoutChangingProgress() {
        let manager = environment()
        let stage = manager.catalog.stages[1]
        let records = manager.progressStore.records
        manager.confirmStageAccessChange()
        XCTAssertFalse(manager.isStageOpen(stage))
        manager.requestStageAccessChange(for: stage.id, action: .unlock)
        XCTAssertEqual(manager.stageAccessConfirmation, StageAccessConfirmation(stageID: stage.id, action: .unlock))
        XCTAssertFalse(manager.isStageOpen(stage))
        manager.cancelStageAccessChange()
        manager.confirmStageAccessChange()
        XCTAssertFalse(manager.isStageOpen(stage))
        manager.requestStageAccessChange(for: stage.id, action: .unlock)
        manager.confirmStageAccessChange()
        let restarted = restored(manager)
        XCTAssertTrue(restarted.isStageOpen(stage))
        XCTAssertTrue(restarted.canRelockStage(stage))
        restarted.requestStageAccessChange(for: stage.id, action: .relock)
        XCTAssertTrue(restarted.isStageOpen(stage))
        restarted.cancelStageAccessChange()
        restarted.confirmStageAccessChange()
        XCTAssertTrue(restarted.isStageOpen(stage))
        restarted.requestStageAccessChange(for: stage.id, action: .relock)
        restarted.confirmStageAccessChange()
        XCTAssertFalse(restored(restarted).isStageOpen(stage))
        XCTAssertFalse(restarted.softUnlockedStages.contains(stage.id))
        XCTAssertEqual(restarted.progressStore.records, records)
        restarted.requestStageAccessChange(for: "intro", action: .relock)
        XCTAssertNil(restarted.stageAccessConfirmation)
        restarted.requestStageAccessChange(for: "unknown", action: .unlock)
        XCTAssertNil(restarted.stageAccessConfirmation)
    }

    func testRelockRejectsEveryStarAndPlayedAccessAndRechecksBeforeConfirmation() {
        for record in [LessonProgress(passed: true), LessonProgress(mastery: true),
                       LessonProgress(memory: true), LessonProgress(hasPlayed: true)] {
            let manager = environment()
            let stage = manager.catalog.stages[1]
            manager.softUnlock(category: stage.id)
            manager.requestStageAccessChange(for: stage.id, action: .relock)
            manager.progressStore.setProgress(record, for: 11, autoSave: false)
            XCTAssertFalse(manager.canRelockStage(stage))
            manager.confirmStageAccessChange()
            XCTAssertTrue(manager.softUnlockedStages.contains(stage.id))
            XCTAssertTrue(restored(manager).isStageOpen(stage))
            manager.requestStageAccessChange(for: stage.id, action: .relock)
            XCTAssertNil(manager.stageAccessConfirmation)
        }
    }

    func testNaturalAndMigrationSnapshotAccessCannotBeRelocked() {
        let manager = environment()
        let stage = manager.catalog.stages[1]
        let first = manager.catalog.stages[0]
        manager.softUnlock(category: first.id)
        XCTAssertFalse(manager.canRelockStage(first))
        manager.softUnlock(category: stage.id)
        manager.requestStageAccessChange(for: stage.id, action: .relock)
        for id in 1...5 { manager.progressStore.recordPass(lessonId: id, mastery: true, autoSave: false) }
        manager.confirmStageAccessChange()
        XCTAssertTrue(manager.softUnlockedStages.contains(stage.id))
        XCTAssertFalse(manager.canRelockStage(stage))
        for id in 1...5 { manager.progressStore.setProgress(LessonProgress(), for: id, autoSave: false) }
        XCTAssertFalse(restored(manager).canRelockStage(stage))

        let migrated = environment(oldProgress: Dictionary(uniqueKeysWithValues:
            (1...5).map { ($0, LessonProgress(passed: true)) }))
        let oldStage = migrated.catalog.stages[1]
        migrated.softUnlock(category: oldStage.id)
        XCTAssertFalse(migrated.canRelockStage(oldStage))
        migrated.requestStageAccessChange(for: oldStage.id, action: .relock)
        XCTAssertNil(migrated.stageAccessConfirmation)
    }

}
