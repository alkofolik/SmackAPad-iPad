import AVFoundation
import Darwin
import XCTest
@testable import SmackAPad

final class PracticeSessionTests: XCTestCase {
    override func setUp() { super.setUp(); StarStreak.forgetAll() }

    @MainActor
    func testTapeMovesContinuouslyAcrossTenRepeatsBeforeAndAfterSchedulerTicks() async throws {
        let suite = "tape-boundary-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let midi = MIDIInput(settings: settings)
        for bpm in [60, 90, 140] {
            for bars in [1, 2, 4] {
                let lesson = Lesson(id: 33_000 + bpm + bars, cat: "test", title: "Tape", genre: "", tags: [],
                    text: "", division: 16, bars: bars, startBpm: bpm, targetBpm: bpm, level: 1, src: "test",
                    hits: [0, bars * 16 - 1].map { LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100) })
                var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                let session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi, clock: { time })
                session.metronome = false
                await session.prepare()
                defer { session.close() }
                XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")
                time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                let start = time + 0.6 + 240 / Double(bpm)
                let duration = Double(bars) * 240 / Double(bpm)
                session.start()
                XCTAssertTrue(session.running)
                time = start
                session.tick()
                var deltas: [Double] = []
                for repeatIndex in 1...10 {
                    let boundary = start + Double(repeatIndex) * duration
                    time = boundary - 0.4
                    session.tick() // Queue the next pass, but leave the boundary tick delayed.
                    time = boundary - 15 / Double(bpm)
                    session.tick()
                    midi.onPadEvent?(PadInputEvent(padIndex: 12, velocity: 100, isNoteOn: true,
                        timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
                    let lastHit = try XCTUnwrap(session.playedHits.last)
                    let lastNote = try XCTUnwrap(lesson.hits.last)
                    XCTAssertEqual(lastHit.tapeStep(totalSteps: bars * 16), Double(repeatIndex * bars * 16 - 1), accuracy: 0.00001)
                    time = boundary - 1.0 / 120
                    let before = session.patternFrame
                    time = boundary + 1.0 / 120
                    let after = session.patternFrame
                    let delta = after.tapePosition - before.tapePosition
                    deltas.append(delta)
                    XCTAssertGreaterThan(delta, 0, "Tape reversed at \(bpm) BPM, \(bars) bars")
                    XCTAssertEqual(delta, Double(bpm) / 900, accuracy: 0.00001,
                                   "A 60 Hz display frame must advance at the scheduled tempo")
                    XCTAssertEqual(after.pass, repeatIndex + 1)
                    XCTAssertEqual(session.hitJudgments[repeatIndex]?[lastNote], .perfect)
                    XCTAssertNil(session.hitJudgments[repeatIndex + 1]?[lastNote])
                    XCTAssertEqual(after.position, Double(bpm) / 1800, accuracy: 0.00001)
                    session.tick()
                    XCTAssertEqual(session.patternFrame.tapePosition, after.tapePosition, accuracy: 0.00001,
                                   "The scheduler tick must not move the tape")
                    XCTAssertTrue(session.running, session.errorMessage ?? "Run stopped")
                    XCTAssertEqual(session.hitJudgments[repeatIndex]?[lastNote], .perfect)
                    XCTAssertEqual(session.playedHits.last?.tapeStep(totalSteps: bars * 16), lastHit.tapeStep(totalSteps: bars * 16))
                }
                print("[tape-boundary] \(bpm) BPM / \(bars) bars / 10 boundaries: delta \(deltas.min()!)...\(deltas.max()!) steps per 60 Hz frame")
                session.close()
            }
        }
    }

    @MainActor
    func testMemoryStarAtEightyPercentEmitsEventAndAutomaticallyStopsAfterRequiredPasses() async throws {
        let suite = "practice-feedback-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let hits = [0, 3, 6, 9, 12].map { LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100) }
        let lesson = Lesson(id: 24_001, cat: "test", title: "Memory star", genre: "", tags: [],
            text: "", division: 16, bars: 1, startBpm: 120, targetBpm: 120, level: 1, src: "test", hits: hits)
        progress.setProgress(LessonProgress(passed: true, mastery: true, currentBpm: 120), for: lesson.id)
        let midi = MIDIInput(settings: settings)
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi, clock: { time })
        session.fromMemory = true
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")
        // Loading samples takes real time. Keep the count-in ahead of the audio clock.
        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let firstStart = time + 0.6 + 4 * 60.0 / 120
        let duration = 240.0 / 120
        session.start()
        XCTAssertTrue(session.running)
        let required = StarStreak.requiredRuns(expectedHits: hits.count, isIntro: false)
        XCTAssertEqual(required, 4)
        for pass in 0..<required {
            let start = firstStart + Double(pass) * duration
            for hit in hits.dropLast() {
                time = start + Double(hit.step) * 15 / 120
                session.tick()
                midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                    timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
            }
            // Queue the next pass using the real session scheduler, then finish this one.
            time = start + duration - 0.4
            session.tick()
            time = start + duration + 0.001
            session.tick()
            if pass < required - 1 {
                XCTAssertTrue(session.running, session.errorMessage ?? "Run ended before the memory streak completed")
                XCTAssertNil(session.starEvent)
                XCTAssertNil(session.summary)
            }
        }
        let event = try XCTUnwrap(session.starEvent)
        XCTAssertEqual(event.award.fresh, [false, false, true])
        XCTAssertTrue(event.award.shouldStop)
        XCTAssertFalse(session.running)
        XCTAssertEqual(session.lastResult?.score ?? 0, 0.8, accuracy: 0.0001)
        XCTAssertEqual(session.summary?.finishedByStar, 3)
        XCTAssertEqual(session.summary?.passes, required)
        XCTAssertEqual(progress.progress(for: lesson.id)?.memory, true)
        XCTAssertTrue(session.playedHits.isEmpty)
        XCTAssertTrue(session.hitJudgments.isEmpty)
        session.start()
        XCTAssertTrue(session.running)
        XCTAssertNil(session.starEvent)
        XCTAssertNil(session.summary)
        XCTAssertNil(session.finishedByStar)
        XCTAssertTrue(session.hitJudgments.isEmpty)
        XCTAssertTrue(session.playedHits.isEmpty)
    }
}
