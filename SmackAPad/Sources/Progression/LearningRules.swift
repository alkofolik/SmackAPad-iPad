/// Numeric learning policy shared by scoring, practice, progression and saved progress.
public enum LearningRules {
    /// Minimum score for an ordinary passing run or a successful review.
    public static let passMark: Double = 0.8
    /// Minimum score for the alternative Learning-mode qualification.
    public static let learningMinimumScore: Double = 0.6
    /// Minimum fraction of expected hits judged perfect or good for Learning credit.
    public static let learningMinimumGoodHitRatio: Double = 0.85
    /// Minimum error allowance for the alternative Learning qualification.
    public static let learningMinimumErrorAllowance = 1
    /// Expected hits per allowed error for the alternative Learning qualification.
    public static let learningHitsPerAllowedError = 10

    /// Minimum accumulated expected hits used to calculate a star's run requirement.
    public static let minimumHitsPerStar = 16
    /// Maximum qualifying runs required for a star, even for sparse patterns.
    public static let maximumRunsPerStar = 4
    /// Minimum qualifying Intro runs for goal-tempo and memory counters.
    public static let minimumIntroRunsPerStar = 3
    /// Target bar count used when repeating a short pattern into a scored run.
    public static let practiceRunBars: Double = 4.0

    /// Passed lessons needed by the retained category-unlock API and migrations.
    public static let categoryLessonsToUnlock = 5
    /// Divisor for the preceding stage's required completed lessons, rounded up.
    public static let stageCompletionDivisor = 2
    /// Maximum completed lessons required to unlock the next stage.
    public static let maximumStageCompletions = 10

    /// Successful or failed eligible passes needed to decide one review window.
    public static let reviewDecisionPasses = 2
    /// Passed spaced reviews required to award or migrate the memory star.
    public static let reviewsForMemoryStar = 2
    /// Consecutive successful warm-up passes required before From-memory notes hide.
    public static let warmUpPassesNeeded = 2

    /// Tracks consecutive successful From-memory warm-up passes for one lesson run.
    public struct MemoryWarmUp: Equatable, Sendable {
        /// Consecutive warm-up passes completed at `passMark` or better (0...warmUpPassesNeeded).
        public private(set) var consecutivePasses = 0

        public init(consecutivePasses: Int = 0) {
            self.consecutivePasses = max(0, min(LearningRules.warmUpPassesNeeded, consecutivePasses))
        }

        /// True once enough consecutive warm-ups have succeeded; notes stay hidden afterward.
        public var notesHidden: Bool {
            consecutivePasses >= LearningRules.warmUpPassesNeeded
        }

        /// Whether From-memory notes are hidden for the current pass under the fade setting.
        public func areNotesHidden(fadeNotes: Bool) -> Bool {
            !fadeNotes || notesHidden
        }

        /// Advances warm-up progress after a finished pass.
        /// Tempo does not matter for warm-ups, and once notes hide they stay hidden.
        public mutating func recordPass(score: Double, fadeNotes: Bool = true) {
            guard fadeNotes else {
                consecutivePasses = LearningRules.warmUpPassesNeeded
                return
            }
            guard !notesHidden else { return }
            if score >= LearningRules.passMark {
                consecutivePasses += 1
            } else {
                consecutivePasses = 0
            }
        }
    }
    /// Last review step, whose successful review settles the lesson.
    public static let lastReviewStep = 3
    /// Next-day delay for initial, migrated, failed and postponed reviews.
    public static let nextDayReviewDelay = 1
    /// Days between successive review steps, starting after mastery.
    public static let reviewGapsDays = [nextDayReviewDelay, 3, 7, 21]
    /// Reviews implied by a settled legacy record when restoring training totals.
    public static let settledReviewPasses = 4
    /// Maximum due lessons selected for today's review plan.
    public static let dailyReviewLimit = 2
    /// Minimum eligible lessons needed to offer and run a training mix.
    public static let minimumMixLessons = 2

    /// Maximum expected hits in a short non-Intro run with no clean-run errors.
    public static let shortCleanRunMaximumHits = 15
    /// Maximum expected hits in a medium run with the smaller error allowance.
    public static let mediumCleanRunMaximumHits = 32
    /// Errors allowed in Intro and short clean runs.
    public static let shortCleanRunAllowedErrors = 0
    /// Errors allowed in medium non-Intro clean runs.
    public static let mediumCleanRunAllowedErrors = 1
    /// Errors allowed in longer non-Intro clean runs.
    public static let longCleanRunAllowedErrors = 2

    /// Highest lesson level using the beginner timing windows.
    public static let beginnerTimingMaximumLevel = 2
    /// Highest lesson level using the intermediate timing windows.
    public static let intermediateTimingMaximumLevel = 4
    /// Perfect, good and matching windows in milliseconds for beginner lessons.
    public static let beginnerTimingMilliseconds = (perfect: 45.0, good: 100.0, maximum: 200.0)
    /// Perfect, good and matching windows in milliseconds for intermediate lessons.
    public static let intermediateTimingMilliseconds = (perfect: 38.0, good: 85.0, maximum: 175.0)
    /// Perfect, good and matching windows in milliseconds for advanced lessons.
    public static let advancedTimingMilliseconds = (perfect: 30.0, good: 70.0, maximum: 150.0)
    /// Same-pad input spacing suppressed as bounce or a resend, in nanoseconds.
    public static let duplicateHitWindowNanoseconds: Double = 25_000_000
    /// Consecutive unmatched hits that reset the adaptive timing center.
    public static let extraHitsToResetTimingCenter = 2
    /// Largest calibrated error accepted into timing-center learning, in nanoseconds.
    public static let timingCenterSampleLimitNanoseconds: Double = 110_000_000
    /// Maximum matched-hit samples retained for the adaptive timing center.
    public static let timingCenterSampleCount = 8
    /// Response-boundary tolerance for After me input, in seconds.
    public static let afterMeResponseToleranceSeconds: Double = 0.0001
}
