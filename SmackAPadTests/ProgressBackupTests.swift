import XCTest
@testable import SmackAPad

final class ProgressBackupTests: XCTestCase {

    override func setUp() {
        super.setUp()
        BadgeStore.shared.resetAll()
        SettingsManager.shared.resetToDefaults()
    }

    override func tearDown() {
        BadgeStore.shared.resetAll()
        SettingsManager.shared.resetToDefaults()
        super.tearDown()
    }

    private func createTempDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("ProgressBackupTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        return tempDir
    }

    private func cleanupDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Test 1: Export -> Delete (fresh state) -> Import round-trip

    func testExportDeleteImportRoundTrip() throws {
        let tempDir = try createTempDirectory()
        defer { cleanupDirectory(tempDir) }

        let progressURL = tempDir.appendingPathComponent("progress.json")
        let progressStore = ProgressStore(fileURL: progressURL)

        // Populate initial progress
        progressStore.recordResult(
            lessonId: 10001,
            passed: true,
            mastery: true,
            bpm: 105,
            score: 0.92,
            memory: true,
            today: "2026-11-08"
        )
        progressStore.recordReviewRun(lessonId: 10001, passed: true, today: "2026-11-09")

        // Populate badges
        let earnedDate = Date(timeIntervalSince1970: 1700000000)
        BadgeStore.shared.importBadges(["intro-graduate": earnedDate])

        // Populate settings
        SettingsManager.shared.selectedKitId = "808"
        SettingsManager.shared.bpmStep = 2
        SettingsManager.shared.padsVolume = 85

        // Export data
        let exportedData = try progressStore.exportData()
        let envelope = try ProgressBackup.decode(from: exportedData)
        XCTAssertEqual(envelope.app, "smack-a-pad")
        XCTAssertEqual(envelope.formatVersion, 1)
        XCTAssertEqual(envelope.progress[10001]?.passed, true)
        XCTAssertEqual(envelope.progress[10001]?.mastery, true)
        XCTAssertEqual(envelope.progress[10001]?.memory, true)
        XCTAssertEqual(envelope.progress[10001]?.currentBpm, 105)
        XCTAssertEqual(envelope.badges["intro-graduate"], earnedDate)
        XCTAssertEqual(envelope.settings.selectedKitId, "808")
        XCTAssertEqual(envelope.settings.bpmStep, 2)
        XCTAssertEqual(envelope.settings.padsVolume, 85)

        // Clear everything (simulate fresh install / app deletion)
        try progressStore.resetAll(deleteFile: true)
        BadgeStore.shared.resetAll()
        SettingsManager.shared.resetToDefaults()

        XCTAssertTrue(ProgressMerge.isFreshDevice(
            records: progressStore.records,
            trainingLog: progressStore.trainingLog,
            earnedBadgesCount: BadgeStore.shared.earnedCount
        ))

        // Import backup
        let result = try progressStore.importFromData(exportedData)
        XCTAssertTrue(result.isFreshDevice)
        XCTAssertGreaterThanOrEqual(result.updatedLessonsCount, 1)

        // Verify restoration
        let restoredLesson = try XCTUnwrap(progressStore.progress(for: 10001))
        XCTAssertTrue(restoredLesson.passed)
        XCTAssertTrue(restoredLesson.mastery)
        XCTAssertTrue(restoredLesson.memory)
        XCTAssertEqual(restoredLesson.currentBpm, 105)
        XCTAssertEqual(restoredLesson.bestScore, 0.92)

        XCTAssertTrue(BadgeStore.shared.isEarned(badgeId: "intro-graduate"))
        XCTAssertEqual(BadgeStore.shared.earnedDate(for: "intro-graduate"), earnedDate)

        XCTAssertEqual(SettingsManager.shared.selectedKitId, "808")
        XCTAssertEqual(SettingsManager.shared.bpmStep, 2)
        XCTAssertEqual(SettingsManager.shared.padsVolume, 85)
    }

