# 201 — Bug: finished mix is still offered on Training

Status: resolved. Reported by Jakub on 2026-11-13 (iPad review, photo 8).

## Goal

Jakub finished today's mix. Back on Training the Mix tile still said "now" and the fourth tile still offered the mix. He did not play it again; he left Training, came back, and only then the tiles showed the mix as done and the fourth tile changed to "Summary · Done for today". Training must show the true state of the day the moment it appears.

## Rules

1. **Find the cause first.** Use the `diagnosing-bugs` skill. Reproduce with a test or a debug scenario: finish the last mix lesson, return to Training, read the tiles. Write the cause in the implementation notes before changing code.
2. **One source of truth.** The tiles on Training and the fourth tile ("Continue" / "Summary") must be derived from the saved day state (`TodayPlan` / progress store), not from a copy that is only refreshed on `onAppear` or on navigation. When the mix result is recorded, Training updates without leaving the screen.
3. The same must hold for reviews and the new lesson: after each step the tiles are correct right away.
4. Do not change what counts as "done"; only when the screen learns about it.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/TrainingScreen.swift`, `TodaySessionScreen.swift` (session model at the top: `record`, `finish`, `advance`, `save`), `SmackAPad/Sources/Progression/TodayPlan.swift`, `TrainingMix.swift`, `SmackAPad/Sources/Persistence/ProgressStore.swift`.

## Tests

One unit test: after the last mix lesson's outcome is recorded, the Today state reports the mix as done and the next action as the day summary, without any extra reload call.

## Acceptance criteria

- [x] After the last mix lesson, Training shows the Mix tile as done and the fourth tile as Summary immediately.
- [x] Same immediate update after a review and after the new lesson.
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

- Play the whole day (reviews, new lesson, mix). After each step look at Training without leaving it: every tile is right.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check. Do this ticket before 204.

## Implementation notes

### Cause
1. In `TodaySessionCoordinator.record(_ outcome:)`, recording the outcome of the final mix step saved the outcome into `plan.steps`, but did not advance or mark `plan.finished = true` / `plan.phase = .summary`. `TodayContinueTarget.resolve` only resolved to `.summary` if `plan.finished || plan.steps.isEmpty || plan.index >= plan.steps.count`. Even with all steps completed, `plan.index` still pointed at the mix step and `plan.finished` was false, so `resolve` continued returning `.session(plan)` instead of `.summary(plan)`.
2. On `TrainingScreen`, the Today tiles and the fourth action button derived their state from `data?.currentPlan`, a frozen snapshot in `@State private var data: TrainingData?` refreshed only in `refreshTrainingData()`. When a `fullScreenCover` (`TodaySessionScreen`) opened, `isVisible` was set to `false`. While `isVisible` was `false`, `isTrainingActive` was `false`, causing all `refreshTrainingData()` calls (from `.task(id: refreshID)` on `savedTodayPlan` changes and `onDismiss`) to be dropped by `guard isTrainingActive else { return }`. SwiftUI fullScreenCover dismissal does not reliably re-trigger `.onAppear`, so the screen remained stuck with the old snapshot until navigating away and back.

### Solution
1. In `TodayPlan`, add `var isFinished: Bool` which checks whether `finished` is true, or all steps from `index` onward have been played / decided. In `TodaySessionCoordinator.record`, if `plan.isFinished`, set `plan.finished = true` and `plan.phase = .summary` and save immediately. In `TodayContinueTarget.resolve`, check `plan.isFinished` so that when all steps are completed, the target resolves to `.summary(plan)`.
2. In `TrainingScreen`, derive `currentPlan` directly from `savedTodayPlan` (`@AppStorage`) reconciled with `progress.records` (`ProgressStore`) as the single source of truth, rather than relying on a stale snapshot in `TrainingData`. When any step outcome is recorded, `@AppStorage` and `ProgressStore` observation immediately update the tiles and the fourth button without leaving the screen or calling any extra reload. Also ensure `refreshTrainingData()` is not silently dropped on fullScreenCover dismiss.

