import AVFoundation
import Darwin
import XCTest
@testable import SmackAPad

final class BossEncounterTests: XCTestCase {
    func testPatternPrefersLastMasteredKeystoneThenAnyMasteredLesson() {
        let lessons = (1...4).map { makeLesson(id: $0) }
        let stageID = "L2-groove"
        let map = StoryMap(stages: [stageID: [.keystone(1), .fork([2, 3]), .keystone(4)]])
        let mastery = LessonProgress(passed: true, mastery: true)
        let pass = LessonProgress(passed: true)

        func pattern(_ progress: [Int: LessonProgress]) -> Int? {
            BossEncounter.pattern(in: lessons, stageID: stageID, progress: progress, storyMap: map)?.id
        }
        XCTAssertEqual(pattern([1: mastery, 3: mastery, 4: mastery]), 4)
        XCTAssertEqual(pattern([1: mastery, 3: mastery, 4: pass]), 1)
        XCTAssertEqual(pattern([2: pass, 3: mastery, 4: pass]), 3)
        XCTAssertNil(pattern([4: pass]))
    }

    func testLengthTempoAndStamina() {
        for (patternBars, repeats, bars, stamina) in [(1, 8, 8, 6), (2, 4, 8, 6), (3, 3, 9, 7), (4, 2, 8, 6)] {
            let boss = BossEncounter(stageID: "L1-groove", level: 1, lesson: makeLesson(bars: patternBars))
            XCTAssertEqual(boss.repeats, repeats)
            XCTAssertEqual(boss.bars, bars)
            XCTAssertEqual(boss.stamina, stamina)
        }
        for (level, bpm) in [85, 88, 90, 92, 95].enumerated() {
            let boss = BossEncounter(stageID: "", level: level + 1, lesson: makeLesson(targetBpm: 101))
            XCTAssertEqual(boss.bpm, bpm)
        }
    }

    func testCleanBarUsesOnlyItsNotesAndWrongHitsForThatRepetition() {
        let kick = LessonHit(step: 0, padIndex: 12, hand: "L", velocity: 100)
        let snare = LessonHit(step: 15, padIndex: 13, hand: "R", velocity: 100)
        let wrong = PlayedHit(padIndex: 12, step: 15.9, pass: 2, mark: .wrong)
        let wrongNextBar = PlayedHit(padIndex: 12, step: 16, pass: 1, mark: .wrong)
        let hits = [kick, snare]
        let played = [wrong, wrongNextBar]

        XCTAssertTrue(BossAttempt.isClean(bar: 0, cycle: 1, hits: hits,
                                          judgments: [kick: .perfect, snare: .good], playedHits: played))
        XCTAssertFalse(BossAttempt.isClean(bar: 0, cycle: 2, hits: hits,
                                           judgments: [kick: .perfect, snare: .good], playedHits: played))
        XCTAssertFalse(BossAttempt.isClean(bar: 0, cycle: 1, hits: hits, judgments: [kick: .perfect], playedHits: []))
        XCTAssertFalse(BossAttempt.isClean(bar: 0, cycle: 1, hits: hits,
                                           judgments: [kick: .perfect, snare: .off], playedHits: []))
        XCTAssertFalse(BossAttempt.isClean(bar: 1, cycle: 1, hits: hits, judgments: [:], playedHits: played))
        XCTAssertTrue(BossAttempt.isClean(bar: 1, cycle: 2, hits: hits, judgments: [:], playedHits: played))
    }

