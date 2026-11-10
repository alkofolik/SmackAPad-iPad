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
                        session.tick()
                        if isMix {
                            XCTAssertTrue(session.running)
                            XCTAssertEqual(session.lesson.id, second.id)
                            XCTAssertEqual(session.bpm, 90)
                            XCTAssertEqual(session.countdown, 4)
                            XCTAssertEqual(session.mixResults.count, 2)
                            XCTAssertEqual(session.mixResults.first?.score, playAllHits ? 1 : 0.5)
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
        for lessonCount in [2, 3] {
            let suite = "mix-auto-stop-\(lessonCount)-\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let settings = SettingsManager(userDefaults: defaults)

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
            let midi = MIDIInput(settings: settings)
            var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())

            let session = PracticeSession(
                lesson: allLessons[0],
                settings: settings,
                progress: progress,
                midi: midi,
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
            XCTAssertTrue(session.mixResults.allSatisfy { $0.score != nil }, "All mixResults must have completed scores")
            XCTAssertTrue(session.mixResults.allSatisfy { $0.met }, "All lessons should be marked as met")
            XCTAssertEqual(progress.trainingLog.mixRounds, 1, "recordFinishedMixRound must be called exactly once")
            XCTAssertNotNil(session.summary, "Session summary must be populated")
            XCTAssertTrue(session.isMixFullyMet, "isMixFullyMet should be true")

            // Nothing is scheduled after: advancing time further does not start anything
            time += 10.0
            session.tick()
            XCTAssertFalse(session.running, "Session must remain stopped")
            XCTAssertNil(session.countdown, "No countdown should be scheduled")
        }
    }
}
