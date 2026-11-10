#if DEBUG
import XCTest
@testable import SmackAPad

final class DebugScenarioTests: XCTestCase {
    @MainActor
    private func withProfile(
        _ action: (DebugSnapshotStore, URL, UserDefaults, String, UserDefaults, String) throws -> Void
    ) throws {
        let suite = "DebugScenarioTests.\(UUID().uuidString)"
        let testSuite = suite + ".test"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let testDefaults = try XCTUnwrap(UserDefaults(suiteName: testSuite))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            defaults.removePersistentDomain(forName: suite)
            testDefaults.removePersistentDomain(forName: testSuite)
            try? FileManager.default.removeItem(at: directory)
        }
        let progressURL = directory.appendingPathComponent("progress.json")
        let store = DebugSnapshotStore(progressURL: progressURL, defaults: defaults, domainName: suite,
                                       testDefaults: testDefaults, testDomainName: testSuite)
        try action(store, progressURL, defaults, suite, testDefaults, testSuite)
    }

    @MainActor
    func testSnapshotRoundTripPreservesExactProgressAndSettings() throws {
        try withProfile { store, progressURL, defaults, suite, testDefaults, testSuite in
            let progress = Data("{ \"lessons\" : {} }\n".utf8)
            try progress.write(to: progressURL)
            let settings: [String: Any] = [
                "smackapad.legend.shownOnce": true,
                "smackapad.settings.reviewReminderTime": Date(timeIntervalSince1970: 1000),
                "smackapad.badges": Data([1, 2, 3])
            ]
            defaults.setPersistentDomain(settings, forName: suite)
            try store.queueOverrides(DebugOverrides(access: .full, dayOffset: 7))
            try store.finishPendingChange()
            try store.capture(name: "My snapshot")
            XCTAssertEqual(try store.list(), ["My snapshot"])

            let testURL = DebugSnapshotStore.testProgressURL(for: progressURL)
            try FileManager.default.removeItem(at: testURL)
            testDefaults.setPersistentDomain([
                DebugSnapshotStore.activeKey: "Current profile copy",
                "smackapad.replaced": true,
                "other.preference": 42
            ], forName: testSuite)
            try store.apply(name: "My snapshot")

            XCTAssertEqual(try Data(contentsOf: testURL), progress)
            var expected = settings
            expected[DebugSnapshotStore.activeKey] = "My snapshot"
            expected[DebugOverrides.accessKey] = "full"
            expected[DebugOverrides.dayOffsetKey] = 7
            expected["other.preference"] = 42
            XCTAssertEqual(testDefaults.persistentDomain(forName: testSuite) as NSDictionary?, expected as NSDictionary)
            XCTAssertEqual(defaults.persistentDomain(forName: suite) as NSDictionary?, settings as NSDictionary)

            try store.delete(name: "My snapshot")
            XCTAssertEqual(try store.list(), [])
        }
    }

    @MainActor
    func testSwitchingScenariosRetainsFirstRealBackupAndRestoresIt() throws {
        try withProfile { store, progressURL, defaults, suite, testDefaults, _ in
            let catalog = LessonStore.shared.libraryCatalog
            let progress = Data("{ \"lessons\" : {} }\n".utf8)
            try progress.write(to: progressURL)
            let realSettings = ["smackapad.legend.shownOnce": true, "smackapad.practice.showPads": false]
            defaults.setPersistentDomain(realSettings, forName: suite)

            try store.queueScenario(.fresh, catalog: catalog, overrides: DebugOverrides(access: .free, dayOffset: -1))
            // The running app still sees its real state until the next launch.
            XCTAssertEqual(try Data(contentsOf: progressURL), progress)
            XCTAssertNil(store.activeScenario)
            try store.finishPendingChange()
            let testURL = DebugSnapshotStore.testProgressURL(for: progressURL)
            XCTAssertFalse(FileManager.default.fileExists(atPath: testURL.path))
            XCTAssertNil(testDefaults.object(forKey: "smackapad.legend.shownOnce"))
            XCTAssertEqual(store.activeScenario, "fresh")
            XCTAssertEqual(try Data(contentsOf: progressURL), progress)
            XCTAssertEqual(defaults.persistentDomain(forName: suite) as NSDictionary?, realSettings as NSDictionary)
            let backupURL = progressURL.deletingLastPathComponent().appendingPathComponent("DebugSnapshots/_real/state.plist")
            let backup = try Data(contentsOf: backupURL)

            try store.queueScenario(.introDone, catalog: catalog, overrides: DebugOverrides(access: .full, dayOffset: 1))
            try store.finishPendingChange()
            XCTAssertEqual(store.activeScenario, "introDone")
            XCTAssertNotEqual(try Data(contentsOf: testURL), progress)
            XCTAssertEqual(try Data(contentsOf: progressURL), progress)
            XCTAssertEqual(defaults.persistentDomain(forName: suite) as NSDictionary?, realSettings as NSDictionary)

            // A Release run can still write its real profile while the test profile is parked.
            let newerProgress = try JSONEncoder().encode(ProgressRoot(lessons: [1: LessonProgress(passed: true)]))
            try newerProgress.write(to: progressURL)
            defaults.set(true, forKey: "smackapad.practice.showPads")
            try store.queueRestore()
            try store.finishPendingChange()

            XCTAssertEqual(try Data(contentsOf: progressURL), newerProgress)
            XCTAssertTrue(defaults.bool(forKey: "smackapad.practice.showPads"))
            XCTAssertNil(store.activeScenario)
            XCTAssertEqual(store.overrides, DebugOverrides())
            XCTAssertFalse(FileManager.default.fileExists(atPath: testURL.path))
            XCTAssertEqual(try Data(contentsOf: backupURL), backup)
        }
    }

    @MainActor
    func testBuiltInScenariosUseTheCatalogAndNormalProgression() throws {
        try withProfile { store, progressURL, _, _, defaults, _ in
            let lessons = LessonStore.shared
            let catalog = lessons.libraryCatalog
            let firstStage = try XCTUnwrap(catalog.stages.first)
            let secondStage = try XCTUnwrap(catalog.stages.dropFirst().first)
            let today = AppCalendar.today()
            for scenario in DebugScenario.allCases {
                try store.queueScenario(scenario, catalog: catalog, overrides: DebugOverrides())
                try store.finishPendingChange()
                let progress = ProgressStore(fileURL: DebugSnapshotStore.testProgressURL(for: progressURL))
                XCTAssertNil(progress.lastLoadError)
                let records = progress.records
                let introIDs = Set(catalog.introLessons.map(\.id))

                switch scenario {
                case .fresh:
                    XCTAssertTrue(records.isEmpty)
                    XCTAssertNil(defaults.object(forKey: "smackapad.legend.shownOnce"))
                case .introDone:
                    XCTAssertEqual(Set(records.keys), introIDs)
                    XCTAssertTrue(records.values.allSatisfy { LibraryStarFilter.stars($0) == 2 })
                case .stage1Done:
                    XCTAssertEqual(Set(records.keys), introIDs.union(firstStage.lessons.map(\.id)))
                    XCTAssertTrue(records.values.allSatisfy { LibraryStarFilter.stars($0) == 2 })
                    let progression = ProgressionManager(lessonStore: lessons, progressStore: progress,
                        settingsManager: SettingsManager(userDefaults: defaults), userDefaults: defaults)
                    let unlock = progression.unlockProgress(for: secondStage)
                    XCTAssertGreaterThanOrEqual(unlock.completed, unlock.needed)
                    XCTAssertTrue(progression.isStageOpen(secondStage))
                case .awaitingStar3:
                    XCTAssertGreaterThanOrEqual(records.count, 3)
                    for record in records.values {
                        XCTAssertEqual(LibraryStarFilter.stars(record), 2)
                        let outcome = ReviewScheduler.evaluate(schedule: record.reviewSchedule, today: today,
                                                              isFullRun: true, fromMemory: true, bpm: 100,
                                                              targetBpm: 100, score: 0.92)
                        XCTAssertTrue(ReviewScheduler.mayEarnStar3(outcome: outcome, progress: record))
                    }
                case .reviewDueToday:
                    XCTAssertTrue((3...5).contains(records.count))
                    XCTAssertTrue(records.values.allSatisfy {
                        LibraryStarFilter.stars($0) == 3 && $0.reviewStep == 2 && $0.reviewDueDay == today
                            && $0.lastReviewedDay != nil && $0.reviewSchedule.isDueReview(on: today)
                    })
                case .advanced:
                    XCTAssertGreaterThan(catalog.path.filter { records[$0.id] != nil }.count, catalog.path.count / 2)
                    XCTAssertEqual(Set(records.values.map { LibraryStarFilter.stars($0) }), [2, 3])
                    XCTAssertTrue(records.values.contains { $0.reviewSchedule.isDue(on: today) })
                    XCTAssertTrue(records.values.contains { !$0.reviewSchedule.isDue(on: today) })
                    XCTAssertGreaterThan(BadgeStore(userDefaults: defaults).earnedCount, 0)
                }
            }
        }
    }

    func testDayOffsetChangesWhichReviewsAreDue() throws {
        let realDay = AppCalendar.today()
        let nextDay = try XCTUnwrap(AppCalendar.addingDays(1, to: realDay))
        let schedule = ReviewScheduler.initialSchedule(masteryDay: realDay)
        XCTAssertFalse(schedule.isDue(on: realDay))

        AppCalendar.useDebugDayOffset(1)
        defer { AppCalendar.useDebugDayOffset(0) }
        XCTAssertEqual(AppCalendar.today(), nextDay)
        XCTAssertTrue(schedule.isDue(on: AppCalendar.today()))
    }

    @MainActor
    func testPurchaseOverrideLocksAndUnlocksFullLesson() throws {
        let lesson = try XCTUnwrap(LessonStore.shared.lessons.first { $0.access == "full" })
        let store = StoreManager()
        store.debugAccessOverride = .free
        XCTAssertFalse(store.hasFullAccess)
        XCTAssertFalse(store.isUnlocked(lesson))
        store.debugAccessOverride = .full
        XCTAssertTrue(store.hasFullAccess)
        XCTAssertTrue(store.isUnlocked(lesson))
    }
}
#endif
