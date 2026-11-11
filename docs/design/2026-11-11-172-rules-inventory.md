# Learning rules inventory — ticket 172

Original locations refer to the source before this refactor (the ticket's implementation parent commit). All values and decision branches are preserved. `UI/StarStreak.swift` is now `Progression/StarStreak.swift`.

## Moved thresholds and counts

All source paths below are relative to the repository root. Named values live in `SmackAPad/Sources/Progression/LearningRules.swift`; existing public constants remain forwarding aliases for compatibility.

| Original file | Original line | Value | Purpose |
| --- | ---: | --- | --- |
| `SmackAPad/Sources/Persistence/Persistence.swift` | 1241 | 4 | Passed reviews implied by a settled record during old-progress decoding. |
| `SmackAPad/Sources/Persistence/Persistence.swift` | 1494 | 2 | Silent migration awarding Star 3 after two reviews. |
| `SmackAPad/Sources/Persistence/Persistence.swift` | 1976 | 1 day | A next-day successful review counts as a bounce-back. |
| `SmackAPad/Sources/Progression/Progression.swift` | 16 | 5 | Passed lessons needed for category access. |
| `SmackAPad/Sources/Progression/Progression.swift` | 19 | 10 | Stage-unlock completion cap. |
| `SmackAPad/Sources/Progression/Progression.swift` | 22 | 2 | Half the preceding stage, rounded up; +1 is ceiling arithmetic. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 18 | 1, 3, 7, 21 days | Review interval sequence; public scheduler API retained. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 112 | 2 successes or 2 failures | Decision threshold for one review window. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 145 | 2 | Passed spaced reviews required for Star 3. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 165 | 3 | Default hidden review pass. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 177 | 3 | First hidden pass eligible for review with fading notes. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 190 | 3 | Successful final step settles the lesson. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 191 | 3 | Persisted settled review step. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 202 | 1 day | Next-day failed, postponed, initial and migration review dates. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 212 | 1 day | Next-day failed, postponed, initial and migration review dates. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 218 | 1 day | Next-day failed, postponed, initial and migration review dates. |
| `SmackAPad/Sources/Progression/ReviewScheduler.swift` | 224 | 1 day | Next-day failed, postponed, initial and migration review dates. |
| `SmackAPad/Sources/Progression/TodayPlan.swift` | 91 | 2 | Daily due-review selection and fallback load. |
| `SmackAPad/Sources/Progression/TodayPlan.swift` | 100 | 2 | Daily due-review selection and fallback load. |
| `SmackAPad/Sources/Progression/TodayPlan.swift` | 102 | 2 | Minimum lessons needed to include a mix in the daily plan. |
| `SmackAPad/Sources/Progression/TrainingMix.swift` | 11 | 2 | Minimum eligible lesson count in a saved daily mix. |
| `SmackAPad/Sources/Progression/TrainingMix.swift` | 44 | 2 | Minimum selected lesson count needed to offer a mix. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 5 | 0.8 | Ordinary pass and review score threshold; public Scoring API retained. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 54 | 25_000_000 ns | Same-pad duplicate suppression window; definition moved to LearningRules. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 111 | level <= 2; 45/100/200 ms | Beginner perfect/good/matching timing windows. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 112 | levels 3...4; 38/85/175 ms | Intermediate perfect/good/matching timing windows. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 113 | 30/70/150 ms | Advanced perfect/good/matching timing windows. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 124 | 25_000_000 ns | Duplicate-hit window consumer. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 147 | 2 | Consecutive extra hits resetting timing-center learning. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 164 | 110_000_000 ns | Maximum calibrated error admitted to timing-center learning. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 166 | 8 | Maximum timing-center sample count. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 185 | 15; 32; 0/1/2 errors | Completed-run clean/mastery error tiers. |
| `SmackAPad/Sources/Scoring/ScoringEngine.swift` | 212 | 15; 32; 0/1/2 errors | Early-result clean/mastery error tiers (same thresholds). |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 87 | 2 | Minimum lessons enabling a training mix. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 235 | level <= 2: 0.2 s; <= 4: 0.175 s; otherwise 0.15 s | Last-hit matching grace before a run is finalized; identical to scoring windows. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 257 | 0.0001 s | After me input boundary tolerance. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 275 | 2 | Minimum lessons enabling a training mix. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 278 | 2 | After me entry is allowed only outside a mix. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 290 | 2 | Minimum lessons enabling a training mix. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 329 | 3 | Memory warm-up eligibility before hidden passes. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 399 | 4.0 bars | Scored run length for repeating short patterns. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 691 | 4.0 bars | Matching initial unmeasured-bar count for a mix round. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 1099 | 3 | Hidden-pass eligibility for stars, review-related practice and mix rounds. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 1121 | 3 | Review pending reason while notes remain visible. |
| `SmackAPad/Sources/UI/PracticeSession.swift` | 1241 | 3 | Hidden-pass eligibility for stars, review-related practice and mix rounds. |
| `SmackAPad/Sources/UI/StarStreak.swift` | 17 | 0.6 | Alternative Learning qualification score floor. |
| `SmackAPad/Sources/UI/StarStreak.swift` | 18 | 0.85 | Alternative Learning perfect/good hit ratio. |
| `SmackAPad/Sources/UI/StarStreak.swift` | 19 | 1; 10 | Minimum allowed error and expected hits per allowed error for Learning. |
| `SmackAPad/Sources/UI/StarStreak.swift` | 34 | 3 | Default hidden pass in retained memory-credit overloads (currently always false). |
| `SmackAPad/Sources/UI/StarStreak.swift` | 49 | 3 | Default hidden pass in retained memory-credit overloads (currently always false). |
| `SmackAPad/Sources/UI/StarStreak.swift` | 66 | 16 | Expected-hit budget for calculating runs per star; API alias retained. |
| `SmackAPad/Sources/UI/StarStreak.swift` | 79 | 4 | Maximum qualifying runs required per star. |
| `SmackAPad/Sources/UI/StarStreak.swift` | 80 | 3 | Intro minimum qualifying runs for goal-tempo and memory counters. |

## Differences and inconsistencies preserved

- Ordinary runs and reviews pass at 80%. Learning also accepts a score of at least 60% when at least 85% of expected hits are perfect/good and errors are at most `max(1, expectedHits / 10)`. These are separate qualifications, not interchangeable thresholds. No active 70% pass rule was found in the inspected files; `Persistence.swift:235` is a 70% pattern-volume default, not a learning rule.
- Clean runs use zero errors for Intro or up to 15 expected hits, one error through 32 hits, and two errors for longer patterns. Mastery uses this clean-run rule at goal tempo, rather than the 80% pass rule.
- The 16-hit star requirement is capped at four runs, so sufficiently sparse patterns can earn a star with fewer than 16 total expected hits. Intro's three-run minimum applies to goal-tempo/memory counters, while the first star uses the shorter ordinary requirement.
- Practice memory credit remains disabled: both `mayEarnMemoryCredit` overloads return/delegate to `false`. Star 3 instead requires two successful spaced reviews. Each review decision itself requires two successful eligible passes (or two failures to fail). These independent counts both happen to be two.
- Settling happens after passing review step 3 (four successful reviews from step 0). Legacy training totals therefore infer four reviews for a settled record, while Star 3 is already awarded at step 2.
- The retained category API unlocks after five passed lessons. Stage access instead needs half the preceding stage's completed lessons (both passed and mastered), rounded up and capped at ten. Migration intentionally preserves older one-star stage access, including lessons lacking an eight-pad layout.
- `recordPass` in `Persistence.swift:1868–1877` supplies a default score of 0.85 and BPM 100 but records the supplied pass directly; these are convenience defaults, not qualification thresholds. Debug scenarios likewise supply sample scores/counts rather than defining learning rules.
- `PracticeSession.swift:325` and existing explanatory strings in `TodayPlan.swift`/`ReviewScheduler.swift` still spell out two passes, 80%, or next-day wording. Display copy is unchanged, as requested; it is not a numeric decision point.

## Inspection boundaries

Inspected all files in `Progression/`, `Scoring/` and `Persistence/`, plus `UI/StarStreak.swift` and `UI/PracticeSession.swift`. Review forecasting and ordering consume schedule state without additional qualification thresholds. Badge goals are supplied by definitions; badge counts do not award lesson stars or unlock stages. Backup retention, serialization versions, dates, volume/calibration limits, tempo input limits, catalogue IDs/levels, mix selection size/level distribution, notification horizons, count-in beats, playback scheduling and presentation constants are not qualification rules and remain in their owning files. Zero-valued empty-state guards, counter initialization, index increments, mathematical divisors/conversions and star array indices also remain local.

## Manual code comparison

The five requested areas were compared directly against their original code:

1. `Progression/`: category/stage requirements, review windows/intervals, Star 3 and daily review/mix eligibility preserve their values and conditions.
2. `Scoring/`: full and early scoring use identical clean-run tiers, pass mark, hit windows and timing-center limits.
3. `StarStreak`: Learning qualification, 16-hit calculation, four-run cap and Intro minimum preserve their formulas; moving the file changes no saved fields.
4. `PracticeSession`: four-bar repetition, hidden-pass eligibility, mix eligibility and final-hit/response tolerances preserve their calculations.
5. `Persistence/`: Star 3 migration, inferred settled review totals and next-day bounce-back detection preserve their values.

## Manual iPad checks for Jakub

- Compare Learning and Challenge on the same pattern: ordinary 80% passes, alternative Learning credit and retained/reset run counts behave as before.
- Try a sparse pattern and Intro: the 16-hit requirement, four-run cap and Intro minimum behave as before.
- Earn goal tempo and complete two spaced reviews: hidden passes begin at pass 3, each review needs two successful passes, and Star 3 arrives after the second successful review.
- Check the next stage's required completion count and previously open stages; both match the prior version.
- Resume saved progress and today's plan, then try a mix and After me; review dates, stars and run lengths match the prior version.

These device checks remain for Jakub; the code comparison is not a claim of hands-on iPad verification.