    func testVeilFollowsLevelAndOnlyHidesItsOwnPreviouslyShownBar() {
        for patternBars in 1...4 {
            for level in 1...5 {
                let boss = BossEncounter(stageID: "", level: level, lesson: makeLesson(bars: patternBars))
                let attempt = BossAttempt(encounter: boss)
                let bars = attempt.veilBars.sorted()
                XCTAssertEqual(bars.count, min(2, level - 1))
                XCTAssertTrue(bars.allSatisfy { $0 >= patternBars && $0 > 0 && $0 < boss.bars })
                XCTAssertTrue(zip(bars, bars.dropFirst()).allSatisfy { $0.1 - $0.0 >= 2 })
                XCTAssertEqual(Set((0..<boss.bars).filter(attempt.warnsDuring)), Set(bars.map { $0 - 1 }))
                XCTAssertTrue(BossAttempt(encounter: boss, gentle: true).veilBars.isEmpty)
                for bar in bars {
                    XCTAssertFalse(PatternVeilDisplay.hides(bar: bar, currentBar: bar - 1, veilBars: attempt.veilBars))
                    XCTAssertTrue(PatternVeilDisplay.hides(bar: bar, currentBar: bar, veilBars: attempt.veilBars))
                    XCTAssertFalse(PatternVeilDisplay.hides(bar: bar - 1, currentBar: bar, veilBars: attempt.veilBars))
                    XCTAssertFalse(PatternVeilDisplay.hides(bar: bar + 1, currentBar: bar, veilBars: attempt.veilBars))
                }
            }
        }
    }

    @MainActor
    func testLiveStaminaWaitsForLateHitAndJudgesEachBarOnceThroughTheLastBar() async throws {
        let suite = "BossEncounterTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(suite)
        defer { try? FileManager.default.removeItem(at: folder) }
        let settings = SettingsManager(userDefaults: defaults)
        for route in AudioOutputRoute.allCases {
            settings.setCalibrationOffset(125, for: "touch", outputRoute: route)
        }
        let progress = ProgressStore(fileURL: folder.appendingPathComponent("progress.json"), autoLoad: false)
        let midi = MIDIInput(settings: settings)
        let note = LessonHit(step: 15, padIndex: 12, hand: "L", velocity: 100)
        let lesson = makeLesson(targetBpm: 300, hits: [note])
        progress.recordResult(lessonId: lesson.id, passed: true, mastery: true, bpm: 300, score: 1, memory: false)
        let boss = BossEncounter(stageID: "L2-groove", level: 2, lesson: lesson)
        var time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let session = PracticeSession(lesson: lesson, settings: settings, progress: progress, midi: midi,
                                      boss: boss, clock: { time })
        session.metronome = false
        await session.prepare()
        defer { session.close() }
        XCTAssertTrue(session.ready, session.errorMessage ?? "Sound preparation failed")
        session.setTempo(100)
        session.selectPlaybackMode(.listen)
        XCTAssertEqual(session.bpm, boss.bpm)
        XCTAssertFalse(session.listen)
        let before = progress.drummerPath
        let barLength = 240 / Double(boss.bpm)
        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let firstStart = time + 0.6 + barLength
        session.start()
        XCTAssertTrue(session.running)

        time = firstStart + barLength + 0.05
        session.tick()
        XCTAssertEqual(session.bossAttempt?.judgedBars, 0)
        time = firstStart + barLength + 0.10
        midi.onPadEvent?(PadInputEvent(padIndex: 12, velocity: 100, isNoteOn: true,
                                       timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "touch"))
        XCTAssertEqual(session.hitJudgments[1]?[note], .perfect)

        time = firstStart + barLength + 0.40
        session.tick()
        XCTAssertEqual(session.bossAttempt?.stamina, 5)
        session.tick()
        XCTAssertEqual(session.bossAttempt?.stamina, 5)

        time = firstStart + 2 * barLength + 0.40
        session.tick()
        XCTAssertEqual(session.bossAttempt?.judgedBars, 2)
        XCTAssertEqual(session.bossAttempt?.stamina, 5, "The first repetition must not count for the second.")
        XCTAssertFalse(session.fromMemory)
        XCTAssertEqual(session.noteVisibility, .shown)

        time = firstStart + Double(boss.bars) * barLength + 0.05
        session.tick()
        XCTAssertTrue(session.running)
        XCTAssertEqual(session.bossAttempt?.judgedBars, boss.bars - 1)
        time += 0.40
        session.tick()
        XCTAssertFalse(session.running)
        XCTAssertEqual(session.bossAttempt?.judgedBars, boss.bars)
        XCTAssertEqual(session.bossAttempt?.won, false)
        XCTAssertEqual(progress.drummerPath, before)
        XCTAssertEqual(progress.progress(for: lesson.id)?.memory, false)
        XCTAssertEqual(progress.progress(for: lesson.id)?.currentBpm, 300)

        time = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        let retryStart = time + 0.6 + barLength
        session.retryBoss(gentle: true)
        XCTAssertEqual(session.bossAttempt?.encounter, boss)
        XCTAssertTrue(session.bossAttempt?.veilBars.isEmpty == true)
        for bar in [0, 1, 2, 3, 4, 7] {
            time = retryStart + Double(bar + 1) * barLength + 0.10
            session.tick()
            if bar == 7 {
                XCTAssertTrue(session.running)
                XCTAssertEqual(session.bossAttempt?.stamina, 1)
            }
            midi.onPadEvent?(PadInputEvent(padIndex: 12, velocity: 100, isNoteOn: true,
                                           timestamp: AVAudioTime.hostTime(forSeconds: time), deviceID: "touch"))
        }
        time += 0.40
        session.tick()
        XCTAssertEqual(session.bossAttempt?.won, true)
        XCTAssertTrue(progress.drummerPath.completedExamStageIDs.contains(boss.stageID))
        XCTAssertEqual(progress.drummerPath.availableKeys, before.availableKeys + 1)
        XCTAssertEqual(progress.progress(for: lesson.id)?.memory, false)
    }

