# 190 — Bug: Home → Today → Continue turns the screen black

Status: ready-for-agent. Reported by Jakub on 2026-11-12.

## What Jakub saw

Open the app, tap the top-left Home pad **Today**, then tap **Continue** at the top right: the screen goes black and nothing happens. Swiping up from the bottom edge of the iPad (app switcher / shrinking the app) brings back the **old window** — the one that was merged/changed in the Today + Training merge — instead of a live screen.

## Known facts from reading the code (not yet reproduced)

- `TrainingScreen.startTodayTraining()` sets `activeTodayPlan` and `showingToday = true`; the cover is `.fullScreenCover(isPresented: $showingToday) { if let plan = activeTodayPlan { TodaySessionScreen(...) } }`. If the closure ever evaluates with `activeTodayPlan == nil` (or the plan has no steps, or all steps are done), the cover is an empty black page with no back control.
- `HomeScreen` (pad "Today", line ~1049) and `TrainingScreen` both exist after the merge; the old Today route may still point at a leftover screen (`TodaySessionScreen` wrapper presented from Home with its own `fullScreenCover`). Check that Home's Today pad opens the merged Training screen only, and that no cover is presented while another cover/navigation transition is still running (SwiftUI drops the second presentation and leaves a black window).
- The app-switcher snapshot showing an older window hints at a second scene/window or a stuck presentation, not a normal navigation.

## Rules

1. Reproduce in the simulator on a build of current `main` plus the pending uncommitted toolbar fixes, with (a) the real profile, (b) `fresh`, (c) `reviewDueToday`, (d) a finished day (all steps done). Record which of them go black, and print/log `currentPlan`, `activeTodayPlan` and the presented covers at the moment of the tap.
2. Fix the cause. Whatever happens, a presented screen must never be empty: if there is no plan or the plan is finished, Continue shows the day summary (or is disabled), never a blank cover; every cover has a visible back arrow.
3. Make sure the old Today screen is not reachable any more (merge ticket 182 follow-up) and nothing is presented from Home and Training at the same time.
4. Add a debug assertion/log (DEBUG only) when a full-screen cover is presented with empty content.

## Files to read

`AGENTS.md`, `HomeScreen.swift` (pads, `activeDestination`), `TrainingScreen.swift` (`startTodayTraining`, covers), `TodaySessionScreen.swift`, `AppNavigation.swift`, `ContentView.swift`, ticket 182.

## Tests

Unit test for the plan-or-summary decision (given plan/finished/none → what Continue opens). UI behaviour is verified manually.

## Acceptance criteria

- [x] Cause written into the ticket notes.
- [x] Home → Today → Continue opens a live screen in all four scenarios; never a black one.
- [x] Build and full test suite pass.

### Reproduced cause & fix (2026-11-12)

- **Reproduced in `iPad (A16)` simulator**:
  - When `currentPlan != nil` (`reviewDueToday`, simulator profile with an active plan, and a finished day), tapping **Continue** set `activeTodayPlan = plan` and `showingToday = true`, but SwiftUI evaluated `.fullScreenCover(isPresented: $showingToday)` before reading `activeTodayPlan` in `TrainingScreen.body`, rendering an `EmptyView()` (`PresentationHostingController<AnyView>` with `subviews=0`, blank black modal with no back button). A scene/app-switcher transition then forced a body re-render that revealed `TodaySessionScreen`.
  - When `currentPlan == nil` (`fresh`, `stage1Done`), `startTodayTraining()` also wrote `savedTodayPlan`, which fired `.onChange(of: savedTodayPlan)` → `refreshID = UUID()` and forced a re-render with `activeTodayPlan` populated.
- **Fix**:
  - Replaced separate `(isPresented, state)` pairs with `.fullScreenCover(item:)` (`TodayContinueTarget`, `MixCoverItem`, `TodayPracticePresentation`) in `TrainingScreen` and `TodaySessionScreen`.
  - Added `TodayContinueTarget.resolve(...)` so active plans open `TodaySessionScreen`, finished/empty/exhausted plans open `DaySummaryView` directly, and **Continue** is disabled when neither a plan nor fallback steps exist.
  - Added `hasActiveCover` / `HomeScreen` idle guards so Home and Training (or multiple Training covers) cannot present simultaneously, cleared `helpPresentation` on route switch, and added `EmptyCoverFallbackView` with a visible `BackButton` plus `#if DEBUG` `print` / `assertionFailure`.

### Manual iPad checks for Jakub

Cold start the app → Today → Continue, three times, in `fresh`, `reviewDueToday` and with the real profile; then swipe up to the app switcher and back: the app shows the live screen.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
