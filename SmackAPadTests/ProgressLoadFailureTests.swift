import XCTest
import UIKit
@testable import SmackAPad

final class ProgressLoadFailureTests: XCTestCase {
    private func progressFile(_ data: Data? = nil) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProgressLoadFailure-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        try data?.write(to: url)
        return url
    }

    private func backups(for url: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url.deletingLastPathComponent(),
                                                  includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("progress.corrupt-") && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    func testCorruptFileLoadsEmptyAndKeepsOriginalBytesInOneBackup() throws {
        let original = Data("not json".utf8)
        let url = try progressFile(original)
        let store = ProgressStore(fileURL: url)
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(store.trainingLog, TrainingLog())
        XCTAssertNotNil(store.lastLoadError)
        let copies = try backups(for: url)
        XCTAssertEqual(copies.count, 1)
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(copies.first)), original)
        XCTAssertEqual(try Data(contentsOf: url), original)
    }

    func testFailedLoadBlocksExplicitAutomaticAndLifecycleSavesButKeepsChangesInMemory() throws {
        let original = Data("not json".utf8)
        let url = try progressFile(original)
        let store = ProgressStore(fileURL: url)
        store.setProgress(LessonProgress(passed: true), for: 10001)
        store.recordReviewRun(lessonId: 10001, passed: true, today: "2026-11-08")
        try store.save()
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.willTerminateNotification, object: nil)
        XCTAssertEqual(try Data(contentsOf: url), original)
        XCTAssertNotNil(store.lastLoadError)
        XCTAssertNil(store.lastSaveError)
        XCTAssertTrue(store.isPassed(lessonId: 10001))
        XCTAssertEqual(store.trainingLog.reviewsPassed, 1)
        XCTAssertEqual(try backups(for: url).count, 1)
    }

    func testStartingEmptyClearsUnsavedChangesAndUnblocksSavingWithoutRemovingBackup() throws {
        let original = Data("not json".utf8)
        let url = try progressFile(original)
        let store = ProgressStore(fileURL: url)
        let backup = try XCTUnwrap(backups(for: url).first)
        store.setProgress(LessonProgress(passed: true), for: 10001)
        store.recordReviewRun(lessonId: 10001, passed: true)
        try store.startWithEmptyProgress()
        XCTAssertNil(store.lastLoadError)
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(store.trainingLog, TrainingLog())
        try store.save()
        XCTAssertEqual(try JSONDecoder().decode(ProgressRoot.self, from: Data(contentsOf: url)), ProgressRoot())
        XCTAssertEqual(try Data(contentsOf: backup), original)
    }

    func testValidFileSavesNormallyWithoutBackup() throws {
        let root = ProgressRoot(lessons: [10001: LessonProgress(passed: true, currentBpm: 80)])
        let url = try progressFile(JSONEncoder().encode(root))
        let store = ProgressStore(fileURL: url)
        XCTAssertNil(store.lastLoadError)
        XCTAssertEqual(store.records, root.lessons)
        store.setProgress(LessonProgress(passed: true, currentBpm: 95), for: 10001)
        try store.save()
        XCTAssertEqual(ProgressStore(fileURL: url).records, store.records)
        XCTAssertTrue(try backups(for: url).isEmpty)
    }

    func testMissingFileStartsEmptyAndSaveCreatesFileWithoutBackup() throws {
        let url = try progressFile()
        let store = ProgressStore(fileURL: url)
        XCTAssertNil(store.lastLoadError)
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        try store.save()
        XCTAssertEqual(try JSONDecoder().decode(ProgressRoot.self, from: Data(contentsOf: url)), ProgressRoot())
        XCTAssertTrue(try backups(for: url).isEmpty)
    }

    func testRepeatedFailuresCreateDistinctCopiesAndKeepOnlyFiveNewest() throws {
        let url = try progressFile(Data("not json 0".utf8))
        let store = ProgressStore(fileURL: url)
        let first = try XCTUnwrap(backups(for: url).first)
        try Data("not json 1".utf8).write(to: url)
        store.load()
        let firstTwo = try backups(for: url)
        XCTAssertEqual(firstTwo.count, 2)
        XCTAssertEqual(try Data(contentsOf: first), Data("not json 0".utf8))
        XCTAssertEqual(try Data(contentsOf: XCTUnwrap(firstTwo.last)), Data("not json 1".utf8))
        for index in 2..<6 {
            try Data("not json \(index)".utf8).write(to: url)
            store.load()
        }
        let newest = try backups(for: url)
        XCTAssertEqual(newest.count, 5)
        XCTAssertFalse(FileManager.default.fileExists(atPath: first.path))
        for (index, copy) in newest.enumerated() {
            XCTAssertEqual(try Data(contentsOf: copy), Data("not json \(index + 1)".utf8))
        }
        XCTAssertEqual(try Data(contentsOf: url), Data("not json 5".utf8))
    }

    func testCurrentFormatGoldenFileWithThreeStarsAndTrainingLogRoundTripsUnchanged() throws {
        // Fixed current-format fixture, independent of the encoder used by save().
        let golden = Data("""
        {
          "afterMeLessons" : [
            10001
          ],
          "bounceBacks" : 2,
          "lessons" : {
            "10001" : {
              "bestScore" : 0.9375,
              "currentBpm" : 95,
              "hasPlayed" : true,
              "lastPlayedDay" : "2026-11-08",
              "lastReviewedDay" : "2026-11-08",
              "learningCreditByPadCount" : {

              },
              "mastery" : true,
              "masteryDay" : "2026-11-01",
              "memory" : true,
              "passed" : true,
              "reviewDueDay" : "2026-12-01",
              "reviewStep" : 2,
              "settled" : false
            }
          },
          "mixMemoryRounds" : 3,
          "mixRounds" : 5,
          "reviewsPassed" : 7,
          "trainingDays" : [
            "2026-11-01",
            "2026-11-08"
          ]
        }
        """.utf8)
        let url = try progressFile(golden)
        let store = ProgressStore(fileURL: url)
        XCTAssertNil(store.lastLoadError)
        let lesson = try XCTUnwrap(store.progress(for: 10001))
        XCTAssertTrue(lesson.passed && lesson.mastery && lesson.memory)
        XCTAssertEqual(store.trainingLog, TrainingLog(reviewsPassed: 7, bounceBacks: 2, mixRounds: 5,
                                                     mixMemoryRounds: 3, afterMeLessons: [10001],
                                                     trainingDays: ["2026-11-01", "2026-11-08"]))
        XCTAssertEqual(try Data(contentsOf: url), golden)
        try store.save()
        XCTAssertEqual(try Data(contentsOf: url), golden)
        XCTAssertTrue(try backups(for: url).isEmpty)
    }
}
