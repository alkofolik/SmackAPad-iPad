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

/// Published after a run finishes scoring to signal qualification for the current star.
struct RunVerdict: Identifiable, Equatable, Sendable {
    let id = UUID()
    let passed: Bool
    let brokenStreak: Bool
}

/// Summary of one completed run within a practice session.
struct PracticeRunResult: Identifiable, Equatable, Sendable {
    let id = UUID()
    let runNumber: Int
    let score: Double
    let bpm: Int
    let passed: Bool

    func accessibilityDescription(settings: SettingsManager) -> String {
        let passedText = settings.localized(passed ? "passed" : "not passed")
        let percent = Int((score * 100).rounded())
        return settings.localized("Run %lld: %lld percent, %lld BPM, %@", runNumber, percent, bpm, passedText)
    }
}

/// One display sample: tape position and repeat identity always share one clock read.
struct PatternFrame {
    let tapePosition: Double
    let totalSteps: Int
    let bpm: Int
    let countdown: Int?

    init(tapePosition: Double, totalSteps: Int, bpm: Int, countdown: Int? = nil) {
        self.tapePosition = tapePosition
        self.totalSteps = totalSteps
        self.bpm = bpm
        self.countdown = countdown
    }

    var pass: Int { Int(floor(tapePosition / Double(totalSteps))) + 1 }
    var position: Double { tapePosition.truncatingRemainder(dividingBy: Double(totalSteps)) }
    var missGraceSteps: Double { Double(bpm) / 15 * 0.2 }
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
    private(set) var currentRepetition = 1
    private(set) var lastResult: ScoringResult?
    private(set) var summary: RunSummary?
    private(set) var starEvent: StarEvent?
    private(set) var lastVerdict: RunVerdict?
    private(set) var runResults: [PracticeRunResult] = []
    private(set) var earnedBadgesInRun: [BadgeDefinition] = []
    private(set) var tempoUpEvent: TempoUpEvent?
    private(set) var errorMessage: String?
    private(set) var barVerdicts: [Int: BarVerdict] = [:]
    @ObservationIgnored private var judgmentsByPass: [Int: [LessonHit: HitJudgment]] = [:]
    private(set) var judgmentVersion = 0
    private(set) var padFlashes: [Int: PadFlash] = [:]
    private(set) var playedHits: [PlayedHit] = []
    private(set) var timingHistory = TimingHistory()
    @ObservationIgnored private var completedMatches = 0
    @ObservationIgnored private var completedExpected = 0
    @ObservationIgnored private var completedExtras = 0
    private(set) var starStreak: StarStreak
    private(set) var practiceMode: PracticeMode = .learning
    /// Keep pass identity so a previous repeat can never colour the new one.
    var hitJudgments: [Int: [LessonHit: HitJudgment]] {
        _ = judgmentVersion
        return judgmentsByPass
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
    @ObservationIgnored private let badgeStore = BadgeStore.shared
    @ObservationIgnored private let midi: MIDIInput
    @ObservationIgnored private let clock: () -> Double
    @ObservationIgnored private let audio = AudioEngine()
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var passes: [Pass] = []
    @ObservationIgnored private var countInEvents: [Double] = []
    @ObservationIgnored private var displayStart: Double = 0
    @ObservationIgnored private var completedPasses = 0
    @ObservationIgnored private var tempo = PracticeTempo()
    @ObservationIgnored private var earnedPass = false
    @ObservationIgnored private var earnedMastery = false
    @ObservationIgnored private var earnedMemory = false
    @ObservationIgnored private var stopAfterStar = false
    @ObservationIgnored private var runPadCount = 16
    private(set) var finishedByStar: Int?
    /// Best score and tempo of this run, written to the store once at STOP.
    /// Writing during a run re-encodes all progress and refreshes the library
    /// behind the practice cover, which caused the hitch at every pass boundary.
    @ObservationIgnored private var pendingScore: Float?
    @ObservationIgnored private var pendingBpm = 0
    @ObservationIgnored private var pendingCredit = false
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
        let padCount: Int
        let duration: Double
        let finalTime: Double
        var scorer: ScoringEngine?
        var sounds: [Sound]

        init(number: Int, start: Double, bpm: Int, lesson: Lesson, padCount: Int,
             listen: Bool, lessonSound: Bool, metronome: Bool, bpmStep: BpmStep) {
            self.number = number
            self.start = start
            self.bpm = bpm
            self.padCount = padCount
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

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput,
         clock: @escaping () -> Double = { AVAudioTime.seconds(forHostTime: mach_absolute_time()) }) {
        self.lesson = lesson
        self.starStreak = settings.practiceMode == .learning
            ? progress.learningCredit(lessonId: lesson.id, padCount: midi.activeProfile.padCount) : StarStreak()
        self.practiceMode = settings.practiceMode
        self.settings = settings
        self.progress = progress
        self.midi = midi
        self.clock = clock
        loopEndBar = lesson.bars - 1
        let saved = progress.progress(for: lesson.id)?.currentBpm ?? lesson.startBpm
        bpm = PracticeTempo.clamp(saved > 0 ? saved : lesson.startBpm)
        audio.setMetronomeVolume(Float(settings.metronomeVolume) / 100)
        audio.setPadsVolume(Float(settings.padsVolume) / 100)
        audio.setPatternVolume(Float(settings.patternVolume) / 100)
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

    func setMetronomeVolume(_ percent: Int) {
        audio.setMetronomeVolume(Float(percent) / 100)
    }

    func setPadsVolume(_ percent: Int) {
        audio.setPadsVolume(Float(percent) / 100)
    }

    func setPatternVolume(_ percent: Int) {
        audio.setPatternVolume(Float(percent) / 100)
    }

    func applyVolumes() {
        audio.setMetronomeVolume(Float(settings.metronomeVolume) / 100)
        audio.setPadsVolume(Float(settings.padsVolume) / 100)
        audio.setPatternVolume(Float(settings.patternVolume) / 100)
    }
    var isSectionLoop: Bool { loopStartBar != 0 || loopEndBar != lesson.bars - 1 }
    var repeatsPerRun: Int {
        guard !listen, !isSectionLoop else { return 1 }
        return max(1, Int((4.0 / Double(lesson.bars)).rounded()))
    }
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
    var scoredLesson: Lesson {
        let repeats = repeatsPerRun
        guard repeats > 1 else { return practiceLesson }
        let baseBars = lesson.bars
        let baseHits = practiceLesson.hits
        let baseHits8 = practiceLesson.hits8
        func repeatHits(_ hits: [LessonHit]) -> [LessonHit] {
            (0..<repeats).flatMap { k in
                hits.map {
                    LessonHit(step: $0.step + k * baseBars * 16, padIndex: $0.padIndex, hand: $0.hand, velocity: $0.velocity)
                }
            }
        }
        return Lesson(id: lesson.id, cat: lesson.cat, title: lesson.title, genre: lesson.genre,
                      tags: lesson.tags, text: lesson.text, division: lesson.division,
                      bars: repeats * baseBars, startBpm: lesson.startBpm,
                      targetBpm: lesson.targetBpm, level: lesson.level, score: lesson.score,
                      src: lesson.src, hits: repeatHits(baseHits), hits8: baseHits8.map(repeatHits),
                      eightNote: lesson.eightNote, intro: lesson.intro)
    }
    var savedProgress: LessonProgress? { progress.progress(for: lesson.id) }
    var timingWindows: (maximum: Double, good: Double) {
        let scorer = passes.last(where: { $0.start <= now })?.scorer
            ?? passes.last?.scorer
        return (scorer?.maximumTimingMilliseconds ?? 1, scorer?.goodTimingMilliseconds ?? 0)
    }

    /// The same matched/expected-plus-extra ratio as scoring, across this run.
    /// Future notes enter the denominator only once their matching window closes.
    var currentRunAccuracy: Double? {
        guard running, !listen else { return nil }
        let time = now
        var matches = completedMatches
        var denominator = completedExpected + completedExtras
        let hits = scoredLesson.hits(forPadCount: runPadCount)
        let baseCount = patternHits.count
        for pass in passes {
            guard let scorer = pass.scorer else { continue }
            let result = scorer.finish()
            let missed = hits.enumerated().filter { index, hit in
                let repIndex = baseCount > 0 ? index / baseCount : 0
                let cycle = (pass.number - 1) * repeatsPerRun + repIndex + 1
                let baseHit = patternHits.indices.contains(index % max(1, baseCount)) ? patternHits[index % max(1, baseCount)] : hit
                return pass.start + Double(hit.step) * 15 / Double(pass.bpm)
                    + scorer.maximumTimingMilliseconds / 1_000 <= time
                    && judgmentsByPass[cycle]?[baseHit] == nil
            }.count
            matches += result.matchedHitCount
            denominator += result.matchedHitCount + missed + result.extraHitCount
        }
        return denominator > 0 ? Double(matches) / Double(denominator) : nil
    }
    var patternHits: [LessonHit] { practiceLesson.hits(forPadCount: midi.activeProfile.padCount) }
    var starRunProgress: (count: Int, required: Int, name: String, starIndex: Int)? {
        guard !listen, !isSectionLoop else { return nil }
        let hitsCount = scoredLesson.hits(forPadCount: midi.activeProfile.padCount).count
        let required = StarStreak.requiredRuns(expectedHits: hitsCount, isIntro: lesson.cat == "intro")
        let passedRequired = StarStreak.requiredRuns(expectedHits: hitsCount)
        let saved = progress.progress(for: lesson.id)
        if saved?.passed != true { return (starStreak.passedRuns, passedRequired, "Passed", 0) }
        if fromMemory, saved?.memory != true { return (starStreak.memoryRuns, required, "From memory", 2) }
        if saved?.mastery != true { return (starStreak.masteryRuns, required, "Goal tempo", 1) }
        return nil
    }
    var available: Bool { midi.padIndices != nil }
    var patternFrame: PatternFrame { tapeFrame(seconds: now) }

    private func tapeFrame(seconds: Double) -> PatternFrame {
        let total = practiceLesson.bars * 16
        guard running else {
            return PatternFrame(tapePosition: 0, totalSteps: total, bpm: bpm, countdown: nil)
        }
        if let current = passes.last(where: { $0.start <= seconds }) {
            // Audio scheduling and drawing share native host seconds. A queued tempo
            // change alters the slope at its start, never the tape's accumulated distance.
            // Do not clamp at the pass end: a delayed scheduler tick cannot freeze drawing.
            let distance = Double((current.number - 1) * repeatsPerRun * total)
                + max(0, seconds - current.start) * Double(current.bpm) / 15
            return PatternFrame(tapePosition: distance, totalSteps: total, bpm: current.bpm, countdown: nil)
        }
        let start = passes.first?.start ?? displayStart
        guard start > 0 else {
            return PatternFrame(tapePosition: 0, totalSteps: total, bpm: bpm, countdown: nil)
        }
        let remainingBeats = (start - seconds) * Double(bpm) / 60
        let count = min(4, max(1, Int(ceil(remainingBeats))))
        return PatternFrame(tapePosition: 0, totalSteps: total, bpm: bpm, countdown: count)
    }
    var position: Double { patternFrame.position }

    /// Samples the tape for the frame SwiftUI is about to show, not for the moment
    /// the view body happens to run. Even frame spacing keeps the tape motion smooth.
    /// Never sample in the past: if a frame was delayed, drawing an outdated moment
    /// causes the next frame to catch up and visibly speed up across the gap.
    func patternFrame(at date: Date) -> PatternFrame {
        tapeFrame(seconds: now + min(0.05, max(0, date.timeIntervalSinceNow)))
    }

    func prepare() async {
        active = true
        midi.setLesson(lesson)
        midi.onPadEvent = { [weak self] event in self?.receive(event) }
        midi.onPracticeAction = { [weak self] action in self?.performControllerAction(action) }
        midi.stoppedPracticeTempo = { [weak self] in
            guard let self, self.active, self.ready, !self.running else { return nil }
            return self.bpm
        }
        midi.onPracticeTempo = { [weak self] bpm in
            guard let self, self.active, self.ready else { return }
            self.setTempo(bpm)
        }
        do {
            let engine = audio
            try await Task.detached(priority: .userInitiated) { try engine.prepare() }.value
            guard !Task.isCancelled, active else { audio.stop(); return }
            prepared = true
            applyVolumes()
            try audio.selectKit(resolvedKitId)
            try audio.start()
            ready = true
        } catch { errorMessage = error.localizedDescription }
    }

    func setTempo(_ tempo: Int) {
        guard !running else { return }
        bpm = PracticeTempo.clamp(tempo)
        saveTempo()
    }

    private func performControllerAction(_ action: MIDIPracticeAction) {
        guard active, ready else { return }
        switch action {
        case .startStop: if running { stop() } else { start() }
        case .restart: restart()
        case .listen: if !running { listen = true }
        case .tempoDown: setTempo(bpm - MIDIPracticeAction.tempoButtonStep)
        case .tempoUp: setTempo(bpm + MIDIPracticeAction.tempoButtonStep)
        }
    }

    func start() {
        guard ready, !running, available else { return }
        do {
            applyVolumes()
            try audio.selectKit(resolvedKitId)
            try audio.start()
            audio.logTiming("practice-start")
            errorMessage = nil
            summary = nil
            lastResult = nil
            starEvent = nil
            lastVerdict = nil
            tempoUpEvent = nil
            stopAfterStar = false
            finishedByStar = nil
            runResults = []
            practiceMode = settings.practiceMode
            runPadCount = midi.activeProfile.padCount
            starStreak = practiceMode == .learning
                ? progress.learningCredit(lessonId: lesson.id, padCount: midi.activeProfile.padCount) : StarStreak()
            earnedBadgesInRun = []
            pendingScore = nil; pendingBpm = 0; pendingCredit = false
            tempo.reset()
            barVerdicts = [:]
            judgmentsByPass = [:]
            playedHits = []
            timingHistory = TimingHistory()
            completedMatches = 0
            completedExpected = 0
            completedExtras = 0
            judgmentVersion += 1
            completedPasses = 0
            earnedPass = false; earnedMastery = false; earnedMemory = false
            passNumber = 1
            currentRepetition = 1
            let first = now + 0.6
            let beat = 60 / Double(bpm)
            countInEvents = (0..<4).map { first + Double($0) * beat }
            displayStart = first + 4 * beat
            passes = [makePass(number: 1, start: displayStart, bpm: bpm)]
            tempo.recordPassStart(bpm: bpm)
            BluetoothTimingDiagnostics.shared.startRun(lessonId: lesson.id, bpm: bpm)
            BluetoothTimingDiagnostics.shared.logPass(
                number: 1,
                startSeconds: displayStart,
                hostTime: AVAudioTime.hostTime(forSeconds: displayStart),
                bpm: bpm
            )
            if !listen {
                var record = progress.progress(for: lesson.id) ?? LessonProgress()
                record.hasPlayed = true
                record.currentBpm = bpm
                progress.setProgress(record, for: lesson.id)
                settings.lastLessonID = lesson.id
            }
            midi.resetControlPickup()
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
        let accuracy = currentRunAccuracy
        flushPendingProgress()
        stopAfterStar = false
        running = false
        BluetoothTimingDiagnostics.shared.stopRun()
        midi.resetControlPickup()
        if practiceMode == .challenge { starStreak.reset() }
        currentRepetition = 1
        tempoUpEvent = nil
        lastVerdict = nil
        playedHits = []
        judgmentsByPass = [:]
        judgmentVersion += 1
        countdown = nil
        task?.cancel(); task = nil
        passes = []; countInEvents = []
        audio.stop()
        if active { resume() }
        if let result = lastResult, !listen {
            summary = RunSummary(score: result.score, bpm: result.bpm, passes: completedPasses,
                                 passed: earnedPass, mastery: earnedMastery, memory: earnedMemory,
                                 finishedByStar: finishedByStar, runs: runResults)
        } else if !listen, let accuracy {
            summary = RunSummary(score: accuracy, bpm: bpm, passes: 0,
                                 passed: false, mastery: false, memory: false,
                                 runs: runResults)
        }
        saveTempo()
        evaluateBadges()
    }

    func restart() { stop(); start() }

    /// One store write per run instead of one per pass.
    private func flushPendingProgress() {
        if pendingCredit, practiceMode == .learning {
            progress.setLearningCredit(starStreak, lessonId: lesson.id, padCount: runPadCount, autoSave: false)
        }
        if let score = pendingScore {
            progress.recordResult(lessonId: lesson.id, passed: false, mastery: false,
                                  bpm: pendingBpm, score: score, autoSave: false)
        }
        pendingScore = nil
        pendingBpm = 0
        pendingCredit = false
    }

    func dismissSummary() { summary = nil }

    func suspend() {
        midi.resetControlPickup()
        stop()
        audio.stop()
        ready = false
    }

    func resume() {
        guard active, prepared else { return }
        do {
            applyVolumes()
            try audio.start()
            ready = true
        }
        catch { errorMessage = error.localizedDescription }
    }

    func close() {
        active = false
        suspend()
        midi.onPracticeAction = nil
        midi.stoppedPracticeTempo = nil
        midi.onPracticeTempo = nil
        midi.resetControlPickup()
        midi.onPadEvent = nil
        midi.setLesson(nil)
    }

    /// The future scoring bar-summary adapter supplies these values. No timing
    /// thresholds or invented judgments are duplicated in the presentation layer.
    func receiveBarSummary(bar: Int, pass: Int, verdict: BarVerdict) {
        guard !listen, pass == passNumber, (0..<lesson.bars).contains(bar) else { return }
        barVerdicts[bar] = verdict
    }

    private var now: Double { clock() }

    private func makePass(number: Int, start: Double, bpm: Int) -> Pass {
        Pass(number: number, start: start, bpm: bpm, lesson: scoredLesson, padCount: runPadCount,
             listen: listen, lessonSound: lessonSound, metronome: metronome, bpmStep: settings.bpmStepEnum)
    }

    /// Internal so session tests can advance a supplied host clock without waiting.
    func tick() {
        let time = now
        finishCompleted(at: time)
        if stopAfterStar {
            stop()
            return
        }
        let horizon = time + 0.5
        // Decide the next BPM from the run's result as known so far. Notes whose
        // matching window has closed count as usual; notes still inside their window
        // are left out of that decision.
        if let last = passes.last, last.start + last.duration <= horizon {
            if let scorer = last.scorer {
                let early = scorer.earlyResult(at: AVAudioTime.hostTime(forSeconds: time))
                tempo.completed(nextBpm: early.nextBpm)
            } else if let lastResult, last.number == completedPasses {
                tempo.completed(nextBpm: lastResult.nextBpm)
            }
            let nextBpm = tempo.queue(after: last.bpm, targetBpm: lesson.targetBpm,
                                      listenBpm: listen ? bpm : nil)
            let nextPass = makePass(number: last.number + 1, start: last.start + last.duration,
                                    bpm: nextBpm)
            passes.append(nextPass)
            BluetoothTimingDiagnostics.shared.logPass(
                number: nextPass.number,
                startSeconds: nextPass.start,
                hostTime: AVAudioTime.hostTime(forSeconds: nextPass.start),
                bpm: nextPass.bpm
            )
        }
        if let current = passes.last(where: { $0.start <= time }) {
            let total = practiceLesson.bars * 16
            let elapsed = max(0, time - current.start) * Double(current.bpm) / 15
            let rep = total > 0 ? min(repeatsPerRun, max(1, Int(floor(elapsed / Double(total))) + 1)) : 1
            if currentRepetition != rep { currentRepetition = rep }

            if current.number != passNumber {
                // Announce a tempo increase at the moment the faster pass
                // actually starts (audible change). Not on the first pass and
                // not on manual changes (which are blocked while running).
                if !listen, let event = tempo.tempoUpEvent(newBpm: current.bpm) {
                    tempoUpEvent = event
                }
                tempo.recordPassStart(bpm: current.bpm)
                passNumber = current.number
                if !barVerdicts.isEmpty { barVerdicts = [:] }
            }
            let currentCycle = (current.number - 1) * repeatsPerRun + (total > 0 ? Int(floor(elapsed / Double(total))) : 0) + 1
            let minCycle = max(1, currentCycle - 3)
            if judgmentsByPass.keys.contains(where: { $0 < minCycle }) {
                judgmentsByPass = judgmentsByPass.filter { $0.key >= minCycle }
                judgmentVersion += 1
            }
            if playedHits.contains(where: { $0.pass < minCycle }) {
                playedHits.removeAll { $0.pass < minCycle }
            }
            // Observation publishes every assignment, even an equal value. Writing
            // these 100x per second re-rendered the whole practice screen.
            if bpm != current.bpm { bpm = current.bpm }
            if countdown != nil { countdown = nil }
        } else if let first = passes.first {
            let next = min(4, max(1, Int(ceil((first.start - time) * Double(bpm) / 60))))
            if countdown != next { countdown = next }
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
            completedMatches += result.matchedHitCount
            completedExpected += result.expectedHitCount
            completedExtras += result.extraHitCount
            completedPasses += 1
            let runPassed: Bool
            if !isSectionLoop {
                let memory = fromMemory && result.bpm >= lesson.targetBpm && result.score >= 0.8
                let required = StarStreak.requiredRuns(expectedHits: result.expectedHitCount, isIntro: lesson.cat == "intro")
                let passed = result.passed || (practiceMode == .learning && StarStreak.learningPassed(
                    score: result.score, perfectOrGoodHits: result.perfectOrGoodHitCount,
                    expectedHits: result.expectedHitCount, errors: result.errorCount))
                let saved = progress.progress(for: lesson.id)
                runPassed = {
                    if saved?.passed != true { return passed }
                    if fromMemory, saved?.memory != true { return memory }
                    if saved?.mastery != true { return result.mastery }
                    return result.passed
                }()
                let streakWasReset: Bool = {
                    guard practiceMode == .challenge && !runPassed else { return false }
                    if saved?.passed != true { return starStreak.passedRuns > 0 }
                    if fromMemory, saved?.memory != true { return starStreak.memoryRuns > 0 }
                    if saved?.mastery != true { return starStreak.masteryRuns > 0 }
                    return false
                }()
                let stars = starStreak.record(passed: passed, mastery: result.mastery,
                                              memory: memory, requiredRuns: required,
                                              passedRequired: StarStreak.requiredRuns(expectedHits: result.expectedHitCount),
                                              mode: practiceMode)
                lastVerdict = RunVerdict(passed: runPassed, brokenStreak: streakWasReset)
                if practiceMode == .learning { pendingCredit = true }
                earnedPass = earnedPass || stars.passed
                earnedMastery = earnedMastery || stars.mastery
                earnedMemory = earnedMemory || stars.memory
                let award = StarAward(previous: progress.progress(for: lesson.id),
                                      passed: stars.passed, mastery: stars.mastery, memory: stars.memory)
                pendingScore = max(pendingScore ?? 0, Float(result.score))
                pendingBpm = max(pendingBpm, result.bpm)
                if award.fresh.contains(true) {
                    // A new star is rare and must be visible at once (library, next-star text).
                    progress.recordResult(lessonId: lesson.id, passed: stars.passed, mastery: stars.mastery,
                                          bpm: result.bpm, score: Float(result.score), memory: stars.memory, autoSave: false)
                    if practiceMode == .learning {
                        progress.setLearningCredit(starStreak, lessonId: lesson.id, padCount: pass.padCount, autoSave: false)
                        pendingCredit = false
                    }
                    starEvent = StarEvent(award: award)
                    evaluateBadges()
                }
                stopAfterStar = award.shouldStop
                if award.shouldStop { finishedByStar = award.fresh[2] ? 3 : 2 }
            } else {
                runPassed = result.passed
                lastVerdict = RunVerdict(passed: result.passed, brokenStreak: false)
            }
            runResults.append(PracticeRunResult(runNumber: runResults.count + 1,
                                                score: result.score,
                                                bpm: result.bpm,
                                                passed: runPassed))
            // The tempo preference is saved once at STOP, not at every pass.
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
        var matchedFeedback: HitFeedback?
        var currentScorerCenter: Double?
        var matchedPassNumber = passNumber

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
            if let error = best.3.timingErrorMilliseconds {
                timingHistory.record(errorMilliseconds: error,
                                     maximumMilliseconds: best.1.maximumTimingMilliseconds,
                                     goodMilliseconds: best.1.goodTimingMilliseconds)
            }
            mark = record(best.3, pass: best.0.number, padIndex: event.padIndex)
            matchedFeedback = best.3
            currentScorerCenter = best.1.currentTimingCenterMilliseconds
            matchedPassNumber = best.0.number
        } else if let pass = passes.first(where: { $0.start <= adjusted && adjusted < $0.start + $0.duration }) {
            if let feedback = pass.scorer?.receive(padIndex: event.padIndex, at: timestamp) {
                mark = record(feedback, pass: pass.number, padIndex: event.padIndex)
                matchedFeedback = feedback
                currentScorerCenter = pass.scorer?.currentTimingCenterMilliseconds
                matchedPassNumber = pass.number
            }
        } else {
            let activePass = passes.last(where: { $0.start <= adjusted }) ?? passes.last ?? passes.first
            currentScorerCenter = activePass?.scorer?.currentTimingCenterMilliseconds
            if let activePass { matchedPassNumber = activePass.number }
        }
        recordPlayedHit(padIndex: event.padIndex, at: adjusted, mark: mark)

        BluetoothTimingDiagnostics.shared.logNoteOn(
            deviceID: event.deviceID,
            rawTimestamp: event.rawTimestamp,
            receiptTimestamp: event.receiptTimestamp,
            resolvedTimestamp: event.timestamp,
            usedReceiptTime: event.usedReceiptTime,
            expectedStep: matchedFeedback?.expectedStep,
            timingErrorMs: matchedFeedback?.timingErrorMilliseconds,
            timingCenterMs: currentScorerCenter,
            passNumber: matchedPassNumber
        )
    }

    private func recordPlayedHit(padIndex: Int, at time: Double, mark: HitMark?) {
        guard let pass = passes.last(where: { $0.start <= time }) ?? passes.first else { return }
        let total = practiceLesson.bars * 16
        guard total > 0 else { return }
        let elapsedSteps = max(0, time - pass.start) * Double(pass.bpm) / 15
        let repIndex = Int(floor(elapsedSteps / Double(total)))
        let cycle = (pass.number - 1) * repeatsPerRun + repIndex + 1
        let localStep = elapsedSteps.truncatingRemainder(dividingBy: Double(total))
        playedHits.append(PlayedHit(padIndex: padIndex, step: localStep, pass: cycle, mark: mark))
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
        guard !hits.isEmpty else { return mark }
        if let index = feedback.expectedHitIndex {
            let baseCount = hits.count
            let baseHit = hits[index % baseCount]
            let repIndex = index / baseCount
            let cycle = (pass - 1) * repeatsPerRun + repIndex + 1
            judgmentsByPass[cycle, default: [:]][baseHit] = feedback.judgment
            judgmentVersion += 1
        }
        return mark
    }

    private func saveTempo() {
        var record = progress.progress(for: lesson.id) ?? LessonProgress()
        record.currentBpm = bpm
        progress.setProgress(record, for: lesson.id)
    }

    private func evaluateBadges() {
        let newly = badgeStore.evaluate(
            progress: progress.records,
            catalog: ProgressionManager.shared.catalog
        )
        for badge in newly {
            if !earnedBadgesInRun.contains(where: { $0.id == badge.id }) {
                earnedBadgesInRun.append(badge)
            }
        }
    }

    func badgeSummaryMessage(settings: SettingsManager) -> String? {
        guard !earnedBadgesInRun.isEmpty else { return nil }
        if earnedBadgesInRun.count == 1 {
            let name = settings.localized(earnedBadgesInRun[0].name)
            return settings.localized("New badge: %@", name)
        } else {
            return settings.localized("Earned %lld new badges", earnedBadgesInRun.count)
        }
    }
}