    // MARK: - Test 2: Old backup over newer progress loses nothing

    func testOldBackupOverNewerProgressLosesNothing() {
        var newerLocal = LessonProgress(
            passed: true,
            mastery: true,
            memory: true,
            currentBpm: 120,
            bestScore: 0.98,
            lastPlayedDay: "2026-11-10",
            masteryDay: "2026-11-05",
            reviewStep: 4,
            reviewDueDay: nil,
            settled: true,
            lastReviewedDay: "2026-11-10"
        )
        newerLocal.modifiedAt = Date(timeIntervalSince1970: 1700020000)

        var olderIncoming = LessonProgress(
            passed: true,
            mastery: false,
            memory: false,
            currentBpm: 80,
            bestScore: 0.75,
            lastPlayedDay: "2026-11-01",
            masteryDay: nil,
            reviewStep: 0,
            reviewDueDay: nil,
            settled: false,
            lastReviewedDay: nil
        )
        olderIncoming.modifiedAt = Date(timeIntervalSince1970: 1700000000)

        let merged = ProgressMerge.mergeLesson(local: newerLocal, incoming: olderIncoming)

        // Local newer achievements are completely preserved
        XCTAssertTrue(merged.passed)
        XCTAssertTrue(merged.mastery)
        XCTAssertTrue(merged.memory)
        XCTAssertEqual(merged.currentBpm, 120)
        XCTAssertEqual(merged.bestScore, 0.98)
        XCTAssertEqual(merged.lastPlayedDay, "2026-11-10")
        XCTAssertEqual(merged.masteryDay, "2026-11-05")
        XCTAssertEqual(merged.settled, true)
        XCTAssertEqual(merged.lastReviewedDay, "2026-11-10")
        XCTAssertNil(merged.reviewDueDay)
    }

    // MARK: - Test 3: Newer backup over older progress applies upgrades

    func testNewerBackupOverOlderProgressAppliesUpgrades() {
        let olderLocal = LessonProgress(
            passed: true,
            mastery: false,
            memory: false,
            currentBpm: 75,
            bestScore: 0.72,
            lastPlayedDay: "2026-11-02",
            masteryDay: nil
        )

        let newerIncoming = LessonProgress(
            passed: true,
            mastery: true,
            memory: false,
            currentBpm: 95,
            bestScore: 0.88,
            lastPlayedDay: "2026-11-09",
            masteryDay: "2026-11-09",
            reviewStep: 1,
            reviewDueDay: "2026-11-10",
            settled: false,
            lastReviewedDay: "2026-11-09"
        )

        let merged = ProgressMerge.mergeLesson(local: olderLocal, incoming: newerIncoming)

        XCTAssertTrue(merged.passed)
        XCTAssertTrue(merged.mastery)
        XCTAssertFalse(merged.memory)
        XCTAssertEqual(merged.currentBpm, 95)
        XCTAssertEqual(merged.bestScore, 0.88)
        XCTAssertEqual(merged.lastPlayedDay, "2026-11-09")
        XCTAssertEqual(merged.masteryDay, "2026-11-09")
        XCTAssertEqual(merged.reviewStep, 1)
        XCTAssertEqual(merged.reviewDueDay, "2026-11-10")
        XCTAssertEqual(merged.lastReviewedDay, "2026-11-09")
    }

    // MARK: - Test 4: Divergent states combine stars, idempotent and commutative

