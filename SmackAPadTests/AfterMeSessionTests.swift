import AVFoundation
import Darwin
import XCTest
@testable import SmackAPad

@MainActor
final class AfterMeSessionTests: XCTestCase {
    private final class Clock {
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
    }

    private func withSession(bars: Int = 1, section: Bool = false,
                             _ body: (PracticeSession, MIDIInput, Clock, Double) throws -> Void) async throws {
        let suite = "after-me-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let hits = (0..<bars).flatMap { bar in
            [0, 4, 8, 12].map { LessonHit(step: bar * 16 + $0, padIndex: 12, hand: "L", velocity: 100) }
        }
        let lesson = Lesson(id: 52_001, cat: "test", title: "Call and response", genre: "Rock", tags: [],
            text: "", division: 16, bars: bars, startBpm: 60, targetBpm: 120, level: 1, src: "Test", hits: hits)
        progress.setProgress(LessonProgress(passed: true, mastery: true, currentBpm: 120,
            masteryDay: "2026-11-04", reviewStep: 0, reviewDueDay: "2026-11-05"), for: lesson.id)
        let before = progress.records
        let midi = MIDIInput(settings: settings)
        let clock = Clock()
        let session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi,
            initialBpm: 120, initialAfterMe: true, clock: { clock.time }, currentDay: { "2026-11-05" })
        if section { session.loopStartBar = 1; session.loopEndBar = 1 }
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")
        clock.time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let start = clock.time + 0.6 + 2
        session.start()
        try body(session, midi, clock, start)
        session.stop()
        XCTAssertEqual(progress.records, before, "After me must not record stars, scores, credit or reviews")
        XCTAssertNil(session.starEvent)
        XCTAssertNil(session.reviewFeedback)
    }

    private func hit(_ midi: MIDIInput, at time: Double, pad: Int = 12) {
        midi.onPadEvent?(PadInputEvent(padIndex: pad, velocity: 100, isNoteOn: true,
            timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
    }

    func testHitsInCallHalfAreNeverScored() async throws {
        try await withSession { session, midi, clock, start in
            for offset in [0.0, 0.5, 1, 1.5, 1.999] {
                clock.time = start + offset
                session.tick()
                self.hit(midi, at: clock.time)
            }
            clock.time = start + 4.01
            session.tick()
            let result = try XCTUnwrap(session.lastResult)
            XCTAssertEqual(result.expectedHitCount, 4)
            XCTAssertEqual(result.matchedHitCount, 0)
            XCTAssertEqual(result.extraHitCount, 0)
            XCTAssertEqual(result.score, 0)
        }
    }

    func testPerfectResponseScoresOneHundredPercentWithoutChangingProgress() async throws {
        try await withSession(bars: 2) { session, midi, clock, start in
            XCTAssertEqual(session.scoredLesson.bars, 4)
            XCTAssertEqual(session.scoredLesson.hits.map(\.step), [32, 36, 40, 44, 48, 52, 56, 60])
            for hit in session.scoredLesson.hits {
                clock.time = start + Double(hit.step) * 15 / 120
                session.tick()
                self.hit(midi, at: clock.time)
            }
            clock.time = start + 8.01
            session.tick()
            XCTAssertEqual(session.lastResult?.score, 1)
            XCTAssertEqual(session.bestResponseScore, 1)
            XCTAssertEqual(session.lastResult?.expectedHitCount, 8)
            XCTAssertTrue(session.running)
            XCTAssertEqual(session.bpm, 120)
            XCTAssertNil(session.tempoUpEvent)
            // An unanswered next response changes the last score, not the best.
            clock.time = start + 15.6
            session.tick()
            clock.time = start + 16.01
            session.tick()
            XCTAssertEqual(session.lastResult?.score, 0)
            XCTAssertEqual(session.bestResponseScore, 1)
        }
    }

    func testExtraHitsInCallDoNotLowerTheResponseScore() async throws {
        try await withSession { session, midi, clock, start in
            for offset in [0.0, 0.01, 0.4, 0.8, 1.2, 1.8, 1.999] {
                clock.time = start + offset
                session.tick()
                self.hit(midi, at: clock.time, pad: 13)
            }
            for step in [16, 20, 24, 28] {
                clock.time = start + Double(step) * 15 / 120
                session.tick()
                self.hit(midi, at: clock.time)
            }
            clock.time = start + 4.01
            session.tick()
            XCTAssertEqual(session.lastResult?.score, 1)
            XCTAssertEqual(session.lastResult?.extraHitCount, 0)
        }
    }

    func testSectionLoopDefinesBothPhraseHalvesAndContinuousCycleLength() async throws {
        try await withSession(bars: 3, section: true) { session, midi, clock, start in
            XCTAssertEqual(session.practiceLesson.bars, 1)
            XCTAssertEqual(session.scoredLesson.bars, 2)
            XCTAssertEqual(session.scoredLesson.hits.map(\.step), [16, 20, 24, 28])
            clock.time = start
            session.tick()
            XCTAssertEqual(session.afterMePhase(at: session.patternFrame), "Listen…")
            XCTAssertEqual(session.noteVisibility(pass: 1), .hidden)
            clock.time = start + 2
            session.tick()
            XCTAssertEqual(session.afterMePhase(at: session.patternFrame), "Your turn")
            XCTAssertEqual(session.noteVisibility(pass: 2), .hidden)
            for step in [16, 20, 24, 28] {
                clock.time = start + Double(step) * 15 / 120
                session.tick()
                self.hit(midi, at: clock.time)
            }
            clock.time = start + 4.001
            session.tick()
            XCTAssertEqual(session.lastResult?.score, 1)
            XCTAssertEqual(session.passNumber, 2)
            XCTAssertEqual(session.afterMePhase(at: session.patternFrame), "Listen…")
            XCTAssertEqual(session.patternFrame.tapePosition, 32.008, accuracy: 0.0001)
            XCTAssertNil(session.countdown, "A second cycle must not add a count-in")
        }
    }

}
