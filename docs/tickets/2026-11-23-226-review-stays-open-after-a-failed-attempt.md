# 226 — Review: a failed attempt keeps the review open for the rest of the day (rules)

Status: ready-for-agent. Rule chosen by Jakub on 2026-11-23 (variant B). UI part is ticket 227 (do 226 first).

## Goal

A due review that fails today is not closed. The run keeps going, the lesson stays due today, and Jakub can still pass it the same day. Nothing is postponed while the day is open. Only if the day ends without a pass does the failure take effect, exactly as the old rule did.

## What Jakub saw (2026-11-23)

Lesson opened as a review after several days. The run ended and said the requirements were not met. He started again: no sign of what was met, the run never stopped, and the result card showed that everything had been met long ago.

## Cause (code reading)

`PracticeSession.swift` ~line 1275–1335 and `ReviewScheduler.evaluate`: any decision (also `.failed`) writes a new schedule with `lastReviewedDay = today` and due tomorrow. That makes `isDueReview` false for the rest of the day, so the review branch is skipped and later passes can neither fail nor pass the review. The window that holds the decided outcome is also kept across restarts, so it stays locked.

## New rule

1. A review is decided by 2 qualifying hidden passes, as today. Two good passes: passed (unchanged: step +1, next gap, run stops). Two bad passes: **failed so far**.
2. **Failed so far** does not touch the schedule: no step-down, no new due day, `lastReviewedDay` stays as it was. It only sets `lastReviewFailDay = today`. The run does **not** stop. The review window starts empty again (0 of 2), so the next 2 qualifying passes decide again. This can repeat any number of times that day.
3. A pass decision later the same day is a normal pass from the original step (step +1, normal gap). `lastReviewFailDay` is cleared. It is not a "bounce back" (that counter stays only for pass on the day after a failure).
4. **Day rollover settles open failures.** At the first load on a later day (and wherever the due list or Today plan is built), any lesson with `lastReviewFailDay < today` whose schedule was not changed after that day gets the old failure result: step -1 (minimum 0), `reviewDueDay = lastReviewFailDay + 1 day`, `lastReviewedDay = lastReviewFailDay`. The result is identical to the old rule when Jakub does not retry. One function, covered by tests; no second place that applies a failure.
5. A lesson with an open failure counts as due today everywhere (`isDueReview`, due queue, Today plan), until it is passed or the day ends. Playing a due review never needs a "reset"; the old "STOP abandons undecided windows" rule stays.
6. Mix and Today steps use the same rules. A mix cannot decide a review alone (one pass per lesson per round), so it must never record a failure by itself.
7. Do not change scoring, the 80 % pass mark, the review gaps or the 2-pass decision count.
8. Delete the code and tests that enforce the old rule "a decided failure locks the day" (decided window kept after `.failed`, `lastReviewedDay = today` on failure).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeSession.swift` (search: `reviewWindows`, `advanceWindow`, `recordReviewRun`, `isDueReview`), `SmackAPad/Sources/Progression/ReviewScheduler.swift`, `SmackAPad/Sources/Persistence/ProgressStore.swift` (`recordReviewRun`, load/migration), `ProgressMerge.swift` (`lastReviewFailDay`), `SmackAPad/Sources/Progression/TodayPlan.swift` (`reconcilingReviews`).

## Tests

Use the tdd skill (scoring/progression). Write: (a) fail then pass the same day gives step +1 and no step-down; (b) fail and nothing else, then next day: step -1 and due = failure day + 1, same as the old result; (c) a failed decision does not stop the run and the next 2 passes decide again; (d) open failure is due the same day; (e) device merge keeps an open failure. Run the full suite.

## Acceptance criteria

- [ ] Rules 1–6 implemented, old locking rule and its tests deleted.
- [ ] The run after a failed decision keeps going and can still pass the review that day.
- [ ] Nothing is postponed while the day is open; settled on the next day with the old result.
- [ ] Build and full tests pass.

### Manual iPad checks for Jakub

`reviewDueToday` scenario: fail the review (run keeps going), then pass it with the same lesson (run stops, review is passed). Second time: fail it and stop; the next day the lesson is due again one step lower.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run tests per `AGENTS.md`, commit, stop for Jakub's iPad check.
