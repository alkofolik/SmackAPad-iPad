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
    let isGoal: Bool

    init(from: Int, to: Int, isGoal: Bool = false) {
        self.from = from
        self.to = to
        self.isGoal = isGoal
    }
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
    var met: Bool = false
    var counted: Bool = true
    var earnedStars: [Bool] = [false, false, false]
    var starEvent: StarEvent?
    var reviewFeedback: ReviewScheduler.ReviewFeedback?
}

@MainActor
@Observable
final class PracticeSession {
    private static weak var audioOwner: PracticeSession?
    private(set) var lesson: Lesson
    let mixLessons: [Lesson]
    let unscored: Bool
    let stopAfterSinglePass: Bool
    @ObservationIgnored var onSinglePassEnded: (() -> Void)?
    var isMix: Bool { mixLessons.count >= LearningRules.minimumMixLessons }
    private(set) var mixIndex = 0
    private(set) var mixResults: [MixLessonResult] = []
    var previousMixResult: (index: Int, result: MixLessonResult)? {
        guard isMix, mixIndex > 0, mixResults.indices.contains(mixIndex - 1) else { return nil }
        return (mixIndex - 1, mixResults[mixIndex - 1])
    }
    var isMixFullyMet: Bool {
        guard isMix, !mixResults.isEmpty, mixResults.allSatisfy({ $0.score != nil }) else { return false }
        if fromMemory {
            return currentMixRoundMemory && mixResults.allSatisfy { $0.met }
        }
        return mixResults.allSatisfy { $0.met }
    }
    @ObservationIgnored private var mixNeedsAdvance = false
    @ObservationIgnored private var mixBarVerdicts: [Int: BarVerdict] = [:]
    @ObservationIgnored private var mixFreshStars: [Bool] = [false, false, false]
    @ObservationIgnored private var mixEarnedStars: [Bool] = [false, false, false]
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
    @ObservationIgnored private let audio = AudioEngine.practice
    @ObservationIgnored private var kitTask: Task<Void, Never>?
    @ObservationIgnored private var selectedKitRequest: String?
    @ObservationIgnored private var suspended = false
    @ObservationIgnored private var audioStarted = false
    @ObservationIgnored private var runID = UUID()
    @ObservationIgnored private var runOutputRoute = AudioOutputRoute.other
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var passes: [Pass] = []
    @ObservationIgnored private var countInEvents: [Double] = []
    @ObservationIgnored private var displayStart: Double = 0
    @ObservationIgnored private var completedPasses = 0
    @ObservationIgnored private var tempo = PracticeTempo()
    @ObservationIgnored private var earnedPass = false
    @ObservationIgnored private var earnedMastery = false
    @ObservationIgnored private var earnedMemory = false
    @ObservationIgnored private var stopAfterPass = false
    @ObservationIgnored private var runPadCount = 16
    private(set) var finishedByStar: Int?
    private(set) var finishedByReview = false
    private(set) var memoryWarmUp = LearningRules.MemoryWarmUp()

