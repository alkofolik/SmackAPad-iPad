import XCTest
@testable import SmackAPad

final class LearningCreditPersistenceTests: XCTestCase {
    func testLearningCreditSurvivesSaveLoadSeparatelyForLessonsAndPadModes() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ticket-28-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let store = ProgressStore(fileURL: url, autoLoad: false)
        var credit = StarStreak()
        _ = credit.record(passed: true, mastery: true, memory: false, requiredRuns: 4)
        _ = credit.record(passed: false, mastery: false, memory: false, requiredRuns: 4)
        store.setLearningCredit(credit, lessonId: 10001, padCount: 8)
        let loaded = ProgressStore(fileURL: url)
        XCTAssertNil(loaded.lastLoadError)
        XCTAssertEqual(loaded.learningCredit(lessonId: 10001, padCount: 8).passedRuns, 1)
        XCTAssertEqual(loaded.learningCredit(lessonId: 10001, padCount: 8).masteryRuns, 1)
        XCTAssertEqual(loaded.learningCredit(lessonId: 10001, padCount: 16).passedRuns, 0)
        XCTAssertEqual(loaded.learningCredit(lessonId: 10002, padCount: 8).passedRuns, 0)
        loaded.setLearningCredit(credit, lessonId: 10001, padCount: 16)
        let reloaded = ProgressStore(fileURL: url)
        XCTAssertEqual(reloaded.learningCredit(lessonId: 10001, padCount: 8).passedRuns, 1)
        XCTAssertEqual(reloaded.learningCredit(lessonId: 10001, padCount: 16).passedRuns, 1)
        // Files created before Learning credit keep existing stars and start counters at zero.
        let oldJSON = #"{"10001":{"passed":true,"mastery":false,"currentBpm":80,"bestScore":0.9}}"#
        try Data(oldJSON.utf8).write(to: url)
        let migrated = ProgressStore(fileURL: url)
        XCTAssertNil(migrated.lastLoadError)
        XCTAssertTrue(migrated.isPassed(lessonId: 10001))
        XCTAssertEqual(migrated.learningCredit(lessonId: 10001, padCount: 8).passedRuns, 0)
    }
}