    func testTwoDivergentStatesBothKeepStarsIdempotentAndCommutative() {
        let stateA = LessonProgress(
            passed: true,
            mastery: true,
            memory: false,
            currentBpm: 90,
            bestScore: 0.85
        )

        let stateB = LessonProgress(
            passed: true,
            mastery: false,
            memory: true,
            currentBpm: 85,
            bestScore: 0.82
        )

        let mergedAB = ProgressMerge.mergeLesson(local: stateA, incoming: stateB)
        let mergedBA = ProgressMerge.mergeLesson(local: stateB, incoming: stateA)

        // Has all stars
        XCTAssertTrue(mergedAB.passed)
        XCTAssertTrue(mergedAB.mastery)
        XCTAssertTrue(mergedAB.memory)
        XCTAssertEqual(mergedAB.bestScore, 0.85)

        // Commutativity for stars and best score
        XCTAssertEqual(mergedAB.passed, mergedBA.passed)
        XCTAssertEqual(mergedAB.mastery, mergedBA.mastery)
        XCTAssertEqual(mergedAB.memory, mergedBA.memory)
        XCTAssertEqual(mergedAB.bestScore, mergedBA.bestScore)

        // Idempotency: merge(A, merge(A, B)) == merge(A, B)
        let mergedTwice = ProgressMerge.mergeLesson(local: stateA, incoming: mergedAB)
        XCTAssertEqual(mergedAB, mergedTwice)
    }

    // MARK: - Test 5: Review schedule taken as a whole group

    func testReviewScheduleTakenAsWholeGroupValidForReviewScheduler() {
        // Record 1: Step 2, due on 2026-11-15, reviewed on 2026-11-08
        let record1 = LessonProgress(
            reviewStep: 2,
            reviewDueDay: "2026-11-15",
            settled: false,
            lastReviewedDay: "2026-11-08"
        )

        // Record 2: Step 1, due on 2026-11-05, reviewed on 2026-11-04
        let record2 = LessonProgress(
            reviewStep: 1,
            reviewDueDay: "2026-11-05",
            settled: false,
            lastReviewedDay: "2026-11-04"
        )

        let scheduleMerged = ProgressMerge.mergeReviewSchedule(local: record1, incoming: record2)
        // Record 1 was reviewed later (2026-11-08 > 2026-11-04), so its entire schedule is chosen
        XCTAssertEqual(scheduleMerged.reviewStep, 2)
        XCTAssertEqual(scheduleMerged.reviewDueDay, "2026-11-15")
        XCTAssertEqual(scheduleMerged.lastReviewedDay, "2026-11-08")
        XCTAssertFalse(scheduleMerged.isSettled)

        // Settled record vs unsettled record
        let settledRecord = LessonProgress(
            reviewStep: 4,
            reviewDueDay: nil,
            settled: true,
            lastReviewedDay: "2026-11-07"
        )
        let settledMerged = ProgressMerge.mergeReviewSchedule(local: record2, incoming: settledRecord)
        XCTAssertTrue(settledMerged.isSettled)
        XCTAssertNil(settledMerged.reviewDueDay)
    }

    // MARK: - Test 6: Settings replaced on fresh device, kept on device with progress; calibration offsets never exported

    func testSettingsReplacedOnFreshDeviceKeptOnDeviceWithProgress() throws {
        let tempDir = try createTempDirectory()
        defer { cleanupDirectory(tempDir) }

        let progressURL = tempDir.appendingPathComponent("progress.json")
        let progressStore = ProgressStore(fileURL: progressURL)

        // Ensure calibration offsets are set locally
        SettingsManager.shared.calibrationOffsets = ["speaker": 15.0, "bluetooth": 80.0]
        SettingsManager.shared.selectedKitId = "acoustic"

        let backupEnvelope = ProgressBackupEnvelope(
            progress: [10001: LessonProgress(passed: true)],
            settings: BackupSettings(selectedKitId: "electronic", metronomeVolume: 50)
        )

        // On a fresh device, settings are replaced
        XCTAssertTrue(ProgressMerge.isFreshDevice(
            records: progressStore.records,
            trainingLog: progressStore.trainingLog,
            earnedBadgesCount: BadgeStore.shared.earnedCount
        ))

        _ = try progressStore.importEnvelope(backupEnvelope)
        XCTAssertEqual(SettingsManager.shared.selectedKitId, "electronic")
        XCTAssertEqual(SettingsManager.shared.metronomeVolume, 50)

        // Calibration offsets must remain unchanged
        XCTAssertEqual(SettingsManager.shared.calibrationOffsets["speaker"], 15.0)

        // Now device has progress (10001 is passed)
        XCTAssertFalse(ProgressMerge.isFreshDevice(
            records: progressStore.records,
            trainingLog: progressStore.trainingLog,
            earnedBadgesCount: BadgeStore.shared.earnedCount
        ))

        // Re-configure local settings
        SettingsManager.shared.selectedKitId = "jazz"
        SettingsManager.shared.metronomeVolume = 90

        // Import another backup with different settings
        let secondBackup = ProgressBackupEnvelope(
            progress: [10002: LessonProgress(passed: true)],
            settings: BackupSettings(selectedKitId: "808", metronomeVolume: 30)
        )
        _ = try progressStore.importEnvelope(secondBackup)

        // Because device already had progress, local settings are KEPT
        XCTAssertEqual(SettingsManager.shared.selectedKitId, "jazz")
        XCTAssertEqual(SettingsManager.shared.metronomeVolume, 90)
    }

