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
}
