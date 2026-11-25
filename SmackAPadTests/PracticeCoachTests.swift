import AVFoundation
import Darwin
import XCTest
@testable import SmackAPad

final class PracticeCoachTests: XCTestCase {
    func testRecommendReturnsNilForPassingAfterMeMixSectionLoopAndZeroPasses() {
        XCTAssertNil(
            PracticeCoach.recommend(
                score: LearningRules.passMark,
                totalBars: 2,
                errorsByBar: [1: 3],
                currentBpm: 90,
                startBpm: 60,
                bpmStep: 5,
                isAfterMe: false,
                isMix: false,
                isSectionLoop: false
            )
        )
        XCTAssertNil(
            PracticeCoach.recommend(
                score: 0.5,
                totalBars: 2,
                errorsByBar: [1: 3],
                currentBpm: 90,
                startBpm: 60,
                bpmStep: 5,
                isAfterMe: true,
                isMix: false,
                isSectionLoop: false
            )
        )
        XCTAssertNil(
            PracticeCoach.recommend(
                score: 0.5,
                totalBars: 2,
                errorsByBar: [1: 3],
                currentBpm: 90,
                startBpm: 60,
                bpmStep: 5,
                isAfterMe: false,
                isMix: true,
                isSectionLoop: false
            )
        )
        XCTAssertNil(
            PracticeCoach.recommend(
                score: 0.5,
                totalBars: 2,
                errorsByBar: [1: 3],
                currentBpm: 90,
                startBpm: 60,
                bpmStep: 5,
                isAfterMe: false,
                isMix: false,
                isSectionLoop: true
            )
        )
        XCTAssertNil(
            PracticeCoach.recommend(
                score: 0.5,
                totalBars: 2,
                errorsByBar: [1: 3],
                currentBpm: 90,
                startBpm: 60,
                bpmStep: 5,
                isAfterMe: false,
                isMix: false,
                isSectionLoop: false,
                passes: 0
            )
        )
    }

    func testRecommendReturnsDrillBarWhenWorstBarMeetsThreshold() {
        // Bar 1 (0-based) has 3 of 4 total errors (>= 50% and >= 2).
        // drillBpm = max(40, min(85, max(60, 80))) = 80.
        let suggestion = PracticeCoach.recommend(
            score: 0.6,
            totalBars: 4,
            errorsByBar: [0: 1, 1: 3],
            currentBpm: 85,
            startBpm: 60,
            bpmStep: 5,
            isAfterMe: false,
            isMix: false,
            isSectionLoop: false
        )
        XCTAssertEqual(suggestion, .drillBar(barIndex: 1, drillBpm: 80))

        // Exact 50% threshold (2 of 4 errors in one bar) still drills the worst bar,
        // and drillBpm clamps down to startBpm rather than below it when currentBpm >= startBpm.
        let exactHalf = PracticeCoach.recommend(
            score: 0.65,
            totalBars: 4,
            errorsByBar: [0: 1, 2: 2, 3: 1],
            currentBpm: 62,
            startBpm: 60,
            bpmStep: 5,
            isAfterMe: false,
            isMix: false,
            isSectionLoop: false
        )
        XCTAssertEqual(exactHalf, .drillBar(barIndex: 2, drillBpm: 60))

        // If already slower than startBpm, drillBpm does not speed up.
        let belowStart = PracticeCoach.recommend(
            score: 0.5,
            totalBars: 2,
            errorsByBar: [1: 2],
            currentBpm: 50,
            startBpm: 60,
            bpmStep: 5,
            isAfterMe: false,
            isMix: false,
            isSectionLoop: false
        )
        XCTAssertEqual(belowStart, .drillBar(barIndex: 1, drillBpm: 50))
    }

