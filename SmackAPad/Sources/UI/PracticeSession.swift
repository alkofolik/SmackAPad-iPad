import AVFoundation
import Darwin
import Observation

struct StarEvent: Identifiable {
    let id = UUID()
    let award: StarAward
}

/// Published when a pass begins at a higher tempo than the previous pass.
/// Manual tempo changes do not trigger this event.
struct TempoUpEvent: Identifiable {
    let id = UUID()
    let from: Int
    let to: Int
}

/// Owns one continuous practice run, with native host times shared by sound and scoring.
/// The view only reads position; display refreshes never determine audible note times.
@MainActor
@Observable
final class PracticeSession {
    let lesson: Lesson
    private(set) var bpm: Int
    private(set) var running = false
    private(set) var ready = false
    private(set) var countdown: Int?
    private(set) var passNumber = 1
    private(set) var lastResult: ScoringResult?
    private(set) var summary: RunSummary?
    private(set) var starEvent: StarEvent?
    private(set) var tempoUpEvent: TempoUpEvent?
    private(set) var errorMessage: String?
    private(set) var barVerdicts: [Int: BarVerdict] = [:]
    @ObservationIgnored private var judgmentsByPass: [Int: [LessonHit: HitJudgment]] = [:]
    private(set) var judgmentVersion = 0
    private(set) var padFlashes: [Int: PadFlash] = [:]
    private(set) var playedHits: [PlayedHit] = []
    private(set) var starStreak = StarStreak()
    /// How the notes of the pass on screen were played, keyed by the note itself.
    var hitJudgments: [LessonHit: HitJudgment] {
        _ = judgmentVersion
        return judgmentsByPass[passNumber] ?? [:]
    }
    /// A note not struck this long after its time is shown as missed.
    var missGraceSteps: Double { Double(bpm) * 4 / 60 * 0.2 }
    var listen = false
    var fromMemory = false
    var lessonSound = false
    var metronome = true
    var loopStartBar = 0 {
        didSet { if loopEndBar < loopStartBar { loopEndBar = loopStartBar } }
    }
    var loopEndBar: Int

    @ObservationIgnored private let settings: SettingsManager
    @ObservationIgnored private let progress: ProgressStore
    @ObservationIgnored private let midi: MIDIInput
    @ObservationIgnored private let audio = AudioEngine()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var passes: [Pass] = []
    @ObservationIgnored private var countInEvents: [Double] = []
    @ObservationIgnored private var displayStart: Double = 0
    @ObservationIgnored private var displayDuration: Double = 1
    @ObservationIgnored private var completedPasses = 0
    @ObservationIgnored private var tempo = PracticeTempo()
    @ObservationIgnored private var earnedPass = false
    @ObservationIgnored private var earnedMastery = false
    @ObservationIgnored private var earnedMemory = false
    @ObservationIgnored private var stopAfterStar = false
    @ObservationIgnored private var prepared = false
    @ObservationIgnored private var active = false

    private struct Sound {
        let time: Double
        let pad: Int?
        let velocity: Int
    }

    private final class Pass {
        let number: Int
        let start: Double
        let bpm: Int
        let duration: Double
        let finalTime: Double
        var scorer: ScoringEngine?
        var sounds: [Sound]

