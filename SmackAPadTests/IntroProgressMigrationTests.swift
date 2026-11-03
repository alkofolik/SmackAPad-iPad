import XCTest
@testable import SmackAPad

final class IntroProgressMigrationTests: XCTestCase {
    private func progressFile(_ records: [Int: LessonProgress]) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("IntroMigration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let keyed = Dictionary(uniqueKeysWithValues: records.map { (String($0.key), $0.value) })
        try JSONEncoder().encode(keyed).write(to: url)
        return url
    }

    func testEveryRemovedRecordMovesToItsSpecifiedIntroLessonAndKeepsLessonSix() throws {
        let expectedMap = [1: 10001, 2: 10015, 3: 10008, 4: 10010, 5: 10011, 7: 10016, 8: 10013, 9: 10014]
        XCTAssertEqual(ProgressStore.duplicateIntroLessonMap, expectedMap)
        var original = Dictionary(uniqueKeysWithValues: expectedMap.keys.map { id in
            (id, LessonProgress(passed: true, mastery: true, memory: true, currentBpm: 60 + id, bestScore: 0.9))
        })
        original[6] = LessonProgress(passed: true, mastery: true, memory: true, currentBpm: 100, bestScore: 0.94)
        let url = try progressFile(original)
        let store = ProgressStore(fileURL: url)
        for (removed, intro) in expectedMap {
            XCTAssertNil(store.progress(for: removed))
            XCTAssertEqual(store.progress(for: intro), original[removed])
        }
        XCTAssertEqual(store.progress(for: 6), original[6])
        let introLesson = try XCTUnwrap(LessonStore.shared.libraryCatalog.introLessons.first { $0.id == 6 })
        XCTAssertEqual(introLesson.cat, "intro")
        XCTAssertTrue(store.progress(for: introLesson.id)?.memory == true)
        XCTAssertEqual(store.records.count, 9)
        XCTAssertNil(store.lastLoadError)
        XCTAssertNil(store.lastSaveError)
        let persisted = ProgressStore(fileURL: url)
        XCTAssertEqual(persisted.records, store.records)
    }

    func testFlagsAreOrMergedAndMissingTargetTempoUsesSource() throws {
        let source = LessonProgress(passed: true, memory: true, currentBpm: 95, bestScore: 0.9)
        let target = LessonProgress(mastery: true, currentBpm: 0, bestScore: 0.7)
        let store = ProgressStore(fileURL: try progressFile([3: source, 10008: target]))
        let merged = try XCTUnwrap(store.progress(for: 10008))
        XCTAssertTrue(merged.passed)
        XCTAssertTrue(merged.mastery)
        XCTAssertTrue(merged.memory)
        XCTAssertTrue(merged.hasPlayed)
        XCTAssertEqual(merged.bestScore, 0.9)
        XCTAssertEqual(merged.currentBpm, 95)
        XCTAssertNil(store.progress(for: 3))
    }

    func testExistingTargetStarsScoreAndTempoAreNeverLowered() throws {
        let source = LessonProgress(hasPlayed: true, currentBpm: 130, bestScore: 0.2)
        let target = LessonProgress(passed: true, mastery: true, memory: true, currentBpm: 100, bestScore: 0.98)
        let store = ProgressStore(fileURL: try progressFile([5: source, 10011: target]))
        XCTAssertEqual(store.progress(for: 10011), target)
        XCTAssertNil(store.progress(for: 5))
    }

    func testSecondLoadChangesNeitherRecordsNorPersistedFile() throws {
        let url = try progressFile([1: LessonProgress(passed: true, currentBpm: 80, bestScore: 0.8)])
        let store = ProgressStore(fileURL: url)
        let firstRecords = store.records
        let firstData = try Data(contentsOf: url)
        store.load()
        XCTAssertEqual(store.records, firstRecords)
        XCTAssertEqual(try Data(contentsOf: url), firstData)
        XCTAssertEqual(ProgressStore(fileURL: url).records, firstRecords)
    }