    func testRecommendFallsBackToSlowDownWhenErrorsAreSpreadOutOrSingleBar() {
        // 4 bars with 1 error each: worst bar has < 2 errors, falls back to slowDown.
        let spread = PracticeCoach.recommend(
            score: 0.6,
            totalBars: 4,
            errorsByBar: [0: 1, 1: 1, 2: 1, 3: 1],
            currentBpm: 90,
            startBpm: 60,
            bpmStep: 10,
            isAfterMe: false,
            isMix: false,
            isSectionLoop: false
        )
        XCTAssertEqual(spread, .slowDown(targetBpm: 80))

        // Worst bar has 2 errors, but total is 5 (40% < 50%): falls back to slowDown.
        let belowHalf = PracticeCoach.recommend(
            score: 0.5,
            totalBars: 4,
            errorsByBar: [0: 2, 1: 1, 2: 1, 3: 1],
            currentBpm: 80,
            startBpm: 60,
            bpmStep: 3,
            isAfterMe: false,
            isMix: false,
            isSectionLoop: false
        )
        XCTAssertEqual(belowHalf, .slowDown(targetBpm: 75))

        // Single-bar lesson at startBpm > 50 with >= 2 errors slows down.
        let singleBarAtStart = PracticeCoach.recommend(
            score: 0.5,
            totalBars: 1,
            errorsByBar: [0: 2],
            currentBpm: 60,
            startBpm: 60,
            bpmStep: 5,
            isAfterMe: false,
            isMix: false,
            isSectionLoop: false
        )
        XCTAssertEqual(singleBarAtStart, .slowDown(targetBpm: 55))

        // At startBpm <= 50 and no concentrated bar to drill -> nil.
        let tooSlow = PracticeCoach.recommend(
            score: 0.5,
            totalBars: 1,
            errorsByBar: [0: 2],
            currentBpm: 50,
            startBpm: 50,
            bpmStep: 5,
            isAfterMe: false,
            isMix: false,
            isSectionLoop: false
        )
        XCTAssertNil(tooSlow)
    }

    @MainActor
    func testSessionCoachDrillIsolatesWeakBarAutoStopsAfterTwoCleanPassesAndRestoresFullLesson() async throws {
        let suite = "coach-drill-lifecycle-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let midi = MIDIInput(settings: settings)

        // 2-bar lesson at 120 BPM (startBpm 80), 4 hits per bar (8 hits per phrase).
        let bar0Hits = [0, 4, 8, 12].map { LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100) }
        let bar1Hits = [16, 20, 24, 28].map { LessonHit(step: $0, padIndex: 13, hand: "R", velocity: 100) }
        let lesson = Lesson(
            id: 40_234,
            cat: "test",
            title: "Coach drill test",
            genre: "",
            tags: [],
            text: "",
            division: 16,
            bars: 2,
            startBpm: 80,
            targetBpm: 120,
            level: 1,
            src: "test",
            hits: bar0Hits + bar1Hits
        )

        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(
            lesson: lesson,
            settings: settings,
            progress: progress,
            midi: midi,
            initialBpm: 120,
            clock: { time }
        )
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")

        // Run 1: full 2-bar lesson (repeatsPerRun = 2 -> 4 bars total = 8.0 s at 120 BPM).
        // Hit all bar 0 notes cleanly, miss all bar 1 notes -> 50% score, all errors in bar 1.
        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let fullStart = time + 0.6 + 4 * (60.0 / 120.0)
        session.start()
        XCTAssertTrue(session.running)

        for rep in 0..<2 {
            for hit in bar0Hits {
                let step = hit.step + rep * 32
                time = fullStart + Double(step) * 15.0 / 120.0 + 0.02
                session.tick()
                midi.onPadEvent?(PadInputEvent(
                    padIndex: hit.padIndex,
                    velocity: 100,
                    isNoteOn: true,
                    timestamp: AVAudioTime.hostTime(forSeconds: time),
                    deviceID: "test"
                ))
            }
        }
        // Advance past pass 1 finalTime (8.0 s + 0.2 s window) and stop.
        time = fullStart + 8.3
        session.tick()
        session.stop()

        XCTAssertEqual(session.coachSuggestion, .drillBar(barIndex: 1, drillBpm: 115))

        // Enter the bar drill via startCoachSuggestion.
        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let drillStart = time + 0.6 + 4 * (60.0 / 115.0)
        session.startCoachSuggestion(.drillBar(barIndex: 1, drillBpm: 115))
        XCTAssertTrue(session.running)
        XCTAssertEqual(session.loopStartBar, 1)
        XCTAssertEqual(session.loopEndBar, 1)
        XCTAssertEqual(session.bpm, 115)
        XCTAssertEqual(session.activeCoachDrill?.savedBpm, 120)
        XCTAssertEqual(session.activeCoachDrill?.targetBar, 1)
        XCTAssertEqual(session.activeCoachDrill?.cleanPasses, 0)

        let barDuration = 240.0 / 115.0
        func playDrillPass(passIndex: Int, hitAll: Bool) {
            let passStart = drillStart + Double(passIndex) * barDuration
            let drillHits = session.patternHits
            let toPlay = hitAll ? drillHits : Array(drillHits.dropLast())
            for hit in toPlay {
                time = passStart + Double(hit.step) * 15.0 / 115.0 + 0.02
                session.tick()
                midi.onPadEvent?(PadInputEvent(
                    padIndex: hit.padIndex,
                    velocity: 100,
                    isNoteOn: true,
                    timestamp: AVAudioTime.hostTime(forSeconds: time),
                    deviceID: "test"
                ))
            }
            // Trigger pass queueing just before pass end, then finalize after pass end.
            time = passStart + barDuration - 0.1
            session.tick()
            time = passStart + barDuration + 0.05
            session.tick()
        }

