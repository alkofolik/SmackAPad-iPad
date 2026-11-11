import AVFoundation
import Darwin
import XCTest
@testable import SmackAPad

final class TrainingMixSessionTests: XCTestCase {
    @MainActor
    func testMixRunRecordsTheSameProgressAsNormalRunForTheSameHits() async throws {
        for mode in [PracticeMode.learning, .challenge] {
            for fromMemory in [false, true] {
                for playAllHits in [false, true] {
                    let suite = "mix-progress-\(UUID().uuidString)"
                    let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
                    defer { defaults.removePersistentDomain(forName: suite) }
                    let settings = SettingsManager(userDefaults: defaults)
                    settings.practiceMode = mode
                    let hits = stride(from: 0, to: 64, by: 2).map {
                        LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100)
                    }
                    let first = Lesson(id: 51_001, cat: "test", title: "First", genre: "Rock", tags: [],
                        text: "", division: 16, bars: 4, startBpm: 60, targetBpm: 120, level: 1,
                        src: "Test", hits: hits)
                    let second = Lesson(id: 51_002, cat: "test", title: "Second", genre: "Jazz", tags: [],
                        text: "", division: 16, bars: 1, startBpm: 60, targetBpm: 90, level: 1,
                        src: "Test", hits: Array(hits.prefix(4)))
                    var outcomes: [LessonProgress] = []
                    for isMix in [false, true] {
                        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite)-\(isMix).json")
                        defer { try? FileManager.default.removeItem(at: file) }
                        let progress = ProgressStore(fileURL: file, autoLoad: false)
                        progress.setProgress(LessonProgress(passed: true, mastery: true, currentBpm: 120,
                            masteryDay: "2026-11-04", reviewStep: 0, reviewDueDay: "2026-11-05"), for: first.id)
                        let midi = MIDIInput(settings: settings)
                        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                        let session = PracticeSession(lesson: first, settings: settings, progress: progress,
                            midi: midi, initialFromMemory: fromMemory, initialBpm: 120,
                            mixLessons: isMix ? [first, second] : [], clock: { time }, currentDay: { "2026-11-05" })
                        session.metronome = false
                        await session.prepare()
                        defer { session.close() }
                        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")
                        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                        let start = time + 0.6 + 2
                        session.start()
                        for (index, hit) in hits.enumerated() where playAllHits || index % 2 == 0 {
                            time = start + Double(hit.step) * 15 / 120
                            session.tick()
                            midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                                timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
                        }
                        time = start + 8.01
                        await session.tick()?.value
                        if isMix {
                            XCTAssertFalse(session.running)
                            XCTAssertNil(session.summary)
                            XCTAssertEqual(session.mixIndex, 1)
                            XCTAssertEqual(session.lesson.id, second.id)
                            XCTAssertEqual(session.bpm, 90)
                            XCTAssertNil(session.countdown)
                            XCTAssertEqual(session.mixResults.count, 2)
                            XCTAssertEqual(session.mixResults.first?.score, playAllHits ? 1 : 0.5)
                            XCTAssertEqual(session.previousMixResult?.index, 0)
                            XCTAssertEqual(session.previousMixResult?.result.score, playAllHits ? 1 : 0.5)
                            XCTAssertNil(session.tempoUpEvent)
                        }
                        session.stop()
                        outcomes.append(try XCTUnwrap(progress.progress(for: first.id)))
                        session.close()
                    }
                    XCTAssertEqual(outcomes[0], outcomes[1], "\(mode), memory \(fromMemory), all hits \(playAllHits)")
                }
            }
        }
    }

    @MainActor
    func testMixStopsAutomaticallyAfterLastLessonForTwoAndThreeLessons() async throws {
        let scenarios: [(fromMemory: Bool, fadeNotes: Bool, reviewDue: Bool, met: Bool, counted: Bool)] = [
            (false, true, false, true, true),  // Ordinary practice.
            (false, true, true, false, false), // Due review played with notes.
            (true, true, false, false, false), // Memory warm-up with visible notes.
            (true, false, false, true, true),  // A completed hidden memory round.
            (true, false, true, false, true)   // An eligible pass, but the review is not decided yet.
        ]
        for lessonCount in [2, 3] {
            for scenario in scenarios {
                let suite = "mix-auto-stop-\(lessonCount)-\(UUID().uuidString)"
                let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
                defer { defaults.removePersistentDomain(forName: suite) }
                let settings = SettingsManager(userDefaults: defaults)
                settings.fadeMemoryNotes = scenario.fadeNotes

                let hits = stride(from: 0, to: 64, by: 4).map {
                    LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100)
                }
                let allLessons = (1...lessonCount).map { idx in
                    Lesson(id: 70_000 + idx, cat: "test", title: "Lesson \(idx)", genre: "Rock", tags: [],
                           text: "", division: 16, bars: 4, startBpm: 120, targetBpm: 120, level: 1,
                           src: "Test", hits: hits)
                }

                let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
                defer { try? FileManager.default.removeItem(at: file) }
                let progress = ProgressStore(fileURL: file, autoLoad: false)
                if scenario.reviewDue || scenario.fromMemory {
                    for lesson in allLessons {
                        progress.setProgress(LessonProgress(passed: true, mastery: true, currentBpm: 120,
                            masteryDay: "2026-11-04", reviewStep: scenario.reviewDue ? 0 : nil,
                            reviewDueDay: scenario.reviewDue ? "2026-11-05" : nil), for: lesson.id)
                    }
                }
                let midi = MIDIInput(settings: settings)
                var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())

                let session = PracticeSession(
                    lesson: allLessons[0],
                    settings: settings,
                    progress: progress,
                    midi: midi,
                    initialFromMemory: scenario.fromMemory,
                    mixLessons: allLessons,
                    clock: { time },
                    currentDay: { "2026-11-05" }
                )
                session.metronome = false
                await session.prepare()
                defer { session.close() }
                XCTAssertTrue(session.ready)

                time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
                session.start()

                for (lessonIndex, currentLesson) in allLessons.enumerated() {
                    if lessonIndex > 0 {
                        XCTAssertFalse(session.running, "Session must wait paused before lesson \(lessonIndex + 1)")
                        XCTAssertNil(session.summary)
                        XCTAssertEqual(session.mixIndex, lessonIndex)
                        XCTAssertEqual(session.lesson.id, currentLesson.id)
                        XCTAssertNil(session.countdown)
                        time += 5.0
                        XCTAssertNil(session.tick())
                        XCTAssertFalse(session.running, "Session must not start until start() is called")
                        session.start()
                    }
                    XCTAssertTrue(session.running, "Session should be running during lesson \(lessonIndex + 1)")
                    XCTAssertEqual(session.lesson.id, currentLesson.id)

                    let start = time + 0.6 + 4 * (60.0 / 120.0)
                    for hit in currentLesson.hits(forPadCount: 16) {
                        time = start + Double(hit.step) * 15 / 120
                        session.tick()
                        midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                            timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
                    }
                    time = start + Double(currentLesson.bars) * 240 / 120 + 0.01
                    await session.tick()?.value
                }

                // After the last lesson's pass, the session is stopped automatically
                XCTAssertFalse(session.running, "Session must stop automatically after the last lesson")
                XCTAssertNil(session.countdown, "No countdown should be active after mix completion")
                XCTAssertEqual(session.mixResults.count, lessonCount, "All lessons must be in mixResults")
                XCTAssertEqual(session.mixResults.map(\.id), allLessons.map(\.id))
                XCTAssertTrue(session.mixResults.allSatisfy { $0.score != nil }, "All mixResults must have completed scores")
                XCTAssertTrue(session.mixResults.allSatisfy { $0.met == scenario.met },
                              "The marks must reflect memory and review requirements, not only the score")
                XCTAssertTrue(session.mixResults.allSatisfy { $0.counted == scenario.counted },
                              "The marks must distinguish eligible passes from warm-ups")
                XCTAssertEqual(progress.trainingLog.mixRounds, 1, "recordFinishedMixRound must be called exactly once")
                XCTAssertNotNil(session.summary, "Session summary must be populated")
                XCTAssertEqual(session.isMixFullyMet, scenario.met)
                XCTAssertEqual(session.summary?.passed, scenario.met)
                if !scenario.reviewDue && !scenario.fromMemory {
                    XCTAssertTrue(session.mixResults.allSatisfy {
                        $0.starEvent?.award.fresh == [true, true, false]
                    }, "The result must retain each lesson's newly earned stars")
                }

                // Nothing is scheduled after: advancing time further does not start anything
                time += 10.0
                XCTAssertNil(session.tick())
                XCTAssertFalse(session.running, "Session must remain stopped")
                XCTAssertNil(session.countdown, "No countdown should be scheduled")
                XCTAssertEqual(session.lesson.id, allLessons.last?.id)
                XCTAssertEqual(session.runResults.count, lessonCount)
                XCTAssertEqual(progress.trainingLog.mixRounds, 1, "Later ticks must not record the round again")

                let earnedProgress = allLessons.map { progress.progress(for: $0.id) }
                session.start()
                XCTAssertTrue(session.running)
                XCTAssertEqual(session.mixIndex, 0, "START must return to the first lesson")
                XCTAssertEqual(session.lesson.id, allLessons[0].id)
                XCTAssertTrue(session.mixResults.allSatisfy { $0.score == nil && $0.starEvent == nil })
                XCTAssertEqual(allLessons.map { progress.progress(for: $0.id) }, earnedProgress,
                               "START must retain earned progress")
                session.stop()
                XCTAssertNil(session.tick())
                XCTAssertFalse(session.running)
                XCTAssertNil(session.countdown)
                XCTAssertEqual(progress.trainingLog.mixRounds, 1, "An interrupted round must not be recorded")
            }
        }
    }

    @MainActor
    func testPauseBetweenMixLessonsAllowsTempoEditAndSkipFinishesWithoutResult() async throws {
        let suite = "mix-pause-skip-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsManager(userDefaults: defaults)

        let hits = stride(from: 0, to: 64, by: 4).map {
            LessonHit(step: $0, padIndex: 12, hand: "L", velocity: 100)
        }
        let lessons = (1...3).map { idx in
            Lesson(id: 71_000 + idx, cat: "test", title: "Mix \(idx)", genre: "Rock", tags: [],
                   text: "", division: 16, bars: 4, startBpm: 80, targetBpm: 120, level: 1,
                   src: "Test", hits: hits)
        }

        let file = FileManager.default.temporaryDirectory.appendingPathComponent("\(suite).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let progress = ProgressStore(fileURL: file, autoLoad: false)
        let midi = MIDIInput(settings: settings)
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())

        let session = PracticeSession(
            lesson: lessons[0],
            settings: settings,
            progress: progress,
            midi: midi,
            mixLessons: lessons,
            clock: { time },
            currentDay: { "2026-11-05" }
        )
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready)

        // Play lesson 1 cleanly
        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        session.start()
        let start1 = time + 0.6 + 4 * (60.0 / 120.0)
        for hit in lessons[0].hits(forPadCount: 16) {
            time = start1 + Double(hit.step) * 15 / 120
            session.tick()
            midi.onPadEvent?(PadInputEvent(padIndex: hit.padIndex, velocity: 100, isNoteOn: true,
                timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "test"))
        }
        time = start1 + Double(lessons[0].bars) * 240 / 120 + 0.01
        await session.tick()?.value

        // Paused at lesson 2: does not auto-start, previous result recorded, tempo editable
        XCTAssertFalse(session.running)
        XCTAssertNil(session.summary)
        XCTAssertEqual(session.mixIndex, 1)
        XCTAssertEqual(session.lesson.id, lessons[1].id)
        XCTAssertEqual(session.previousMixResult?.index, 0)
        XCTAssertEqual(session.previousMixResult?.result.score, 1.0)
        session.setTempo(95)
        XCTAssertEqual(session.bpm, 95)

        // Calling skipMixLesson advances to lesson 3 in stopped state without writing a score for lesson 2
        await session.skipMixLesson()?.value
        XCTAssertFalse(session.running)
        XCTAssertNil(session.summary)
        XCTAssertEqual(session.mixIndex, 2)
        XCTAssertEqual(session.lesson.id, lessons[2].id)
        XCTAssertEqual(session.bpm, 120)
        XCTAssertNil(session.mixResults[1].score)
        XCTAssertEqual(session.previousMixResult?.index, 1)
        XCTAssertNil(session.previousMixResult?.result.score)

        // Calling start() on lesson 3 starts lesson 3 (not lesson 1!) and preserves previous mix results
        session.setTempo(100)
        session.start()
        XCTAssertTrue(session.running)
        XCTAssertEqual(session.mixIndex, 2)
        XCTAssertEqual(session.lesson.id, lessons[2].id)
        XCTAssertEqual(session.bpm, 100)
        XCTAssertEqual(session.mixResults[0].score, 1.0)
        XCTAssertNil(session.mixResults[1].score)

        // Stop early -> Skip from the last lesson finishes the mix without recording a completed round
        session.stop()
        XCTAssertNotNil(session.summary)

        // Also test direct skip on the last lesson from paused state
        let session2 = PracticeSession(
            lesson: lessons[0],
            settings: settings,
            progress: progress,
            midi: midi,
            mixLessons: lessons,
            clock: { time },
            currentDay: { "2026-11-05" }
        )
        session2.metronome = false
        await session2.prepare()
        defer { session2.close() }
        await session2.skipMixLesson()?.value
        await session2.skipMixLesson()?.value
        XCTAssertEqual(session2.mixIndex, 2)
        XCTAssertNil(session2.summary)
        await session2.skipMixLesson()?.value
        XCTAssertNotNil(session2.summary)
        XCTAssertFalse(session2.isMixFullyMet)
        XCTAssertTrue(session2.mixResults.allSatisfy { $0.score == nil })
        XCTAssertEqual(progress.trainingLog.mixRounds, 0, "Skipped rounds must not count as completed mix rounds")
    }
}
