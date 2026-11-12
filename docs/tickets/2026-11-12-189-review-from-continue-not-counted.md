# 189 — Bug: review opened from Continue does not stop and stays in the review queue

Status: ready-for-agent. Reported by Jakub on 2026-11-12 (3 screenshots, 14:38–14:40). Ticket 176 fixed the auto-stop from the Library; this is the same symptom on another path.

## What Jakub saw

- Opened the app → Training/Review queue → **Continue**; the first step was the review of "Kick and hat together" (1 bar, 80 BPM, two pads: Hi-hat + Kick, From memory, both "eye" buttons visible top right, accuracy 95 %).
- The run did **not** stop by itself when the lesson was passed. He played it at 100 % three or four times.
- After stopping once, he could not tell whether the review requirements were met.
- The **Review queue** still lists "Kick and hat together" as "STEP 2 OF 4 · Ready for review" although he passed it several times with 100 %. (One result card did say "Review passed · next in 3 days", so a pass was reported at least once.)

## Known facts from reading the code (not yet reproduced)

- Checked against `reviewDueToday` (booted iPad simulator + session/queue code inspection & unit tests) across all three launch paths:
  - **(a) Library (`LibraryScreen.open(_:)` / Home Pad 3 `CONTINUE`)**: Uses `LessonLaunch.library(lesson, progress:, today:)`, which sets `reviewTempo = lesson.targetBpm` and `fromMemory = true` when due. Full 2 warm-ups + 2 hidden passes DO decide `.passed`, set `stopAfterPass = true` / `finishedByReview = true`, update `reviewSchedule`, and remove the lesson from `dueLessonIds`. However, on an **early stop** before the 2 hidden passes complete (`reviewFeedback == nil`), `EndOfRunCardModel.build(...)` fell through to `"✓ Passed"` (`summary.score >= 0.8`) instead of reporting `"Not counted"` (`exclamationmark.circle`) with the pending reason.
  - **(b) Home pad → Training → review queue row (`TrainingScreen.dueLessonRow`)**: Launches `.review(lesson)` from inside `reviewQueueDestination`. Passing the review DOES auto-stop and update `ProgressStore` (e.g. step 1 → step 2, future `reviewDueDay`), **but** while `reviewQueueDestination` is pushed onto the `NavigationStack`, `TrainingScreen`'s root `GeometryReader` has `isVisible = false` (from `.onDisappear`), so `refreshTrainingData()` and `withObservationTracking` skip the update. Returning to the Review queue leaves the passed lesson in `"Ready for review"` showing the live `"STEP 2 OF 4"` alongside stale `"Ready for review"` text, and tapping that stale row again launches `.review(lesson)` when `isDueReview` is already `false` (`lastReviewedDay == today`), so subsequent runs never auto-stop. Fixed by tracking `isQueueVisible` (`isTrainingActive = isVisible || isQueueVisible`), refreshing synchronously in `reviewQueueDestination.onAppear` / `selectedLesson == nil` / `showingToday` dismiss, and skipping the 50 ms initial-open delay when `data != nil`.
  - **(c) Home pad → Training → Continue (Today steps) (`TodaySessionScreen` → `PracticeScreen`)**: Launches `.review(lesson)` with `isMix == false` and `onStepResult: { coordinator.record($0) }`. It auto-stops after 2 warm-up passes + 2 hidden passes (16 bars total for a 1-bar lesson when `fadeMemoryNotes == true`), updates `reviewSchedule`, and `reconcilingReviews` / `postpone` do not move a passed review back to today. When stopping early after 3–4 bars (1 pass or partial pass, `reviewFeedback == nil`), `EndOfRunCardModel.build(...)` previously reported `"✓ Passed"` whenever `summary.score >= 0.8` instead of `exclamationmark.circle` `"Not counted"` + pending reason chip (`notesVisible` / `unfinishedReview`). Fixed in `EndOfRunCardModel.build` and `PracticeScreen`.

## Rules

1. Reproduce first (simulator, `reviewDueToday`, lesson "Kick and hat together" or any 1-bar two-pad lesson due for review). Test all three launch paths separately: Library, Home pad → Training → review queue row, Home pad → Continue (Today steps). Write down in this ticket which paths fail and why.
2. Fix so that, from every launch path: the run stops by itself in the pass where the review is met; the lesson leaves the "ready for review" list right away and shows the new date (queue row and Waiting panel); the result card says clearly whether the review passed.
3. Tell the player, without new text, whether the review is still open when he stops early: reuse the existing exclamation icon from ticket 158 (played but not counted).
4. Do not change the review rules (80 % pass mark, two good hidden passes, goal tempo).

## Files to read

`AGENTS.md`, `PracticeSession.swift`, `ReviewScheduler.swift`, `LearningRules.swift`, `TodayPlan.swift` (`reconcilingReviews`), `TodaySessionScreen.swift`, `TrainingScreen.swift` (`makeTrainingData`, `refreshTrainingData`), `ProgressStore.swift` (`updateReviewSchedule`, `recordReviewRun`), tickets 158, 176, 177.

## Tests

Unit tests: (a) a due review played through Today-step launch ends with an updated schedule and `lessonStopsAfterPass`; (b) after the decision `dueLessonIds` no longer contains the lesson; (c) `reconcilingReviews`/`postpone` never moves a passed review back to today.

## Acceptance criteria

- [x] Cause written into the ticket notes, per launch path.
- [x] Review stops by itself from Library, queue row and Continue.
- [x] Passed review disappears from the queue immediately and appears under Waiting with the right day.
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

`reviewDueToday` scenario: Continue → pass the first review step → it stops, result says passed, open the Review queue: the lesson is gone from "Ready for review". Repeat from the Library and from a queue row.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (diagnosis across session, scheduler and Training). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