    private struct DailyReviewWindow {
        let day: String
        var state = ReviewScheduler.WindowState()
        var outcome: ReviewScheduler.Outcome?
    }
    private var reviewWindows: [Int: DailyReviewWindow] = [:]
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
            let window = lesson.level <= LearningRules.beginnerTimingMaximumLevel
                ? LearningRules.beginnerTimingMilliseconds.maximum / 1_000
                : lesson.level <= LearningRules.intermediateTimingMaximumLevel
                    ? LearningRules.intermediateTimingMilliseconds.maximum / 1_000
                    : LearningRules.advancedTimingMilliseconds.maximum / 1_000
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
            return time >= responseStart - LearningRules.afterMeResponseToleranceSeconds && time < start + duration
        }
    }

    public private(set) var reviewFeedback: ReviewScheduler.ReviewFeedback?
    private(set) var reviewPendingReason: PracticeStepOutcome.Reason?

    var todayStepOutcome: PracticeStepOutcome? {
        guard !isSectionLoop, !afterMe, !listen, let best = runResults.map(\.score).max() else { return nil }
        return PracticeStepOutcome(bestScore: best, reviewFeedback: reviewFeedback,
                                   reviewPendingReason: reviewPendingReason)
    }

    init(lesson: Lesson, settings: SettingsManager, progress: ProgressStore, midi: MIDIInput,
         initialFromMemory: Bool = false, initialBpm: Int? = nil,
         mixLessons: [Lesson] = [], initialAfterMe: Bool = false,
         unscored: Bool = false, stopAfterSinglePass: Bool = false,
         clock: @escaping () -> Double = { AVAudioTime.seconds(forHostTime: mach_absolute_time()) },
         currentDay: @escaping () -> String = { AppCalendar.today() }) {
        let activeLesson = mixLessons.count >= LearningRules.minimumMixLessons ? mixLessons[0] : lesson
        self.lesson = activeLesson
        self.mixLessons = mixLessons
        self.unscored = unscored
        self.stopAfterSinglePass = stopAfterSinglePass
        self.playbackMode = initialAfterMe && mixLessons.count < LearningRules.minimumMixLessons ? .afterMe : .play
        self.starStreak = !unscored && settings.practiceMode == .learning
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
        bpm = PracticeTempo.clamp(mixLessons.count >= LearningRules.minimumMixLessons ? activeLesson.targetBpm : (saved > 0 ? saved : activeLesson.startBpm))
    }

    public var isDueReview: Bool {
        guard !unscored, !afterMe, !isMix, let schedule = savedProgress?.reviewSchedule else { return false }
        return schedule.isDueReview(on: currentDay())
    }

    var showsReviewStatus: Bool {
        !unscored && !afterMe && !isMix && reviewStatusText(for: lesson.id, settings: settings) != nil
    }

    public var reviewStep: Int {
        (progress.progress(for: lesson.id)?.reviewStep ?? 0) + 1
    }

    public func reviewStatusText(settings: SettingsManager) -> String {
        reviewStatusText(for: lesson.id, settings: settings) ?? ""
    }

    func reviewStatusText(for lessonID: Int, settings: SettingsManager) -> String? {
        guard !unscored, !afterMe else { return nil }
        let today = currentDay()
        let window = reviewWindows[lessonID].flatMap { $0.day == today ? $0 : nil }
        if let feedback = window?.outcome?.feedback {
            if case .failed = feedback {
                return settings.localized("Review not passed · again tomorrow · practice goes on")
            }
            return feedback.message(language: settings.languagePreference)
        }
        guard let schedule = progress.progress(for: lessonID)?.reviewSchedule,
              schedule.isDueReview(on: today) else { return nil }
        if window == nil, progress.progress(for: lessonID)?.isUnstartedLegacyReview == true {
            return settings.localized("Review · start from memory")
        }
        return settings.localized("Review · %lld of 2 passed", window?.state.successes ?? 0)
    }

    public var completedWarmUps: Int {
        memoryWarmUp.consecutivePasses
    }

    public var memoryWarmUpNotesHidden: Bool {
        memoryWarmUp.areNotesHidden(fadeNotes: settings.fadeMemoryNotes)
    }

    public var showsMemoryFadePhase: Bool {
        !afterMe && fromMemory && running && !listen && !isSectionLoop && settings.fadeMemoryNotes
    }

    public var noteVisibility: NoteVisibility {
        if afterMe { return .hidden }
        return NoteVisibility.derive(
            fromMemory: fromMemory,
            running: running,
            listen: listen,
            isSectionLoop: isSectionLoop,
            warmUp: memoryWarmUp,
            fadeNotes: settings.fadeMemoryNotes
        )
    }

    /// Maps a single-phrase cycle index (`PatternFrame.pass`) to the scored run number (`Pass.number`).
    func runNumber(for framePass: Int) -> Int {
        max(1, (max(1, framePass) - 1) / max(1, repeatsPerRun) + 1)
    }

    func noteVisibility(at frame: PatternFrame) -> NoteVisibility {
        noteVisibility
    }

    var hits: [LessonHit] { lesson.hits(forPadCount: midi.activeProfile.padCount) }
    private(set) var kits: [SampleKit] = []
    var availableKitsDict: [String: SampleKit] {
        Dictionary(uniqueKeysWithValues: kits.map { ($0.kitId, $0) })
    }
    var resolvedKitId: String {
        resolveKit(for: lesson)
    }
    private func resolveKit(for lesson: Lesson) -> String {
        SoundKitResolver.resolveKitId(for: lesson, settings: settings, kits: availableKitsDict)
    }
    var automaticKitPickerLabel: String {
        let resolved = SoundKitResolver.resolve(for: lesson, settings: settings, kits: availableKitsDict)
        return settings.localized("Automatic · %@", resolved.kitShortName)
    }

    func applyResolvedKit() {
        guard active, prepared, !suspended, !running else { return }
        loadKit(resolvedKitId) { try $0.startAudio() }
    }

    func setMetronomeVolume(_ percent: Int) {
        guard active else { return }
        audio.setMetronomeVolume(Float(percent) / 100)
    }

    func setPadsVolume(_ percent: Int) {
        guard active else { return }
        audio.setPadsVolume(Float(percent) / 100)
    }

    func setPatternVolume(_ percent: Int) {
        guard active else { return }
        audio.setPatternVolume(Float(percent) / 100)
    }

    func setInstrumentTrims(_ trims: [String: Int]) {
        guard active else { return }
        audio.setInstrumentTrims(trims)
    }

    func applyVolumes() {
        audio.setInstrumentTrims(settings.instrumentTrims)
        audio.setMetronomeVolume(Float(settings.metronomeVolume) / 100)
        audio.setPadsVolume(Float(settings.padsVolume) / 100)
        audio.setPatternVolume(Float(settings.patternVolume) / 100)
    }
    var isSectionLoop: Bool { loopStartBar != 0 || loopEndBar != lesson.bars - 1 }
    var repeatsPerRun: Int {
        if afterMe { return 2 }
        guard !listen, !isSectionLoop else { return 1 }
        return max(1, Int((LearningRules.practiceRunBars / Double(lesson.bars)).rounded()))
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
        guard !unscored, !listen, !afterMe, !isSectionLoop else { return nil }
        let hitsCount = scoredLesson.hits(forPadCount: midi.activeProfile.padCount).count
        let required = StarStreak.requiredRuns(expectedHits: hitsCount, isIntro: lesson.cat == "intro")
        let passedRequired = StarStreak.requiredRuns(expectedHits: hitsCount)
        let saved = progress.progress(for: lesson.id)
        if saved?.passed != true { return (starStreak.passedRuns, passedRequired, "Passed", 0) }
        if saved?.mastery != true { return (starStreak.masteryRuns, required, "Goal tempo", 1) }
        return nil
    }

    var reviewRunProgress: (count: Int, required: Int, settled: Bool)? {
        guard !listen, !afterMe, !isSectionLoop, isDueReview else { return nil }
        let today = currentDay()
        let window = reviewWindows[lesson.id].flatMap { $0.day == today ? $0 : nil }
        let count = window?.outcome != nil ? LearningRules.reviewDecisionPasses : (window?.state.successes ?? 0)
        let settled = (savedProgress?.reviewSchedule.reviewStep ?? 0) >= LearningRules.lastReviewStep
        return (min(LearningRules.reviewDecisionPasses, count), LearningRules.reviewDecisionPasses, settled)
    }
    var available: Bool { midi.padIndices != nil }
    var patternFrame: PatternFrame { tapeFrame(seconds: now) }

    static func runFraction(tapePosition: Double, totalSteps: Int, repeatsPerRun: Int) -> Double {
        let runSteps = Double(totalSteps) * Double(repeatsPerRun)
        guard runSteps > 0 else { return 0 }
        return min(1, max(0, tapePosition.truncatingRemainder(dividingBy: runSteps) / runSteps))
    }

    func runMeterFraction(at frame: PatternFrame) -> Double {
        let repeats = repeatsPerRun
        let runNumber = runNumber(for: frame.pass)
        // The tape can reach the next run before the previous verdict is published.
        // Keep the finished block full until the verdict banks or drains it.
        if passes.contains(where: { $0.number == runNumber - 1 && $0.scorer != nil }) {
            return 1
        }
        return Self.runFraction(tapePosition: frame.tapePosition,
                                totalSteps: frame.totalSteps, repeatsPerRun: repeats)
    }

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
        guard !active else { return }
        Self.audioOwner?.close()
        Self.audioOwner = self
        active = true
        #if DEBUG
        let started = DispatchTime.now()
        defer {
            AudioEngine.logDuration("prepare", since: started)
            if ready { AudioEngine.logFootprint(lessonID: lesson.id) }
        }
        #endif
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
            let catalog = try await audio.prepare()
            guard !Task.isCancelled, active else { return }
            kits = catalog
            prepared = true
            guard !suspended else { return }
            let task = loadKit(resolvedKitId) { try $0.startAudio() }
            await withTaskCancellationHandler {
                await task?.value
            } onCancel: {
                task?.cancel()
            }
        } catch {
            if active, !Task.isCancelled { errorMessage = error.localizedDescription }
        }
    }

    @discardableResult
    private func loadKit(
        _ id: String, onReady: @escaping (PracticeSession) throws -> Void
    ) -> Task<Void, Never>? {
        kitTask?.cancel()
        kitTask = nil
        if selectedKitRequest == id {
            finishKitChange(onReady)
            return nil
        }
        if running { midi.setPracticeSound(nil) }
        else { setReady(false) }
        let task = Task { [weak self, audio] in
            do {
                let kit = try await audio.loadKit(id)
                guard let self, !Task.isCancelled else { return }
                audio.selectKit(kit)
                self.selectedKitRequest = id
                self.kitTask = nil
                self.finishKitChange(onReady)
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.kitTask = nil
                self.failKitChange(error)
            }
        }
        kitTask = task
        return task
    }

    private func finishKitChange(_ onReady: (PracticeSession) throws -> Void) {
        do { try onReady(self) }
        catch { failKitChange(error) }
    }

    private func failKitChange(_ error: Error) {
        errorMessage = error.localizedDescription
        if running { stop() }
    }

    private func setReady(_ ready: Bool) {
        self.ready = ready
        midi.setPracticeSound(ready ? audio : nil)
    }

    private func startAudio(onRunAudioChange: (@MainActor @Sendable () -> Void)? = nil) throws {
        applyVolumes()
        runOutputRoute = try audio.start(onRunAudioChange: onRunAudioChange)
        audioStarted = true
        setReady(true)
    }

    func setTempo(_ tempo: Int) {
        guard !running else { return }
        bpm = PracticeTempo.clamp(tempo)
        if !isMix { saveTempo() }
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
        let startingFreshMix = isMix && (mixResults.isEmpty || summary != nil)
        let kit = resolveKit(for: startingFreshMix ? (mixLessons.first ?? lesson) : lesson)
        loadKit(kit) { $0.beginRun() }
    }

    private func makeInitialMixResults() -> [MixLessonResult] {
        mixLessons.map {
            let record = progress.progress(for: $0.id)
            return MixLessonResult(
                id: $0.id,
                title: $0.title,
                score: nil,
                unmeasuredBars: $0.bars * max(1, Int((LearningRules.practiceRunBars / Double($0.bars)).rounded())),
                met: false,
                counted: true,
                earnedStars: [record?.passed ?? false, record?.mastery ?? false, record?.memory ?? false],
                starEvent: nil,
                reviewFeedback: nil
            )
        }
    }

    private func beginRun() {
        do {
            let startingFreshMix = isMix && (mixResults.isEmpty || summary != nil)
            if isMix {
                listen = false
                mixNeedsAdvance = false
                if startingFreshMix {
                    mixIndex = 0
                    lesson = mixLessons[0]
                    bpm = PracticeTempo.clamp(lesson.targetBpm)
                    currentMixRoundMemory = true
                    mixBarVerdicts = [:]
                    mixFreshStars = [false, false, false]
                    mixEarnedStars = [false, false, false]
                    mixResults = makeInitialMixResults()
                }
                loopStartBar = 0
                loopEndBar = lesson.bars - 1
                midi.setLesson(lesson)
            }
            let id = UUID()
            try startAudio { [weak self] in
                guard let self, self.running, self.runID == id else { return }
                self.errorMessage = self.settings.localized("Audio output changed. Run stopped, press Start to continue.")
                self.stop(restarting: false, audioSessionChanged: true)
            }
            audio.logTiming("practice-start")
            errorMessage = nil
            summary = nil
            lastResult = nil
            bestResponseScore = nil
            // STOP abandons undecided review windows; decided outcomes survive restarts.
            let today = currentDay()
            if !unscored {
                reviewWindows = reviewWindows.filter { $0.value.day == today && $0.value.outcome != nil }
                reviewFeedback = afterMe ? nil : reviewWindows[lesson.id]?.outcome?.feedback
            } else {
                reviewFeedback = nil
            }
            finishedByReview = false
            starEvent = nil
            lastVerdict = nil
            tempoUpEvent = nil
            stopAfterPass = false
            finishedByStar = nil
            if !isMix || startingFreshMix {
                earnedFirstMasteryInRun = false
                runResults = []
                earnedPass = false; earnedMastery = false; earnedMemory = false
            }
            practiceMode = settings.practiceMode
            runPadCount = midi.activeProfile.padCount
            starStreak = !unscored && practiceMode == .learning
                ? progress.learningCredit(lessonId: lesson.id, padCount: midi.activeProfile.padCount) : StarStreak()
            if !isMix || startingFreshMix {
                earnedBadgesInRun = []
            }
            pendingScore = nil; pendingBpm = 0; pendingCredit = false
            tempo.reset()
            barVerdicts = [:]
            mixBarVerdicts = [:]
            judgmentsByPass = [:]
            playedHits = []
            timingHistory = TimingHistory()
            completedMatches = 0
            completedExpected = 0
            completedExtras = 0
            judgmentVersion += 1
            completedPasses = 0
            memoryWarmUp = LearningRules.MemoryWarmUp()
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
            if !listen && !afterMe && !unscored {
                var record = progress.progress(for: lesson.id) ?? LessonProgress()
                record.hasPlayed = true
                record.currentBpm = bpm
                progress.setProgress(record, for: lesson.id)
                settings.lastLessonID = lesson.id
            }
            midi.resetControlPickup()
            runID = id
            running = true
            countdown = 4
            task = Task { [weak self] in
                while !Task.isCancelled {
                    guard let self, self.running else { return }
                    await self.tick()?.value
                    try? await Task.sleep(for: .milliseconds(10))
                }
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func stop() { stop(restarting: false) }

    private func stop(restarting: Bool, audioSessionChanged: Bool = false) {
        guard running else { return }
        // Credit complete passes only; stopping halfway cannot earn a star.
        // An automatic star or review stop already credited the winning pass. Discard everything
        // queued after it, even if the app was delayed long enough to finish it.
        if !stopAfterPass, !audioSessionChanged { finishCompleted(at: now) }
        let accuracy = currentRunAccuracy
        flushPendingProgress()
        stopAfterPass = false
        mixNeedsAdvance = false
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
        stopAudio()
        if afterMe {
            summary = RunSummary(score: lastResult?.score ?? 0, bpm: bpm, passes: completedPasses,
                                 passed: false, mastery: false, memory: false, runs: runResults)
        } else if isMix {
            summary = makeMixSummary()
        } else if let result = lastResult, !listen {
            summary = RunSummary(score: result.score, bpm: result.bpm, passes: completedPasses,
                                 passed: earnedPass, mastery: earnedMastery, memory: earnedMemory,
                                 finishedByStar: finishedByStar, runs: runResults,
                                 firstStar2: earnedFirstMasteryInRun)
        } else if !listen, !unscored, let accuracy {
            summary = RunSummary(score: accuracy, bpm: bpm, passes: 0,
                                 passed: false, mastery: false, memory: false,
                                 runs: runResults)
        }
        if !afterMe && !unscored {
            if audioSessionChanged {
                if !listen, !isMix, let savedBpm = progress.progress(for: lesson.id)?.currentBpm {
                    bpm = savedBpm
                }
            } else {
                saveTempo()
            }
        }
        if !unscored && (audioSessionChanged || reviewFeedback != nil) {
            try? progress.save()
        }
        if !afterMe && !unscored { evaluateBadges() }
        if active, !suspended {
            if restarting {
                loadKit(resolveKit(for: mixLessons.first ?? lesson)) { $0.beginRun() }
            } else {
                resume()
            }
        }
    }

    private func makeMixSummary() -> RunSummary {
        let mixPassed = isMixFullyMet
        let mixScores = mixResults.compactMap(\.score)
        let mixScore = mixScores.isEmpty ? (lastResult?.score ?? 0) : (mixScores.reduce(0.0, +) / Double(mixScores.count))
        return RunSummary(score: mixScore, bpm: bpm,
                          passes: runResults.count, passed: mixPassed, mastery: earnedMastery,
                          memory: fromMemory && currentMixRoundMemory, runs: runResults)
    }

    func restart() {
        if running { stop(restarting: true) }
        else { start() }
    }

    /// One store write per run instead of one per pass.
    private func flushPendingProgress() {
        if !unscored {
            if pendingCredit, practiceMode == .learning {
                progress.setLearningCredit(starStreak, lessonId: lesson.id, padCount: runPadCount, autoSave: false)
            }
            if let score = pendingScore {
                progress.recordResult(lessonId: lesson.id, passed: false, mastery: false,
                                      bpm: pendingBpm, score: score, autoSave: false, today: currentDay())
            }
        }
        pendingScore = nil
        pendingBpm = 0
        pendingCredit = false
    }

    func dismissSummary() { summary = nil }

    func suspend() {
        guard active else { return }
        suspended = true
        midi.resetControlPickup()
        if running { stop() }
        else { stopAudio() }
    }

    private func stopAudio() {
        kitTask?.cancel()
        kitTask = nil
        setReady(false)
        if audioStarted {
            audio.stop()
            audioStarted = false
        }
    }

    func resume() {
        guard active else { return }
        suspended = false
        guard prepared, !running, kitTask == nil else { return }
        loadKit(resolvedKitId) { try $0.startAudio() }
    }

    func close() {
        guard active else { return }
        suspend()
        active = false
        Self.audioOwner = nil
        if selectedKitRequest != nil { audio.selectKit(nil) }
        selectedKitRequest = nil
        prepared = false
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

    /// Pause cleanly before the next lesson in this round without auto-starting it.
    private func pauseMixForNextLesson() -> Task<Void, Never>? {
        mixNeedsAdvance = false
        guard mixIndex + 1 < mixLessons.count else { return nil }
        return advanceToPausedMixLesson(index: mixIndex + 1)
    }

    /// Skip the current stopped mix lesson without recording a result, or finish if on the last lesson.
    @discardableResult
    func skipMixLesson() -> Task<Void, Never>? {
        guard isMix, !running, summary == nil, mixIndex < mixLessons.count else { return nil }
        if mixResults.isEmpty {
            mixResults = makeInitialMixResults()
        }
        if mixIndex + 1 < mixLessons.count {
            return advanceToPausedMixLesson(index: mixIndex + 1)
        }
        mixNeedsAdvance = false
        summary = makeMixSummary()
        if !unscored {
            try? progress.save()
            evaluateBadges()
        }
        return nil
    }

    private func advanceToPausedMixLesson(index nextIndex: Int) -> Task<Void, Never>? {
        guard isMix, mixLessons.indices.contains(nextIndex) else { return nil }
        running = false
        BluetoothTimingDiagnostics.shared.stopRun()
        stopAudio()
        mixIndex = nextIndex
        let nextLesson = mixLessons[nextIndex]
        lesson = nextLesson
        bpm = PracticeTempo.clamp(nextLesson.targetBpm)
        loopStartBar = 0
        loopEndBar = nextLesson.bars - 1
        midi.setLesson(nextLesson)
        midi.resetControlPickup()
        starStreak = !unscored && practiceMode == .learning
            ? progress.learningCredit(lessonId: nextLesson.id, padCount: runPadCount) : StarStreak()
        memoryWarmUp = LearningRules.MemoryWarmUp()
        passNumber = 1
        currentRepetition = 1
        lastResult = nil
        lastVerdict = nil
        summary = nil
        reviewFeedback = unscored ? nil : reviewWindows[nextLesson.id].flatMap {
            $0.day == currentDay() ? $0.outcome?.feedback : nil
        }
        finishedByStar = nil
        tempoUpEvent = nil
        stopAfterPass = false
        tempo.reset()
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
        passes = []
        countInEvents = []
        countdown = nil
        return loadKit(resolvedKitId) { try $0.startAudio() }
    }

    private var now: Double { clock() }

    private func makePass(number: Int, start: Double, bpm: Int) -> Pass {
        Pass(number: number, start: start, bpm: bpm, lesson: scoredLesson, padCount: runPadCount,
             listen: listen, lessonSound: afterMe ? false : lessonSound,
             metronome: afterMe || metronome, bpmStep: settings.bpmStepEnum,
             callLesson: afterMe ? practiceLesson : nil)
    }

    /// Internal so session tests can advance a supplied host clock without waiting.
    @discardableResult
    func tick() -> Task<Void, Never>? {
        guard running else { return nil }
        if let kitTask { return kitTask }
        let time = now
        if stopAfterSinglePass, listen, let first = passes.first, time >= first.finalTime {
            let callback = onSinglePassEnded
            stop()
            callback?()
            return nil
        }
        finishCompleted(at: time)
        if stopAfterPass {
            stop()
            return nil
        }
        if isMix, mixNeedsAdvance {
            return pauseMixForNextLesson()
        }
        let horizon = time + 0.5
        // Decide the next BPM from the run's result as known so far. Notes whose
        // matching window has closed count as usual; notes still inside their window
        // are left out of that decision.
        if !isMix, !stopAfterSinglePass, let last = passes.last, last.start + last.duration <= horizon {
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
                if !listen, !afterMe, let event = tempo.tempoUpEvent(newBpm: current.bpm, goalBpm: lesson.targetBpm) {
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
        var sounds: [AudioEngine.ScheduledSound] = []
        while let click = countInEvents.first, click <= horizon {
            sounds.append(.init(audibleHostTime: AVAudioTime.hostTime(forSeconds: click), padIndex: nil))
            countInEvents.removeFirst()
        }
        for pass in passes {
            while let sound = pass.sounds.first, sound.time <= horizon {
                sounds.append(.init(audibleHostTime: AVAudioTime.hostTime(forSeconds: sound.time),
                                    padIndex: sound.pad, velocity: sound.velocity, passStart: pass.start))
                pass.sounds.removeFirst()
            }
        }
        if !sounds.isEmpty {
            let id = runID
            audio.schedule(sounds) { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self, self.running, self.runID == id else { return }
                    self.errorMessage = error.localizedDescription
                    self.stop()
                }
            }
        }
        passes.removeAll { $0.finalTime < time && $0.scorer == nil && $0.number < passNumber }
        return nil
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
                if !unscored {
                    progress.recordAfterMeResponse(lessonId: lesson.id, score: result.score, today: currentDay(), autoSave: true)
                    evaluateBadges(onlyGroup: .training)
                }
                continue
            }
            let runPassed: Bool
            var award: StarAward?
            let lessonReviewDue = !unscored && progress.progress(for: lesson.id)?.reviewSchedule.isDueReview(on: currentDay()) == true
            let memoryNotesHidden = memoryWarmUp.areNotesHidden(fadeNotes: settings.fadeMemoryNotes)
            let isHiddenPass = !fromMemory || memoryNotesHidden
            if !isSectionLoop && !unscored {
                let saved = progress.progress(for: lesson.id)

                let today = currentDay()
                if let currentProgress = saved,
                   currentProgress.reviewSchedule.isDueReview(on: today) {
                    let passResult = ReviewScheduler.evaluate(
                        schedule: currentProgress.reviewSchedule,
                        today: today,
                        isFullRun: !isSectionLoop,
                        fromMemory: fromMemory,
                        bpm: result.bpm,
                        targetBpm: lesson.targetBpm,
                        score: Float(result.score),
                        notesHidden: memoryNotesHidden
                    )
                    var window = reviewWindows[lesson.id].flatMap { $0.day == today ? $0 : nil }
                        ?? DailyReviewWindow(day: today)
                    let decision = ReviewScheduler.advanceWindow(window.state, with: passResult)
                    window.state = decision.window
                    window.outcome = decision.outcome
                    reviewWindows[lesson.id] = window
                    reviewPendingReason = fromMemory && !memoryNotesHidden
                        ? .notesVisible : .unfinishedReview
                    if let outcome = decision.outcome, let feedback = outcome.feedback {
                        reviewFeedback = feedback
                        progress.updateReviewSchedule(outcome.newSchedule, for: lesson.id, autoSave: false)
                        switch feedback {
                        case .passed, .settled:
                            progress.recordReviewRun(lessonId: lesson.id, passed: true, today: today, autoSave: false)
                            if !isMix {
                                stopAfterPass = true
                                finishedByReview = true
                            }
                            if ReviewScheduler.mayEarnStar3(outcome: outcome, progress: currentProgress) {
                                earnedMemory = true
                                finishedByStar = 3
                                let award = StarAward(previous: currentProgress,
                                                      passed: currentProgress.passed,
                                                      mastery: currentProgress.mastery,
                                                      memory: true)
                                progress.recordResult(lessonId: lesson.id,
                                                      passed: currentProgress.passed,
                                                      mastery: currentProgress.mastery,
                                                      bpm: result.bpm,
                                                      score: Float(result.score),
                                                      memory: true,
                                                      autoSave: false,
                                                      today: today)
                                starEvent = StarEvent(award: award)
                            }
                        case .failed:
                            progress.recordReviewRun(lessonId: lesson.id, passed: false, today: today, autoSave: false)
                        case .doesNotCount:
                            break
                        }
                        // A decided review survives app closure even while practice continues.
                        try? progress.save()
                        evaluateBadges()
                    } else {
                        reviewFeedback = passResult.feedback.flatMap {
                            if case .doesNotCount = $0 { return $0 }
                            return nil
                        }
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
                    notesHidden: memoryNotesHidden
                )
                let memoryRunPassed = fromMemory && result.bpm >= lesson.targetBpm && result.score >= Scoring.passMark && isHiddenPass
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
                award = StarAward(previous: progress.progress(for: lesson.id),
                                  passed: stars.passed, mastery: stars.mastery, memory: stars.memory)
                let currentAward = award!
                pendingScore = max(pendingScore ?? 0, Float(result.score))
                pendingBpm = max(pendingBpm, result.bpm)
                if currentAward.fresh[1] {
                    earnedFirstMasteryInRun = true
                }
                if currentAward.fresh.contains(true) {
                    // A new star is rare and must be visible at once (library, next-star text).
                    progress.recordResult(lessonId: lesson.id, passed: stars.passed, mastery: stars.mastery,
                                          bpm: result.bpm, score: Float(result.score), memory: stars.memory,
                                          autoSave: false, today: currentDay())
                    if practiceMode == .learning {
                        progress.setLearningCredit(starStreak, lessonId: lesson.id, padCount: pass.padCount, autoSave: false)
                        pendingCredit = false
                    }
                    starEvent = StarEvent(award: currentAward)
                    evaluateBadges()
                }
                stopAfterPass = stopAfterPass || (!isMix && currentAward.shouldStop)
                if currentAward.shouldStop { finishedByStar = currentAward.fresh[2] ? 3 : 2 }
            } else {
                runPassed = result.passed
                lastVerdict = RunVerdict(passed: result.passed, brokenStreak: false)
            }
            runResults.append(PracticeRunResult(runNumber: runResults.count + 1,
                                                score: result.score,
                                                bpm: result.bpm,
                                                passed: runPassed))
            if isMix {
                let currentAward = award ?? StarAward(previous: progress.progress(for: lesson.id),
                                                      passed: false, mastery: false, memory: false)
                flushPendingProgress()
                let runMemoryPass = fromMemory && isHiddenPass && result.score >= Scoring.passMark
                if !runMemoryPass {
                    currentMixRoundMemory = false
                }

                let lessonMet: Bool = {
                    if lessonReviewDue {
                        switch reviewFeedback {
                        case .passed, .settled: return true
                        case .failed, .doesNotCount, nil: return false
                        }
                    }
                    if fromMemory { return runMemoryPass }
                    return runPassed
                }()

                let lessonCounted: Bool = {
                    if lessonReviewDue {
                        return fromMemory && isHiddenPass && result.bpm >= lesson.targetBpm
                    }
                    return !fromMemory || isHiddenPass
                }()

                let lessonStarEvent = currentAward.fresh.contains(true) ? StarEvent(award: currentAward) : nil
                mixEarnedStars = zip(mixEarnedStars, currentAward.earned).map { $0 || $1 }
                mixFreshStars = zip(mixFreshStars, currentAward.fresh).map { $0 || $1 }
                if mixFreshStars.contains(true) {
                    starEvent = StarEvent(award: StarAward(earned: mixEarnedStars, fresh: mixFreshStars))
                }

                if let index = mixResults.firstIndex(where: { $0.id == lesson.id }) {
                    mixResults[index].score = result.score
                    mixResults[index].barCounts = Dictionary(grouping: mixBarVerdicts.values, by: \.rawValue).mapValues(\.count)
                    mixResults[index].unmeasuredBars = max(0, scoredLesson.bars - mixBarVerdicts.count)
                    mixResults[index].met = lessonMet
                    mixResults[index].counted = lessonCounted
                    mixResults[index].earnedStars = currentAward.earned
                    mixResults[index].starEvent = lessonStarEvent
                    mixResults[index].reviewFeedback = reviewFeedback
                }

                if mixIndex == mixLessons.count - 1 {
                    if !unscored && mixResults.allSatisfy({ $0.score != nil }) {
                        progress.recordFinishedMixRound(isMemoryRound: currentMixRoundMemory, today: currentDay(), autoSave: false)
                    }
                    stopAfterPass = true
                } else {
                    mixNeedsAdvance = true
                }
                if !unscored {
                    try? progress.save()
                    evaluateBadges()
                }
            }
            // The tempo preference is saved once at STOP, not at every pass.
            if let error = progress.lastSaveError { errorMessage = error.localizedDescription }
            if fromMemory && !isSectionLoop {
                memoryWarmUp.recordPass(score: result.score, fadeNotes: settings.fadeMemoryNotes)
            }
            if stopAfterPass { return }
        }
    }

    private func receive(_ event: PadInputEvent) {
        guard event.isNoteOn, ready, kitTask == nil else { return }
        guard running else {
            padFlashes[event.padIndex] = PadFlash(mark: nil, date: Date())
            return
        }
        let sourceTime = AVAudioTime.seconds(forHostTime: event.timestamp)
        let offset = settings.calibrationOffset(for: event.deviceID, outputRoute: runOutputRoute)
        let adjusted = max(0, sourceTime - offset / 1_000)
        guard !listen else {
            padFlashes[event.padIndex] = PadFlash(mark: nil, date: Date())
            recordPlayedHit(padIndex: event.padIndex, at: adjusted, mark: nil)
            return
        }
        // Boundary ownership follows the calibrated input timestamp, never the
        // display tick. Call hits cannot match even an early response note.
        if afterMe, !passes.contains(where: { $0.acceptsInput(at: adjusted) }) {
            padFlashes[event.padIndex] = PadFlash(mark: nil, date: Date())
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
            // Check duplicates before choosing between overlapping pass windows.
            // An ignored input must also preserve the previous pad colour.
            guard feedback.judgment != .ignored else { return }
            if let error = feedback.timingErrorMilliseconds,
               best == nil || abs(error) < best!.2 {
                best = (pass, scorer, abs(error), feedback)
            }
        }
        if let best {
            best.0.scorer = best.1
            if let error = best.3.calibratedTimingErrorMilliseconds {
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
                guard feedback.judgment != .ignored else { return }
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
        if matchedFeedback == nil {
            padFlashes[event.padIndex] = PadFlash(mark: nil, date: Date())
        }
        recordPlayedHit(padIndex: event.padIndex, at: adjusted, mark: mark)

        BluetoothTimingDiagnostics.shared.logNoteOn(
            deviceID: event.deviceID,
            rawTimestamp: event.rawTimestamp,
            receiptTimestamp: event.receiptTimestamp,
            resolvedTimestamp: event.timestamp,
            usedReceiptTime: event.usedReceiptTime,
            expectedStep: matchedFeedback?.expectedStep,
            timingErrorMs: matchedFeedback?.calibratedTimingErrorMilliseconds,
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
    private func record(_ feedback: HitFeedback, pass: Int, padIndex: Int) -> HitMark? {
        let mark: HitMark
        switch feedback.judgment {
        case .perfect, .good: mark = .correct
        case .off: mark = .off
        case .wrongPad: mark = .wrong
        case .ignored: return nil
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
        guard !unscored, !isMix else { return }
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
        return EndOfRunCardModel.badgeSummaryText(count: earnedBadgesInRun.count, language: settings.languagePreference)
    }
}
