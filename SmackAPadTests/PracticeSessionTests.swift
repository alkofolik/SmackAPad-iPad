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
            text: "", division: 16, bars: 4, startBpm: 120, targetBpm: 120, level: 1, src: "test", hits: hits)
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
        let duration = Double(lesson.bars) * 240.0 / 120
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

    @MainActor
    func testOneBarLessonPlayedOverOnePassYieldsRepeatedHitsAndOneTempoStep() async throws {
        let suite = "four-bar-run-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let midi = MIDIInput(settings: settings)
        let hits = [0, 4, 8, 12].map { LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100) }
        let lesson = Lesson(id: 40_001, cat: "starter", title: "One bar run", genre: "", tags: [],
            text: "", division: 16, bars: 1, startBpm: 60, targetBpm: 120, level: 1, src: "test", hits: hits)
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi, clock: { time })
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")

        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let firstStart = time + 0.6 + 4 * 60.0 / 60.0
        let repeats = session.repeatsPerRun
        XCTAssertEqual(repeats, 4)
        session.start()
        XCTAssertTrue(session.running)
        let initialBpm = session.bpm

        // Play all repeats across the single pass
        for rep in 0..<repeats {
            for hit in hits {
                let step = hit.step + rep * lesson.bars * 16
                time = firstStart + Double(step) * 15.0 / Double(initialBpm)
                session.tick()
                midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                    timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
            }
        }

        // Advance to end of the pass
        let passDuration = Double(repeats * lesson.bars) * 240.0 / Double(initialBpm)
        time = firstStart + passDuration - 0.4
        session.tick()
        time = firstStart + passDuration + 0.05
        session.tick()

        let result = try XCTUnwrap(session.lastResult)
        XCTAssertEqual(result.expectedHitCount, repeats * hits.count)
        XCTAssertEqual(result.matchedHitCount, repeats * hits.count)
        XCTAssertEqual(result.nextBpm, initialBpm + settings.bpmStepEnum.rawValue)
        XCTAssertEqual(session.summary?.passes ?? 1, 1)
    }

    @MainActor
    func testPassedRunProducesHigherBpmOnRunNPlusOneNotNPlusTwo() async throws {
        let suite = "tempo-step-early-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let midi = MIDIInput(settings: settings)
        let hits = [0, 4, 8, 12].map { LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100) }
        let lesson = Lesson(id: 40_002, cat: "starter", title: "Early tempo step", genre: "", tags: [],
            text: "", division: 16, bars: 1, startBpm: 60, targetBpm: 120, level: 1, src: "test", hits: hits)
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi, clock: { time })
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")

        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let firstStart = time + 0.6 + 4 * 60.0 / 60.0
        let repeats = session.repeatsPerRun
        XCTAssertEqual(repeats, 4)
        session.start()
        XCTAssertTrue(session.running)
        let initialBpm = session.bpm

        // Play all repeats across the first pass cleanly
        for rep in 0..<repeats {
            for hit in hits {
                let step = hit.step + rep * lesson.bars * 16
                time = firstStart + Double(step) * 15.0 / Double(initialBpm)
                session.tick()
                midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                    timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
            }
        }

        // Advance to queue horizon: next pass is queued about 0.5s before end
        let passDuration = Double(repeats * lesson.bars) * 240.0 / Double(initialBpm)
        time = firstStart + passDuration - 0.4
        session.tick()

        // Advance to the exact boundary when Pass 2 starts
        time = firstStart + passDuration + 0.001
        session.tick()

        let expectedNextBpm = initialBpm + settings.bpmStepEnum.rawValue
        XCTAssertEqual(session.passNumber, 2, "Session should now be on pass 2 (run N + 1)")
        XCTAssertEqual(session.bpm, expectedNextBpm, "Session BPM on run N + 1 must be higher, not on run N + 2")
        XCTAssertEqual(session.patternFrame.bpm, expectedNextBpm)
        XCTAssertEqual(session.tempoUpEvent?.from, initialBpm)
        XCTAssertEqual(session.tempoUpEvent?.to, expectedNextBpm)
    }

    @MainActor
    func testRunWhoseLastNoteIsMissedAfterEarlyDecisionDoesNotChangeAlreadyQueuedTempo() async throws {
        let suite = "late-miss-tempo-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let midi = MIDIInput(settings: settings)
        // 4 bars at 60 BPM = 16 seconds. Repeats = 1.
        // Hit 2 is at step 62 (15.5s), with timing window closing at 15.7s.
        let hits = [
            LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100),
            LessonHit(step: 62, padIndex: 12, hand: "L", velocity: 100)
        ]
        let lesson = Lesson(id: 40_003, cat: "starter", title: "Late miss test", genre: "", tags: [],
            text: "", division: 16, bars: 4, startBpm: 60, targetBpm: 120, level: 1, src: "test", hits: hits)
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi, clock: { time })
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")

        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let firstStart = time + 0.6 + 4 * 60.0 / 60.0
        session.start()
        XCTAssertTrue(session.running)
        let initialBpm = session.bpm

        // Play the first hit cleanly
        let firstHit = hits[0]
        time = firstStart + Double(firstHit.step) * 15.0 / Double(initialBpm)
        session.tick()
        midi.onPadEvent?(PadInputEvent(padIndex: firstHit.padIndex, velocity: 100, isNoteOn: true,
            timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))

        // Advance to queue time: 15.55s (0.45s before pass end).
        // Hit 2 is at 15.50s, window ends at 15.70s. Hit 2 window has not closed.
        let passDuration = Double(lesson.bars) * 240.0 / Double(initialBpm) // 16.0s
        time = firstStart + 15.55
        session.tick()

        let expectedNextBpm = initialBpm + settings.bpmStepEnum.rawValue

        // Advance past Hit 4 without playing it (late miss) to the boundary of Pass 2
        time = firstStart + passDuration + 0.001
        session.tick()

        XCTAssertEqual(session.passNumber, 2)
        XCTAssertEqual(session.bpm, expectedNextBpm, "Pass 2 must start at the higher BPM")
        XCTAssertEqual(session.patternFrame.bpm, expectedNextBpm)

        // Advance past pass 1 finalTime so finishCompleted runs for pass 1
        time = firstStart + passDuration + 0.25
        session.tick()

        // Pass 1 finished as failed due to the missed last note
        let pass1Result = try XCTUnwrap(session.lastResult)
        XCTAssertFalse(pass1Result.isCleanRun, "Full result must record the late miss")
        XCTAssertFalse(pass1Result.passed, "Full result must fail due to the missed note")
        XCTAssertEqual(session.lastVerdict?.passed, false)

        // But Pass 2's queued BPM must NOT be reverted; pass continues at 65 BPM
        XCTAssertEqual(session.bpm, expectedNextBpm, "Queued tempo must not revert inside a running pass")
        XCTAssertEqual(session.patternFrame.bpm, expectedNextBpm)
    }
}
