import AVFoundation
import Darwin
import XCTest
@testable import SmackAPad

final class TrainingLogAndBadgesTests: XCTestCase {
    func testPassFailPassOnConsecutiveDaysGivesOneBounceBack() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let fileURL = tempDir.appendingPathComponent("progress.json")
        let store = ProgressStore(fileURL: fileURL, autoLoad: false)

        let lessonId = 10001
        // Day 1: Pass review
        store.recordReviewRun(lessonId: lessonId, passed: true, today: "2026-11-05")
        XCTAssertEqual(store.trainingLog.reviewsPassed, 1)
        XCTAssertEqual(store.trainingLog.bounceBacks, 0)
        XCTAssertNil(store.progress(for: lessonId)?.lastReviewFailDay)

        // Day 2: Fail review
        store.recordReviewRun(lessonId: lessonId, passed: false, today: "2026-11-06")
        XCTAssertEqual(store.trainingLog.reviewsPassed, 1)
        XCTAssertEqual(store.trainingLog.bounceBacks, 0)
        XCTAssertEqual(store.progress(for: lessonId)?.lastReviewFailDay, "2026-11-06")

        // Day 3: Pass review on consecutive day -> gives one bounce-back!
        store.recordReviewRun(lessonId: lessonId, passed: true, today: "2026-11-07")
        XCTAssertEqual(store.trainingLog.reviewsPassed, 2)
        XCTAssertEqual(store.trainingLog.bounceBacks, 1)
        XCTAssertNil(store.progress(for: lessonId)?.lastReviewFailDay)
    }

    @MainActor
    func testMixRoundWithOneShownPassIsNotAMemoryRound() async throws {
        let suite = "mix-memory-test-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        settings.fadeMemoryNotes = true // Passes 1-2 show notes (fading hints), so pass 1 is shown

        let hits = stride(from: 0, to: 64, by: 4).map {
            LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100)
        }
        let first = Lesson(id: 61_001, cat: "test", title: "First", genre: "Rock", tags: [],
            text: "", division: 16, bars: 4, startBpm: 120, targetBpm: 120, level: 1,
            src: "Test", hits: hits)
        let second = Lesson(id: 61_002, cat: "test", title: "Second", genre: "Jazz", tags: [],
            text: "", division: 16, bars: 4, startBpm: 120, targetBpm: 120, level: 1,
            src: "Test", hits: hits)

        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)

        let midi = MIDIInput(settings: settings)
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(
            lesson: first,
            settings: settings,
            progress: progress,
            midi: midi,
            initialFromMemory: true, // From memory requested
            initialBpm: 120,
            mixLessons: [first, second],
            clock: { time },
            currentDay: { "2026-11-05" }
        )
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready)

        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let startFirst = time + 0.6 + 2 // 4 count-in beats at 120 BPM = 2s
        session.start()

        // Play first lesson hits (100% score, but pass 1 with fadeMemoryNotes on is SHOWN, not hidden)
        for hit in hits {
            time = startFirst + Double(hit.step) * 15 / 120
            session.tick()
            midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
        }
        time = startFirst + 8.01 // 4 bars at 120 BPM = 8s
        await session.tick()?.value

        XCTAssertEqual(session.lesson.id, second.id)

        // Advance into second lesson (4 count-in beats at 120 BPM = 2s, anchor offset 0.6s)
        let startSecond = time + 0.6 + 2
        for hit in hits {
            time = startSecond + Double(hit.step) * 15 / 120
            session.tick()
            midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
        }
        time = startSecond + 8.01
        session.tick() // Second lesson finishes -> full Mix round finishes!

        session.stop()

        // 1 full Mix round finished, but because pass 1 was shown, it is NOT a memory round
        XCTAssertEqual(progress.trainingLog.mixRounds, 1)
        XCTAssertEqual(progress.trainingLog.mixMemoryRounds, 0)
    }

    func testMergeTakesMaxAndUnion() {
        let logA = TrainingLog(
            reviewsPassed: 5,
            bounceBacks: 1,
            mixRounds: 3,
            mixMemoryRounds: 2,
            afterMeLessons: [101, 102],
            trainingDays: ["2026-11-01", "2026-11-02"]
        )
        let logB = TrainingLog(
            reviewsPassed: 8,
            bounceBacks: 0,
            mixRounds: 2,
            mixMemoryRounds: 4,
            afterMeLessons: [102, 103],
            trainingDays: ["2026-11-02", "2026-11-03"]
        )
        let mergedLog = ProgressStore.merging(logA, with: logB)
        XCTAssertEqual(mergedLog.reviewsPassed, 8)
        XCTAssertEqual(mergedLog.bounceBacks, 1)
        XCTAssertEqual(mergedLog.mixRounds, 3)
        XCTAssertEqual(mergedLog.mixMemoryRounds, 4)
        XCTAssertEqual(mergedLog.afterMeLessons, [101, 102, 103])
        XCTAssertEqual(mergedLog.trainingDays, ["2026-11-01", "2026-11-02", "2026-11-03"])

        let lessonA = LessonProgress(lastReviewFailDay: "2026-11-02")
        let lessonB = LessonProgress(lastReviewFailDay: "2026-11-04")
        let mergedLesson = ProgressStore.merging(lessonA, with: lessonB)
        XCTAssertEqual(mergedLesson.lastReviewFailDay, "2026-11-04")
    }

    func testOldFileWithReviewStep2GivesReviewsPassed2() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        let fileURL = tempDir.appendingPathComponent("progress.json")

        let oldJSON = """
        {
            "10001": {
                "passed": true,
                "mastery": true,
                "memory": false,
                "currentBpm": 100,
                "bestScore": 0.85,
                "reviewStep": 2,
                "reviewDueDay": "2026-11-20"
            }
        }
        """
        try oldJSON.write(to: fileURL, atomically: true, encoding: .utf8)

        let store = ProgressStore(fileURL: fileURL, autoLoad: true)
        XCTAssertEqual(store.trainingLog.reviewsPassed, 2)
    }
}
