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

/// Published when one or more badges are earned during a run.
struct BadgeBannerEvent: Identifiable, Equatable {
    let id = UUID()
    let badges: [BadgeDefinition]
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
struct MixLessonResult: Identifiable {
    let id: Int
    let title: String
    var score: Double?
    var barCounts: [String: Int] = [:]
    var unmeasuredBars: Int
}

@MainActor
@Observable
final class PracticeSession {
    private(set) var lesson: Lesson
    let mixLessons: [Lesson]
    var isMix: Bool { mixLessons.count >= 2 }
    private(set) var mixIndex = 0
    private(set) var mixResults: [MixLessonResult] = []
    @ObservationIgnored private var mixNeedsAdvance = false
    @ObservationIgnored private var mixAppearances: [Int: Int] = [:]
    @ObservationIgnored private var mixStreaks: [Int: StarStreak] = [:]
    @ObservationIgnored private var mixBarVerdicts: [Int: BarVerdict] = [:]
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
    private(set) var badgeBannerEvent: BadgeBannerEvent?
    private(set) var earnedFirstMasteryInRun = false
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
    private(set) var playbackMode: LessonPlaybackMode = .play
    var listen: Bool {
        get { playbackMode == .listen }
        set { playbackMode = newValue ? .listen : .play }
    }
    var afterMe: Bool { playbackMode == .afterMe }
    private(set) var bestResponseScore: Double?

    func selectPlaybackMode(_ mode: LessonPlaybackMode) {
        guard !running, !isMix, mode != playbackMode else { return }
        playbackMode = mode
        summary = nil
        lastResult = nil
        reviewFeedback = nil
        starEvent = nil
    }

    func afterMePhase(at frame: PatternFrame) -> String {
        frame.countdown == nil && frame.pass.isMultiple(of: 2) ? "Your turn" : "Listen…"
    }

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
    @ObservationIgnored private let currentDay: () -> String
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
    @ObservationIgnored private var currentMixRoundMemory = true
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
        let responseStart: Double?
        var scorer: ScoringEngine?
        var sounds: [Sound]

        init(number: Int, start: Double, bpm: Int, lesson: Lesson, padCount: Int,
             listen: Bool, lessonSound: Bool, metronome: Bool, bpmStep: BpmStep, callLesson: Lesson? = nil) {
            self.number = number
            self.start = start
            self.bpm = bpm
            self.padCount = padCount
            duration = Double(lesson.bars) * 240 / Double(bpm)
            let hits = lesson.hits(forPadCount: padCount)
            let lastHit = Double(hits.map(\.step).max() ?? 0) * 15 / Double(bpm)
            let window = lesson.level <= 2 ? 0.2 : lesson.level <= 4 ? 0.175 : 0.15
            responseStart = callLesson.map { start + Double($0.bars) * 240 / Double(bpm) }
            finalTime = callLesson == nil ? start + max(duration, lastHit + window) : start + duration
            scorer = listen ? nil : ScoringEngine(lesson: lesson, bpm: bpm,
                startTimestamp: AVAudioTime.hostTime(forSeconds: start), padCount: padCount, bpmStep: bpmStep)
            var events: [Sound] = []
            if listen || lessonSound || callLesson != nil {
                let soundHits = callLesson?.hits(forPadCount: padCount) ?? hits
                events += soundHits.map { Sound(time: start + Double($0.step) * 15 / Double(bpm), pad: $0.padIndex, velocity: $0.velocity) }
            }
            if metronome && !listen {
                events += (0..<(lesson.bars * 4)).map {
                    Sound(time: start + Double($0) * 60 / Double(bpm), pad: nil, velocity: 100)
                }
            }
            sounds = events.sorted { $0.time < $1.time }
        }

        func acceptsInput(at time: Double) -> Bool {
            guard let responseStart else { return true }
            // Host-clock round trips can land a hit that is exactly on the boundary a
            // few nanoseconds early, so the response start gets a 0.1 ms tolerance.
            return time >= responseStart - 0.0001 && time < start + duration
        }
    }