    func testUserWithoutRetiredRecordsIsUntouched() throws {
        let original = [6: LessonProgress(hasPlayed: true, currentBpm: 70),
                        10008: LessonProgress(passed: true, currentBpm: 90, bestScore: 0.75)]
        let url = try progressFile(original)
        let originalData = try Data(contentsOf: url)
        let store = ProgressStore(fileURL: url)
        XCTAssertEqual(store.records, original)
        XCTAssertEqual(try Data(contentsOf: url), originalData)
        XCTAssertNil(store.lastSaveError)
    }
}

#if DEBUG
import XCTest
@testable import SmackAPad

final class LegacyProgressImportTests: XCTestCase {
    private func backup(_ body: String, app: String = "padwork", version: Int = 1) -> Data {
        Data("""
        {"app":"\(app)","formatVersion":\(version),\(body)}
        """.utf8)
    }

    func testMapsRetiredIDAndMemoryOnlyWithoutImportingUnstarredLessons() throws {
        let mapped = try LegacyProgressImport.map(backup("""
        "rewards":{"stars":{
          "1":{"passed":true,"mastered":true},
          "10002":{"memory":"2026-10-30T12:00:00Z"},
          "10003":{"passed":false,"mastered":false}
        }},
        "progress":{"1":{"bpm":95,"best":87},"10004":{"bpm":120,"best":99}},
        "unlockedStages":["L1-ghost"]
        """))
        XCTAssertEqual(mapped.count, 2)
        XCTAssertNil(mapped[1])
        XCTAssertEqual(mapped[10001], LessonProgress(passed: true, mastery: true, hasPlayed: true,
                                                    currentBpm: 95, bestScore: 0.87))
        XCTAssertEqual(mapped[10002], LessonProgress(memory: true, hasPlayed: true))
        XCTAssertNil(mapped[10003])
        XCTAssertNil(mapped[10004])
    }

    func testMergeNeverLowersProgressAndIsIdempotent() throws {
        let imported = try LegacyProgressImport.map(backup("""
        "rewards":{"stars":{"1":{"passed":true,"memory":"2026-10-30T12:00:00Z"}}},
        "progress":{"1":{"bpm":120,"best":75}}
        """))
        let existing = [10001: LessonProgress(mastery: true, currentBpm: 80, bestScore: 0.95),
                        10002: LessonProgress(passed: true)]
        let merged = LegacyProgressImport.merge(existing: existing, imported: imported)
        XCTAssertEqual(merged[10001], LessonProgress(passed: true, mastery: true, memory: true,
                                                    hasPlayed: true, currentBpm: 80, bestScore: 0.95))
        XCTAssertEqual(merged[10002], existing[10002])
        XCTAssertEqual(LegacyProgressImport.merge(existing: merged, imported: imported), merged)
    }

    func testRejectsWrongAppVersionAndMissingStars() {
        for data in [backup("\"rewards\":{\"stars\":{}}", app: "other"),
                     backup("\"rewards\":{\"stars\":{}}", version: 2),
                     backup("\"rewards\":{}"), Data("invalid".utf8)] {
            XCTAssertThrowsError(try LegacyProgressImport.map(data))
        }
    }

    func testBackupAndRepeatedImportPreserveOriginalFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = ProgressStore(fileURL: url, autoLoad: false)
        store.setProgress(LessonProgress(mastery: true, currentBpm: 90), for: 10001, autoSave: false)
        try store.save()
        let original = try Data(contentsOf: url)
        let data = backup("""
        "rewards":{"stars":{"1":{"passed":true,"memory":"2026-10-30T12:00:00Z"}}}
        """)
        let first = try store.importLegacyBackup(data)
        XCTAssertEqual(first.lessons, 1)
        XCTAssertEqual(first.starsAdded, 2)
        let imported = store.records
        XCTAssertEqual(try store.importLegacyBackup(data).starsAdded, 0)
        XCTAssertEqual(store.records, imported)
        XCTAssertEqual(try Data(contentsOf: url.appendingPathExtension("pre-import")), original)
        let saved = try Data(contentsOf: url)
        XCTAssertThrowsError(try store.importLegacyBackup(Data("{}".utf8)))
        XCTAssertEqual(store.records, imported)
        XCTAssertEqual(try Data(contentsOf: url), saved)
    }
}
#endif
