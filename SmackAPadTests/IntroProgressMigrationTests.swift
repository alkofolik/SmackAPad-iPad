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
        original[6] = LessonProgress(hasPlayed: true, currentBpm: 72, bestScore: 0.4)
        let url = try progressFile(original)
        let store = ProgressStore(fileURL: url)
        for (removed, intro) in expectedMap {
            XCTAssertNil(store.progress(for: removed))
            XCTAssertEqual(store.progress(for: intro), original[removed])
        }
        XCTAssertEqual(store.progress(for: 6), original[6])
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