        // Pass 1 clean -> cleanPasses == 1, still running.
        playDrillPass(passIndex: 0, hitAll: true)
        XCTAssertTrue(session.running)
        XCTAssertEqual(session.activeCoachDrill?.cleanPasses, 1)
        XCTAssertEqual(session.bpm, 115)

        // Pass 2 dirty (missed 1 hit) -> resets consecutive cleanPasses to 0, still running.
        playDrillPass(passIndex: 1, hitAll: false)
        XCTAssertTrue(session.running)
        XCTAssertEqual(session.activeCoachDrill?.cleanPasses, 0)

        // Pass 3 clean -> cleanPasses == 1.
        playDrillPass(passIndex: 2, hitAll: true)
        XCTAssertTrue(session.running)
        XCTAssertEqual(session.activeCoachDrill?.cleanPasses, 1)

        // Pass 4 clean -> cleanPasses == 2 -> auto-stops drill!
        playDrillPass(passIndex: 3, hitAll: true)
        XCTAssertFalse(session.running)
        XCTAssertEqual(session.activeCoachDrill?.cleanPasses, 2)
        XCTAssertEqual(session.completedCoachDrillBar, 1)
        XCTAssertNotNil(session.summary)

        // Finish drill and return to full lesson -> restores full bars, saved BPM, clears drill, restarts.
        session.finishCoachDrillAndRestart()
        XCTAssertNil(session.activeCoachDrill)
        XCTAssertNil(session.completedCoachDrillBar)
        XCTAssertEqual(session.loopStartBar, 0)
        XCTAssertEqual(session.loopEndBar, 1)
        XCTAssertEqual(session.bpm, 120)
        XCTAssertTrue(session.running)
    }

    @MainActor
    func testSlowDownAndExitOrCloseRestoreSessionStateCleanly() async throws {
        let suite = "coach-slowdown-exit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let midi = MIDIInput(settings: settings)

        let hits = [0, 8, 16, 24].map { LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100) }
        let lesson = Lesson(
            id: 40_235,
            cat: "test",
            title: "Coach slow down test",
            genre: "",
            tags: [],
            text: "",
            division: 16,
            bars: 2,
            startBpm: 80,
            targetBpm: 120,
            level: 1,
            src: "test",
            hits: hits
        )

        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(
            lesson: lesson,
            settings: settings,
            progress: progress,
            midi: midi,
            initialBpm: 100,
            clock: { time }
        )
        session.metronome = false
        await session.prepare()

        // Slow down updates BPM and restarts immediately without entering bar-drill mode.
        session.startCoachSuggestion(.slowDown(targetBpm: 95))
        XCTAssertTrue(session.running)
        XCTAssertEqual(session.bpm, 95)
        XCTAssertNil(session.activeCoachDrill)
        session.stop()

        // Enter bar drill, then exit via exitCoachDrill -> restores full bars & saved BPM.
        session.startCoachSuggestion(.drillBar(barIndex: 1, drillBpm: 90))
        XCTAssertNotNil(session.activeCoachDrill)
        XCTAssertEqual(session.bpm, 90)
        session.exitCoachDrill()
        XCTAssertFalse(session.running)
        XCTAssertNil(session.activeCoachDrill)
        XCTAssertEqual(session.loopStartBar, 0)
        XCTAssertEqual(session.loopEndBar, 1)
        XCTAssertEqual(session.bpm, 95)

        // Manual loop change clears activeCoachDrill.
        session.startCoachSuggestion(.drillBar(barIndex: 1, drillBpm: 90))
        session.stop()
        XCTAssertNotNil(session.activeCoachDrill)
        session.loopStartBar = 0
        XCTAssertNil(session.activeCoachDrill)

        // Close clears activeCoachDrill and restores saved BPM & full bars.
        session.loopEndBar = 1
        session.setTempo(105)
        session.startCoachSuggestion(.drillBar(barIndex: 1, drillBpm: 100))
        XCTAssertNotNil(session.activeCoachDrill)
        session.close()
        XCTAssertNil(session.activeCoachDrill)
        XCTAssertEqual(session.loopStartBar, 0)
        XCTAssertEqual(session.loopEndBar, 1)
        XCTAssertEqual(session.bpm, 105)
    }
}