        init(number: Int, start: Double, bpm: Int, lesson: Lesson, padCount: Int,
             listen: Bool, lessonSound: Bool, metronome: Bool, bpmStep: BpmStep) {
            self.number = number
            self.start = start
            self.bpm = bpm
            duration = Double(lesson.bars) * 240 / Double(bpm)
            let hits = lesson.hits(forPadCount: padCount)
            let lastHit = Double(hits.map(\.step).max() ?? 0) * 15 / Double(bpm)
            let window = lesson.level <= 2 ? 0.2 : lesson.level <= 4 ? 0.175 : 0.15
            finalTime = start + max(duration, lastHit + window)
            scorer = listen ? nil : ScoringEngine(lesson: lesson, bpm: bpm,
                startTimestamp: AVAudioTime.hostTime(forSeconds: start), padCount: padCount, bpmStep: bpmStep)
            var events: [Sound] = []
            if listen || lessonSound {
                events += hits.map { Sound(time: start + Double($0.step) * 15 / Double(bpm), pad: $0.padIndex, velocity: $0.velocity) }
            }
            if metronome && !listen {
                events += (0..<(lesson.bars * 4)).map {
                    Sound(time: start + Double($0) * 60 / Double(bpm), pad: nil, velocity: 100)
                }
            }
            sounds = events.sorted { $0.time < $1.time }
        }
    }

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput) {
        self.lesson = lesson
        self.settings = settings
        self.progress = progress
        self.midi = midi
        loopEndBar = lesson.bars - 1
        let saved = progress.progress(for: lesson.id)?.currentBpm ?? lesson.startBpm
        bpm = min(400, max(30, saved > 0 ? saved : lesson.startBpm))
    }

    var hits: [LessonHit] { lesson.hits(forPadCount: midi.activeProfile.padCount) }
    var kits: [SampleKit] { audio.availableKits }
    var availableKitsDict: [String: SampleKit] {
        Dictionary(uniqueKeysWithValues: kits.map { ($0.kitId, $0) })
    }
    var resolvedKitId: String {
        SoundKitResolver.resolveKitId(for: lesson, settings: settings, kits: availableKitsDict)
    }
    var automaticKitPickerLabel: String {
        let resolved = SoundKitResolver.resolve(for: lesson, settings: settings, kits: availableKitsDict)
        return settings.localized("Automatic · %@", resolved.kitShortName)
    }

    func applyResolvedKit() {
        guard ready, !running else { return }
        try? audio.selectKit(resolvedKitId)
    }
    var isSectionLoop: Bool { loopStartBar != 0 || loopEndBar != lesson.bars - 1 }
    var practiceLesson: Lesson {
        guard isSectionLoop else { return lesson }
        func slice(_ hits: [LessonHit]) -> [LessonHit] {
            hits.filter { $0.step >= loopStartBar * 16 && $0.step < (loopEndBar + 1) * 16 }.map {
                LessonHit(step: $0.step - loopStartBar * 16, padIndex: $0.padIndex, hand: $0.hand, velocity: $0.velocity)
            }
        }
        return Lesson(id: lesson.id, cat: lesson.cat, title: lesson.title, genre: lesson.genre,
                      tags: lesson.tags, text: lesson.text, division: lesson.division,
                      bars: loopEndBar - loopStartBar + 1, startBpm: lesson.startBpm,
                      targetBpm: lesson.targetBpm, level: lesson.level, score: lesson.score,
                      src: lesson.src, hits: slice(lesson.hits), hits8: lesson.hits8.map(slice),
                      eightNote: lesson.eightNote, intro: lesson.intro)
    }
    var savedProgress: LessonProgress? { progress.progress(for: lesson.id) }
    var patternHits: [LessonHit] { practiceLesson.hits(forPadCount: midi.activeProfile.padCount) }
    var starRunProgress: (count: Int, required: Int, name: String)? {
        guard running, !listen, !isSectionLoop else { return nil }
        let required = StarStreak.requiredRuns(expectedHits: patternHits.count, isIntro: lesson.cat == "intro")
        guard required > 1 else { return nil }
        let saved = progress.progress(for: lesson.id)
        if saved?.passed != true { return (starStreak.passedRuns, required, "Passed") }
        if fromMemory, saved?.memory != true { return (starStreak.memoryRuns, required, "From memory") }
        if saved?.mastery != true { return (starStreak.masteryRuns, required, "Goal tempo") }
        return nil
    }
    var available: Bool { midi.padIndices != nil }
    var position: Double {
        guard running, countdown == nil else { return 0 }
        let seconds = AVAudioTime.seconds(forHostTime: mach_absolute_time())
        return min(Double(practiceLesson.bars * 16) - 0.0001,
                   max(0, (seconds - displayStart) / displayDuration * Double(practiceLesson.bars * 16)))
    }

    func prepare() async {
        active = true
        midi.setLesson(lesson)
        midi.onPadEvent = { [weak self] event in self?.receive(event) }
        do {
            let engine = audio
            try await Task.detached(priority: .userInitiated) { try engine.prepare() }.value
            guard !Task.isCancelled, active else { audio.stop(); return }
            prepared = true
            try audio.selectKit(resolvedKitId)
            try audio.start()
            ready = true
        } catch { errorMessage = error.localizedDescription }
    }

    func setTempo(_ tempo: Int) {
        guard !running else { return }
        bpm = min(400, max(30, tempo))
        saveTempo()
    }

    func start() {
        guard ready, !running, available else { return }
        do {
            try audio.selectKit(resolvedKitId)
            try audio.start()
            audio.logTiming("practice-start")
            errorMessage = nil
            summary = nil
            lastResult = nil
            starEvent = nil
            tempoUpEvent = nil
            stopAfterStar = false
            tempo.reset()
            starStreak.reset()
            barVerdicts = [:]
            judgmentsByPass = [:]
            playedHits = []
            judgmentVersion += 1
            completedPasses = 0
            earnedPass = false; earnedMastery = false; earnedMemory = false
            passNumber = 1
            let first = now + 0.6
            let beat = 60 / Double(bpm)
            countInEvents = (0..<4).map { first + Double($0) * beat }
            displayStart = first + 4 * beat
            displayDuration = Double(practiceLesson.bars) * 240 / Double(bpm)
            passes = [makePass(number: 1, start: displayStart, bpm: bpm)]
            tempo.recordPassStart(bpm: bpm)
            if !listen {
                var record = progress.progress(for: lesson.id) ?? LessonProgress()
                record.hasPlayed = true
                record.currentBpm = bpm
                progress.setProgress(record, for: lesson.id)
                settings.lastLessonID = lesson.id
            }
            running = true
            countdown = 4
            task = Task { [weak self] in
                while !Task.isCancelled {
                    guard let self, self.running else { return }
                    self.tick()
                    try? await Task.sleep(for: .milliseconds(10))
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func stop() {
        guard running else { return }
        // Credit complete passes only; stopping halfway cannot earn a star.
        // An automatic stop already credited the winning pass. Discard everything
        // queued after it, even if the app was delayed long enough to finish it.
        if !stopAfterStar { finishCompleted(at: now) }
        stopAfterStar = false
        running = false
        starStreak.reset()
        playedHits = []
        countdown = nil
        task?.cancel(); task = nil
        passes = []; countInEvents = []
        audio.stop()
        if active { resume() }
        if let result = lastResult, !listen {
            summary = RunSummary(score: result.score, bpm: result.bpm, passes: completedPasses,
                                 passed: earnedPass, mastery: earnedMastery, memory: earnedMemory)
        }
        saveTempo()
    }

    func restart() { stop(); start() }

    func suspend() {
        stop()
        audio.stop()
        ready = false
    }

    func resume() {
        guard active, prepared else { return }
        do { try audio.start(); ready = true }
        catch { errorMessage = error.localizedDescription }
    }

    func close() {
        active = false
        suspend()
        midi.onPadEvent = nil
        midi.setLesson(nil)
    }

    /// The future scoring bar-summary adapter supplies these values. No timing
    /// thresholds or invented judgments are duplicated in the presentation layer.
    func receiveBarSummary(bar: Int, pass: Int, verdict: BarVerdict) {
        guard !listen, pass == passNumber, (0..<lesson.bars).contains(bar) else { return }
        barVerdicts[bar] = verdict
    }

    private var now: Double { AVAudioTime.seconds(forHostTime: mach_absolute_time()) }

    private func makePass(number: Int, start: Double, bpm: Int) -> Pass {
        Pass(number: number, start: start, bpm: bpm, lesson: practiceLesson, padCount: midi.activeProfile.padCount,
             listen: listen, lessonSound: lessonSound, metronome: metronome, bpmStep: settings.bpmStepEnum)
    }

    private func tick() {
        let time = now
        finishCompleted(at: time)
        if stopAfterStar {
            stop()
            return
        }
        let horizon = time + 0.5
        // Results arrive after the next pass has been queued. Advance from the
        // last queued tempo, never from an earlier pass's slower clock.
        if let last = passes.last, last.start + last.duration <= horizon {
            let nextBpm = tempo.queue(after: last.bpm, targetBpm: lesson.targetBpm,
                                      listenBpm: listen ? bpm : nil)
            passes.append(makePass(number: last.number + 1, start: last.start + last.duration,
                                   bpm: nextBpm))
        }
        if let current = passes.last(where: { $0.start <= time }) {
            if current.number != passNumber {
                // Announce a tempo increase at the moment the faster pass
                // actually starts (audible change). Not on the first pass and
                // not on manual changes (which are blocked while running).
                if !listen, let event = tempo.tempoUpEvent(newBpm: current.bpm) {
                    tempoUpEvent = event
                }
                tempo.recordPassStart(bpm: current.bpm)
                passNumber = current.number
                barVerdicts = [:]
                judgmentsByPass = judgmentsByPass.filter { $0.key >= current.number }
                judgmentVersion += 1
            }
            bpm = current.bpm
            displayStart = current.start
            displayDuration = current.duration
            countdown = nil
        } else if let first = passes.first {
            countdown = min(4, max(1, Int(ceil((first.start - time) * Double(bpm) / 60))))
        }
        do {
            while let click = countInEvents.first, click <= horizon {
                try audio.scheduleClick(audibleHostTime: AVAudioTime.hostTime(forSeconds: click))
                countInEvents.removeFirst()
            }
            for pass in passes {
                while let sound = pass.sounds.first, sound.time <= horizon {
                    let timestamp = AVAudioTime.hostTime(forSeconds: sound.time)
                    if let pad = sound.pad {
                        try audio.schedule(padIndex: pad, velocity: sound.velocity, audibleHostTime: timestamp)
                    } else { try audio.scheduleClick(audibleHostTime: timestamp) }
                    pass.sounds.removeFirst()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            stop()
        }
        passes.removeAll { $0.finalTime < time && $0.scorer == nil && $0.number < passNumber }
    }

    private func finishCompleted(at time: Double) {
        for pass in passes where pass.finalTime <= time {
            guard let scorer = pass.scorer else { continue }
            let result = scorer.finish()
            pass.scorer = nil
            lastResult = result
            tempo.completed(nextBpm: result.nextBpm)
            completedPasses += 1
            if !isSectionLoop {
                let memory = fromMemory && result.bpm >= lesson.targetBpm && result.score >= 0.8
                let required = StarStreak.requiredRuns(expectedHits: result.expectedHitCount, isIntro: lesson.cat == "intro")
                let stars = starStreak.record(passed: result.passed, mastery: result.mastery,
                                              memory: memory, requiredRuns: required)
                earnedPass = earnedPass || stars.passed
                earnedMastery = earnedMastery || stars.mastery
                earnedMemory = earnedMemory || stars.memory
                let award = StarAward(previous: progress.progress(for: lesson.id),
                                      passed: stars.passed, mastery: stars.mastery, memory: stars.memory)
                progress.recordResult(lessonId: lesson.id, passed: stars.passed, mastery: stars.mastery,
                                      bpm: result.bpm, score: Float(result.score), memory: stars.memory, autoSave: false)
                if award.fresh.contains(true) { starEvent = StarEvent(award: award) }
                stopAfterStar = award.shouldStop
            }
            // currentBpm is a preference, including manually lowered tempos.
            saveTempo()
            if let error = progress.lastSaveError { errorMessage = error.localizedDescription }
            if stopAfterStar { return }
        }
    }

    private func receive(_ event: PadInputEvent) {
        guard event.isNoteOn, ready else { return }
        audio.play(padIndex: event.padIndex, velocity: event.velocity)
        padFlashes[event.padIndex] = PadFlash(mark: nil, date: Date())
        guard running else { return }
        let sourceTime = AVAudioTime.seconds(forHostTime: event.timestamp)
        let adjusted = max(0, sourceTime - settings.calibrationOffset(for: event.deviceID) / 1_000)
        guard !listen else {
            recordPlayedHit(padIndex: event.padIndex, at: adjusted, mark: nil)
            return
        }
        let timestamp = AVAudioTime.hostTime(forSeconds: adjusted)
        var mark: HitMark?
        // Probe value copies so early notes at the next boundary and late notes
        // at the previous boundary go to one scorer, never to both.
        var best: (Pass, ScoringEngine, Double, HitFeedback)?
        for pass in passes {
            guard var scorer = pass.scorer else { continue }
            let feedback = scorer.receive(padIndex: event.padIndex, at: timestamp)
            if let error = feedback.timingErrorMilliseconds,
               best == nil || abs(error) < best!.2 {
                best = (pass, scorer, abs(error), feedback)
            }
        }
        if let best {
            best.0.scorer = best.1
            mark = record(best.3, pass: best.0.number, padIndex: event.padIndex)
        } else if let pass = passes.first(where: { $0.start <= adjusted && adjusted < $0.start + $0.duration }) {
            if let feedback = pass.scorer?.receive(padIndex: event.padIndex, at: timestamp) {
                mark = record(feedback, pass: pass.number, padIndex: event.padIndex)
            }
        }
        recordPlayedHit(padIndex: event.padIndex, at: adjusted, mark: mark)
    }

    private func recordPlayedHit(padIndex: Int, at time: Double, mark: HitMark?) {
        guard let pass = passes.last(where: { $0.start <= time }) ?? passes.first else { return }
        // Use the actual strike position, even if scoring matched a neighbouring pass.
        let step = (time - pass.start) * Double(pass.bpm) / 15
        playedHits.append(PlayedHit(padIndex: padIndex, step: step, pass: pass.number, mark: mark))
    }

    /// Colour feedback only. Scoring itself is unchanged.
    private func record(_ feedback: HitFeedback, pass: Int, padIndex: Int) -> HitMark {
        let mark: HitMark
        switch feedback.judgment {
        case .perfect, .good: mark = .correct
        case .off: mark = .off
        case .wrongPad: mark = .wrong
        }
        padFlashes[padIndex] = PadFlash(mark: mark, date: Date())
        let hits = patternHits
        if let index = feedback.expectedHitIndex, hits.indices.contains(index) {
            judgmentsByPass[pass, default: [:]][hits[index]] = feedback.judgment
            judgmentVersion += 1
        }
        return mark
    }

    private func saveTempo() {
        var record = progress.progress(for: lesson.id) ?? LessonProgress()
        record.currentBpm = bpm
        progress.setProgress(record, for: lesson.id)
    }
}