    // MARK: - Test 7: Current format without new fields and legacy flat format load unchanged

    func testLegacyAndCurrentProgressFormatsLoadUnchanged() throws {
        let tempDir = try createTempDirectory()
        defer { cleanupDirectory(tempDir) }

        // 1. Current format progress.json without formatVersion and without modifiedAt
        let currentFormatJSON = """
        {
          "lessons": {
            "10001": {
              "passed": true,
              "mastery": true,
              "memory": false,
              "currentBpm": 100,
              "bestScore": 0.88,
              "hasPlayed": true
            }
          },
          "trainingLog": {
            "reviewsPassed": 5,
            "bounceBacks": 1,
            "mixRounds": 2,
            "mixMemoryRounds": 1,
            "afterMeLessons": [10001],
            "trainingDays": ["2026-11-09"]
          }
        }
        """.data(using: .utf8)!

        let currentURL = tempDir.appendingPathComponent("current.json")
        try currentFormatJSON.write(to: currentURL)

        let store1 = ProgressStore(fileURL: currentURL)
        XCTAssertTrue(store1.loadedSuccessfully)
        XCTAssertEqual(store1.progress(for: 10001)?.passed, true)
        XCTAssertEqual(store1.progress(for: 10001)?.currentBpm, 100)
        XCTAssertEqual(store1.trainingLog.reviewsPassed, 5)

        // 2. Legacy flat dictionary format
        let flatFormatJSON = """
        {
          "10001": {
            "passed": true,
            "mastery": false,
            "currentBpm": 85,
            "bestScore": 0.76
          }
        }
        """.data(using: .utf8)!

        let flatURL = tempDir.appendingPathComponent("flat.json")
        try flatFormatJSON.write(to: flatURL)

        let store2 = ProgressStore(fileURL: flatURL)
        XCTAssertTrue(store2.loadedSuccessfully)
        XCTAssertEqual(store2.progress(for: 10001)?.passed, true)
        XCTAssertEqual(store2.progress(for: 10001)?.currentBpm, 85)
    }

    // MARK: - Test 8: Unknown higher formatVersion and invalid JSON refused, disk unchanged