    public private(set) var reviewFeedback: ReviewScheduler.ReviewFeedback?

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput,
         initialFromMemory: Bool = false, initialBpm: Int? = nil,
         mixLessons: [Lesson] = [], initialAfterMe: Bool = false,
         clock: @escaping () -> Double = { AVAudioTime.seconds(forHostTime: mach_absolute_time()) },
         currentDay: @escaping () -> String = { AppCalendar.today() }) {
        let activeLesson = mixLessons.count >= 2 ? mixLessons[0] : lesson
        self.lesson = activeLesson
        self.mixLessons = mixLessons
        self.playbackMode = initialAfterMe && mixLessons.count < 2 ? .afterMe : .play
        self.starStreak = settings.practiceMode == .learning
            ? progress.learningCredit(lessonId: activeLesson.id, padCount: midi.activeProfile.padCount) : StarStreak()
        self.practiceMode = settings.practiceMode
        self.settings = settings
        self.progress = progress
        self.midi = midi
        self.clock = clock
        self.currentDay = currentDay
        self.fromMemory = initialFromMemory
        loopEndBar = activeLesson.bars - 1
        let saved = initialBpm ?? progress.progress(for: activeLesson.id)?.currentBpm ?? activeLesson.startBpm
        bpm = PracticeTempo.clamp(mixLessons.count >= 2 ? activeLesson.targetBpm : (saved > 0 ? saved : activeLesson.startBpm))
        audio.setMetronomeVolume(Float(settings.metronomeVolume) / 100)
        audio.setPadsVolume(Float(settings.padsVolume) / 100)
        audio.setPatternVolume(Float(settings.patternVolume) / 100)
    }

    public var isDueReview: Bool {
        !afterMe && !isMix && progress.progress(for: lesson.id)?.reviewSchedule.isDue(on: currentDay()) == true
    }

    public var reviewStep: Int {
        (progress.progress(for: lesson.id)?.reviewStep ?? 0) + 1
    }

    public func reviewStatusText(settings: SettingsManager) -> String {
        let step = reviewStep
        return settings.localized("Review · step %lld of 4", step)
    }

    public var showsMemoryFadePhase: Bool {
        !afterMe && fromMemory && running && !listen && !isSectionLoop && settings.fadeMemoryNotes && passNumber < 3
    }

    public func memoryPhaseText(settings: SettingsManager) -> String {
        passNumber == 1 ? settings.localized("Pass 1 · notes shown") : settings.localized("Pass 2 · notes fading")
    }

    public func noteVisibility(pass: Int) -> NoteVisibility {
        if afterMe { return .hidden }
        return NoteVisibility.derive(
            fromMemory: fromMemory,
            running: running,
            listen: listen,
            isSectionLoop: isSectionLoop,
            pass: pass,
            fadeNotes: settings.fadeMemoryNotes
        )
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
        if afterMe { return 2 }
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
    /// One cycle is twice the phrase length. Only response notes are expected;
    /// the call is scheduled separately as sound and never enters scoring.
    var afterMeLesson: Lesson {
        let phrase = practiceLesson
        func responseHits(_ hits: [LessonHit]) -> [LessonHit] {
            hits.map { LessonHit(step: $0.step + phrase.bars * 16, padIndex: $0.padIndex,
                                 hand: $0.hand, velocity: $0.velocity) }
        }
        return Lesson(id: phrase.id, cat: phrase.cat, title: phrase.title, genre: phrase.genre,
                      tags: phrase.tags, text: phrase.text, division: phrase.division,
                      bars: phrase.bars * 2, startBpm: phrase.startBpm, targetBpm: phrase.targetBpm,
                      level: phrase.level, score: phrase.score, src: phrase.src,
                      hits: responseHits(phrase.hits), hits8: phrase.hits8.map(responseHits),
                      eightNote: phrase.eightNote, intro: phrase.intro, access: phrase.access)
    }
    var scoredLesson: Lesson {
        if afterMe { return afterMeLesson }
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
        if afterMe, afterMePhase(at: patternFrame) != "Your turn" { return nil }
        var matches = completedMatches
        var denominator = completedExpected + completedExtras
        let hits = scoredLesson.hits(forPadCount: runPadCount)
        let baseCount = patternHits.count
        for pass in passes {
            guard let scorer = pass.scorer else { continue }
            let result = scorer.finish()
            let missed = hits.enumerated().filter { index, hit in
                let repIndex = baseCount > 0 ? index / baseCount : 0
                let cycle = (pass.number - 1) * repeatsPerRun + (afterMe ? 2 : repIndex + 1)
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
    /// True on the same calendar day as the goal-tempo star (Star 2).
    /// Star 3 cannot be earned today; today From memory is practice only.
    var isMemoryPracticeToday: Bool {
        guard !listen, !afterMe else { return false }
        let saved = progress.progress(for: lesson.id)
        guard let saved, saved.mastery, !saved.memory else { return false }
        if let masteryDay = saved.masteryDay {
            return masteryDay == currentDay()
        }
        return false
    }

    var starRunProgress: (count: Int, required: Int, name: String, starIndex: Int)? {
        guard !listen, !afterMe, !isSectionLoop else { return nil }
        let hitsCount = scoredLesson.hits(forPadCount: midi.activeProfile.padCount).count
        let required = StarStreak.requiredRuns(expectedHits: hitsCount, isIntro: lesson.cat == "intro")
        let passedRequired = StarStreak.requiredRuns(expectedHits: hitsCount)
        let saved = progress.progress(for: lesson.id)
        if saved?.passed != true { return (starStreak.passedRuns, passedRequired, "Passed", 0) }
        if fromMemory, saved?.memory != true {
            if StarStreak.mayEarnMemoryCredit(
                progress: saved,
                today: currentDay(),
                fromMemory: true,
                bpm: lesson.targetBpm,
                targetBpm: lesson.targetBpm,
                score: 1.0,
                pass: passNumber,
                fadeNotes: settings.fadeMemoryNotes
            ) {
                return (starStreak.memoryRuns, required, "From memory", 2)
            }
            return nil
        }
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
            guard let self, self.active, self.ready, !self.running, !self.isMix else { return nil }
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
        guard !running, !isMix else { return }
        bpm = PracticeTempo.clamp(tempo)
        saveTempo()
    }

    private func performControllerAction(_ action: MIDIPracticeAction) {
        guard active, ready else { return }
        switch action {
        case .startStop: if running { stop() } else { start() }
        case .restart: restart()
        case .listen: if !running && !isMix { listen = true }
        case .tempoDown: setTempo(bpm - MIDIPracticeAction.tempoButtonStep)
        case .tempoUp: setTempo(bpm + MIDIPracticeAction.tempoButtonStep)
        }
    }

    func start() {
        guard ready, !running, available else { return }
        do {
            if isMix {
                mixIndex = 0
                lesson = mixLessons[0]
                bpm = PracticeTempo.clamp(lesson.targetBpm)
                listen = false
                loopStartBar = 0
                loopEndBar = lesson.bars - 1
                midi.setLesson(lesson)
                mixAppearances = [:]
                mixStreaks = [:]
                mixNeedsAdvance = false
                currentMixRoundMemory = true
                mixBarVerdicts = [:]
                mixResults = mixLessons.map {
                    MixLessonResult(id: $0.id, title: $0.title, score: nil,
                                    unmeasuredBars: $0.bars * max(1, Int((4.0 / Double($0.bars)).rounded())))
                }
            }
            applyVolumes()
            try audio.selectKit(resolvedKitId)
            try audio.start()
            audio.logTiming("practice-start")
            errorMessage = nil
            summary = nil
            lastResult = nil
            bestResponseScore = nil
            reviewFeedback = nil
            starEvent = nil
            lastVerdict = nil
            tempoUpEvent = nil
            stopAfterStar = false
            finishedByStar = nil
            earnedFirstMasteryInRun = false
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
            if !listen && !afterMe {
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
        if afterMe {
            summary = RunSummary(score: lastResult?.score ?? 0, bpm: bpm, passes: completedPasses,
                                 passed: false, mastery: false, memory: false, runs: runResults)
        } else if let result = lastResult, !listen {
            summary = RunSummary(score: result.score, bpm: result.bpm, passes: completedPasses,
                                 passed: earnedPass, mastery: earnedMastery, memory: earnedMemory,
                                 finishedByStar: finishedByStar, runs: runResults,
                                 firstStar2: earnedFirstMasteryInRun)
        } else if isMix {
            summary = RunSummary(score: mixResults.compactMap(\.score).last ?? 0, bpm: bpm,
                                 passes: runResults.count, passed: earnedPass, mastery: earnedMastery,
                                 memory: earnedMemory, runs: runResults)
        } else if !listen, let accuracy {
            summary = RunSummary(score: accuracy, bpm: bpm, passes: 0,
                                 passed: false, mastery: false, memory: false,
                                 runs: runResults)
        }
        if !afterMe { saveTempo() }
        if reviewFeedback != nil {
            try? progress.save()
        }
        if !afterMe { evaluateBadges() }
    }

    func restart() { stop(); start() }

    /// One store write per run instead of one per pass.
    private func flushPendingProgress() {
        if pendingCredit, practiceMode == .learning {
            progress.setLearningCredit(starStreak, lessonId: lesson.id, padCount: runPadCount, autoSave: false)
        }
        if let score = pendingScore {
            progress.recordResult(lessonId: lesson.id, passed: false, mastery: false,
                                  bpm: pendingBpm, score: score, autoSave: false, today: currentDay())
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
        guard !listen, pass == passNumber, (0..<practiceLesson.bars).contains(bar),
              !afterMe || currentRepetition == 2 else { return }
        barVerdicts[bar] = verdict
        if isMix { mixBarVerdicts[(currentRepetition - 1) * lesson.bars + bar] = verdict }
    }

    /// Flush the old lesson before swapping it. Only the pattern schedule changes;
    /// the prepared audio engine and MIDI callbacks remain owned by this session.
    private func advanceMix() {
        mixNeedsAdvance = false
        mixIndex = (mixIndex + 1) % mixLessons.count
        lesson = mixLessons[mixIndex]
        bpm = PracticeTempo.clamp(lesson.targetBpm)
        loopStartBar = 0
        loopEndBar = lesson.bars - 1
        midi.setLesson(lesson)
        midi.resetControlPickup()
        var record = progress.progress(for: lesson.id) ?? LessonProgress()
        record.hasPlayed = true
        record.currentBpm = bpm
        progress.setProgress(record, for: lesson.id, autoSave: false)
        settings.lastLessonID = lesson.id
        starStreak = mixStreaks[lesson.id] ?? (practiceMode == .learning
            ? progress.learningCredit(lessonId: lesson.id, padCount: runPadCount) : StarStreak())
        passNumber = (mixAppearances[lesson.id] ?? 0) + 1
        currentRepetition = 1
        lastResult = nil
        lastVerdict = nil
        starEvent = nil
        reviewFeedback = nil
        finishedByStar = nil
        tempoUpEvent = nil
        barVerdicts = [:]
        mixBarVerdicts = [:]
        judgmentsByPass = [:]
        judgmentVersion += 1
        playedHits = []
        padFlashes = [:]
        timingHistory = TimingHistory()
        completedMatches = 0
        completedExpected = 0
        completedExtras = 0
        do {
            try audio.selectKit(resolvedKitId)
            // Anchor AFTER kit/layout work to native host time. No events from the
            // next lesson were queued early; four clicks use the new goal tempo.
            let first = now + 0.6
            let beat = 60 / Double(bpm)
            countInEvents = (0..<4).map { first + Double($0) * beat }
            displayStart = first + 4 * beat
            passes = [makePass(number: passNumber, start: displayStart, bpm: bpm)]
            countdown = 4
            BluetoothTimingDiagnostics.shared.startRun(lessonId: lesson.id, bpm: bpm)
        } catch {
            errorMessage = error.localizedDescription
            stop()
        }
    }

    private var now: Double { clock() }

    private func makePass(number: Int, start: Double, bpm: Int) -> Pass {
        Pass(number: number, start: start, bpm: bpm, lesson: scoredLesson, padCount: runPadCount,
             listen: listen, lessonSound: afterMe ? false : lessonSound,
             metronome: afterMe || metronome, bpmStep: settings.bpmStepEnum,
             callLesson: afterMe ? practiceLesson : nil)
    }

    /// Internal so session tests can advance a supplied host clock without waiting.
    func tick() {
        let time = now
        finishCompleted(at: time)
        if isMix, mixNeedsAdvance {
            advanceMix()
            return
        }
        if stopAfterStar {
            stop()
            return
        }
        let horizon = time + 0.5
        // Decide the next BPM from the run's result as known so far. Notes whose
        // matching window has closed count as usual; notes still inside their window
        // are left out of that decision.
        if !isMix, let last = passes.last, last.start + last.duration <= horizon {
            if !afterMe, let scorer = last.scorer {
                let early = scorer.earlyResult(at: AVAudioTime.hostTime(forSeconds: time))
                tempo.completed(nextBpm: early.nextBpm)
            } else if !afterMe, let lastResult, last.number == completedPasses {
                tempo.completed(nextBpm: lastResult.nextBpm)
            }
            let nextBpm = afterMe ? last.bpm : tempo.queue(after: last.bpm, targetBpm: lesson.targetBpm,
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
                if !listen, !afterMe, let event = tempo.tempoUpEvent(newBpm: current.bpm) {
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
            if afterMe {
                bestResponseScore = max(bestResponseScore ?? 0, result.score)
                lastVerdict = RunVerdict(passed: result.passed, brokenStreak: false)
                runResults.append(PracticeRunResult(runNumber: runResults.count + 1, score: result.score,
                                                    bpm: result.bpm, passed: result.passed))
                progress.recordAfterMeResponse(lessonId: lesson.id, score: result.score, today: currentDay(), autoSave: true)
                evaluateBadges(onlyGroup: .training)
                continue
            }
            let runPassed: Bool
            if !isSectionLoop {
                let saved = progress.progress(for: lesson.id)

                let isHiddenPass = !fromMemory || !settings.fadeMemoryNotes || pass.number >= 3

                // Ticket 98 spaced review evaluation: only hidden passes (3+) count as review
                if isHiddenPass,
                   let currentProgress = saved,
                   currentProgress.reviewSchedule.isDue(on: currentDay()) {
                    let outcome = ReviewScheduler.evaluate(
                        schedule: currentProgress.reviewSchedule,
                        today: currentDay(),
                        isFullRun: !isSectionLoop,
                        fromMemory: fromMemory,
                        bpm: result.bpm,
                        targetBpm: lesson.targetBpm,
                        score: Float(result.score),
                        pass: pass.number,
                        fadeNotes: settings.fadeMemoryNotes
                    )
                    if let feedback = outcome.feedback {
                        self.reviewFeedback = feedback
                        progress.updateReviewSchedule(outcome.newSchedule, for: lesson.id, autoSave: false)
                        switch feedback {
                        case .passed, .settled:
                            progress.recordReviewRun(lessonId: lesson.id, passed: true, today: currentDay(), autoSave: false)
                        case .failed:
                            progress.recordReviewRun(lessonId: lesson.id, passed: false, today: currentDay(), autoSave: false)
                        case .doesNotCount:
                            break
                        }
                        evaluateBadges()
                    }
                }

                let memoryCredit = StarStreak.mayEarnMemoryCredit(
                    progress: saved,
                    today: currentDay(),
                    fromMemory: fromMemory,
                    bpm: result.bpm,
                    targetBpm: lesson.targetBpm,
                    score: result.score,
                    isSectionLoop: isSectionLoop,
                    pass: pass.number,
                    fadeNotes: settings.fadeMemoryNotes
                )
                let memoryRunPassed = fromMemory && result.bpm >= lesson.targetBpm && result.score >= 0.8 && isHiddenPass
                let required = StarStreak.requiredRuns(expectedHits: result.expectedHitCount, isIntro: lesson.cat == "intro")
                let passed = result.passed || (practiceMode == .learning && StarStreak.learningPassed(
                    score: result.score, perfectOrGoodHits: result.perfectOrGoodHitCount,
                    expectedHits: result.expectedHitCount, errors: result.errorCount))
                runPassed = {
                    if saved?.passed != true { return passed }
                    if fromMemory, saved?.memory != true { return isHiddenPass ? memoryRunPassed : result.passed }
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
                let stars = starStreak.record(passed: fromMemory ? false : passed,
                                              mastery: fromMemory ? false : result.mastery,
                                              memory: memoryCredit, requiredRuns: required,
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
                if award.fresh[1] {
                    earnedFirstMasteryInRun = true
                }
                if award.fresh.contains(true) {
                    // A new star is rare and must be visible at once (library, next-star text).
                    progress.recordResult(lessonId: lesson.id, passed: stars.passed, mastery: stars.mastery,
                                          bpm: result.bpm, score: Float(result.score), memory: stars.memory,
                                          autoSave: false, today: currentDay())
                    if practiceMode == .learning {
                        progress.setLearningCredit(starStreak, lessonId: lesson.id, padCount: pass.padCount, autoSave: false)
                        pendingCredit = false
                    }
                    starEvent = StarEvent(award: award)
                    evaluateBadges()
                }
                stopAfterStar = !isMix && award.shouldStop
                if award.shouldStop { finishedByStar = award.fresh[2] ? 3 : 2 }
            } else {
                runPassed = result.passed
                lastVerdict = RunVerdict(passed: result.passed, brokenStreak: false)
            }
            runResults.append(PracticeRunResult(runNumber: runResults.count + 1,
                                                score: result.score,
                                                bpm: result.bpm,
                                                passed: runPassed))
            if isMix {
                flushPendingProgress()
                mixStreaks[lesson.id] = starStreak
                mixAppearances[lesson.id, default: 0] += 1
                if let index = mixResults.firstIndex(where: { $0.id == lesson.id }) {
                    mixResults[index].score = result.score
                    mixResults[index].barCounts = Dictionary(grouping: mixBarVerdicts.values, by: \.rawValue).mapValues(\.count)
                    mixResults[index].unmeasuredBars = max(0, scoredLesson.bars - mixBarVerdicts.count)
                }
                let isHiddenPass = !fromMemory || !settings.fadeMemoryNotes || pass.number >= 3
                let runMemoryPass = fromMemory && isHiddenPass && result.score >= 0.80
                if !runMemoryPass {
                    currentMixRoundMemory = false
                }
                if mixIndex == mixLessons.count - 1 {
                    progress.recordFinishedMixRound(isMemoryRound: currentMixRoundMemory, today: currentDay(), autoSave: false)
                    currentMixRoundMemory = true
                }
                try? progress.save()
                evaluateBadges()
                mixNeedsAdvance = true
            }
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
        // Boundary ownership follows the calibrated input timestamp, never the
        // display tick. Call hits cannot match even an early response note.
        if afterMe, !passes.contains(where: { $0.acceptsInput(at: adjusted) }) {
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
            guard pass.acceptsInput(at: adjusted), var scorer = pass.scorer else { continue }
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
        } else if let pass = passes.first(where: { $0.start <= adjusted && adjusted < $0.start + $0.duration && $0.acceptsInput(at: adjusted) }) {
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
            let cycle = (pass - 1) * repeatsPerRun + (afterMe ? 2 : repIndex + 1)
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

    private func evaluateBadges(onlyGroup: BadgeGroup? = nil) {
        let newly = badgeStore.evaluate(
            progress: progress.records,
            catalog: ProgressionManager.shared.catalog,
            trainingLog: progress.trainingLog,
            onlyGroup: onlyGroup
        )
        guard !newly.isEmpty else { return }
        var fresh: [BadgeDefinition] = []
        for badge in newly {
            if !earnedBadgesInRun.contains(where: { $0.id == badge.id }) {
                earnedBadgesInRun.append(badge)
                fresh.append(badge)
            }
        }
        if !fresh.isEmpty {
            badgeBannerEvent = BadgeBannerEvent(badges: fresh)
        }
    }

    func clearBadgeBannerEvent() {
        badgeBannerEvent = nil
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