    func testFirstVictoryOpensNextStageAndAwardsExactlyOneKey() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("progress.json")
        let catalog = LibraryCatalog(lessons: [makeLesson(id: 101, level: 1), makeLesson(id: 102, level: 2)])
        let stage = try XCTUnwrap(catalog.stages.first)
        let nextStage = try XCTUnwrap(catalog.stages.last)
        let lesson = try XCTUnwrap(stage.lessons.last)
        let store = ProgressStore(fileURL: file)
        store.recordResult(lessonId: lesson.id, passed: true, mastery: true, bpm: 101, score: 1, memory: false)
        let reloaded = ProgressStore(fileURL: file)
        let before = reloaded.drummerPath
        let records = reloaded.records
        XCTAssertFalse(before.completedExamStageIDs.contains(stage.id))
        let beforeMap = DrummerPathMapBuilder.buildStages(catalog: catalog, progress: records, pathState: before)
        XCTAssertFalse(try XCTUnwrap(beforeMap.first { $0.id == nextStage.id }).isStageOpen)

        try reloaded.recordBossVictory(stageID: stage.id, catalog: catalog)
        let first = reloaded.drummerPath
        XCTAssertEqual(first.completedExamStageIDs.subtracting(before.completedExamStageIDs), [stage.id])
        XCTAssertEqual(first.availableKeys, before.availableKeys + 1)
        XCTAssertEqual(reloaded.records, records)
        try reloaded.recordBossVictory(stageID: stage.id, catalog: catalog)
        XCTAssertEqual(reloaded.drummerPath, first)
        XCTAssertEqual(ProgressStore(fileURL: file).drummerPath.completedExamStageIDs, first.completedExamStageIDs)
        let afterMap = DrummerPathMapBuilder.buildStages(catalog: catalog, progress: records, pathState: first)
        XCTAssertTrue(try XCTUnwrap(afterMap.first { $0.id == nextStage.id }).isStageOpen)
    }

    private func makeLesson(id: Int = 91_251, bars: Int = 1, level: Int = 2, targetBpm: Int = 101,
                            hits: [LessonHit] = []) -> Lesson {
        Lesson(id: id, cat: "eighth", title: "Boss pattern", genre: "Funk", tags: [], text: "",
               division: 16, bars: bars, startBpm: 90, targetBpm: targetBpm, level: level, src: "test", hits: hits)
    }
}