    func testUnknownHigherFormatVersionAndInvalidJSONRefusedDiskUnchanged() throws {
        let tempDir = try createTempDirectory()
        defer { cleanupDirectory(tempDir) }

        let progressURL = tempDir.appendingPathComponent("progress.json")
        let progressStore = ProgressStore(fileURL: progressURL)
        progressStore.recordResult(lessonId: 10001, passed: true, mastery: true, bpm: 90, score: 0.85)
        try progressStore.save()

        let initialDataOnDisk = try Data(contentsOf: progressURL)

        // 1. Unknown higher formatVersion
        let futureJSON = """
        {
          "app": "smack-a-pad",
          "formatVersion": 99,
          "exportedAt": "2026-11-10T12:00:00Z",
          "progress": {}
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try progressStore.importFromData(futureJSON)) { error in
            guard case ProgressBackupError.newerVersion(let version) = error else {
                XCTFail("Expected newerVersion error, got \(error)")
                return
            }
            XCTAssertEqual(version, 99)
        }

        let diskAfterFuture = try Data(contentsOf: progressURL)
        XCTAssertEqual(initialDataOnDisk, diskAfterFuture)

        // 2. Arbitrary non-backup JSON
        let nonBackupJSON = """
        {
          "hello": "world",
          "foo": "bar"
        }
        """.data(using: .utf8)!

        XCTAssertThrowsError(try progressStore.importFromData(nonBackupJSON)) { error in
            guard case ProgressBackupError.invalidEnvelope = error else {
                XCTFail("Expected invalidEnvelope error, got \(error)")
                return
            }
        }

        let diskAfterInvalid = try Data(contentsOf: progressURL)
        XCTAssertEqual(initialDataOnDisk, diskAfterInvalid)
    }

    // MARK: - Test 9: Pre-import backup written and pruned to 5

    func testPreImportBackupWrittenAndPrunedToFive() throws {
        let tempDir = try createTempDirectory()
        defer { cleanupDirectory(tempDir) }

        let backupsDir = tempDir.appendingPathComponent("Backups")
        let envelope = ProgressBackupEnvelope(progress: [10001: LessonProgress(passed: true)])

        // Create 8 backups with distinct dates
        let baseDate = Date(timeIntervalSince1970: 1700000000)
        for i in 0..<8 {
            let date = baseDate.addingTimeInterval(TimeInterval(i * 10))
            try BackupStorage.createPreImportBackup(envelope: envelope, directory: backupsDir, date: date)
        }

        let files = try FileManager.default.contentsOfDirectory(at: backupsDir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("before-import-") }

        XCTAssertEqual(files.count, 5, "Pre-import backups must be pruned to exactly 5")
    }

    // MARK: - Test 10: Daily rolling auto-backup pruned to 3

    func testDailyRollingAutoBackupPrunedToThree() throws {
        let tempDir = try createTempDirectory()
        defer { cleanupDirectory(tempDir) }

        let backupsDir = tempDir.appendingPathComponent("Backups")
        let envelope = ProgressBackupEnvelope(progress: [10001: LessonProgress(passed: true)])

        // Record for 5 different calendar days
        let days = ["2026-11-01", "2026-11-02", "2026-11-03", "2026-11-04", "2026-11-05"]
        for day in days {
            try BackupStorage.recordDailyAutoBackupIfNeeded(envelope: envelope, today: day, directory: backupsDir)
        }

        let files = try FileManager.default.contentsOfDirectory(at: backupsDir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("auto-") }

        XCTAssertEqual(files.count, 3, "Auto daily backups must be pruned to exactly 3")
        let remainingNames = files.map(\.lastPathComponent).sorted()
        XCTAssertEqual(remainingNames, ["auto-2026-11-03.json", "auto-2026-11-04.json", "auto-2026-11-05.json"])
    }

    // MARK: - Ticket 195: showPadKeys removed from backup

    func testBackupContainingShowPadKeysDecodesWithoutError() throws {
        let envelope = ProgressBackupEnvelope()
        let data = try ProgressBackup.encode(envelope: envelope)
        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        var settings = json["settings"] as? [String: Any] ?? [:]
        settings["showPadKeys"] = true
        json["settings"] = settings
        let modifiedData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try ProgressBackup.decode(from: modifiedData)
        XCTAssertEqual(decoded.app, "smack-a-pad")
        XCTAssertEqual(decoded.formatVersion, 1)
    }

    func testNewlyEncodedBackupContainsNoShowPadKeysKey() throws {
        let envelope = ProgressBackupEnvelope()
        let data = try ProgressBackup.encode(envelope: envelope)
        let jsonString = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(jsonString.contains("showPadKeys"), "Newly encoded backup must not contain showPadKeys")
    }
}
