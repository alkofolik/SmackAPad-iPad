# 158 — Reviews started from Library/Home set themselves up; mark for played-but-uncounted review

Status: approved by Jakub 2026-11-09; amended same day with A6 after the agent's A5 stop (approved option 2). Ready for the agent. Blocked by: 157 (tested 2026-11-09, done). Source: Jakub's iPad check 2026-11-08 (`docs/2026-11-08-ai-panel-action-plan.md`, section "Nové z kontroly na iPadu"). Related: ticket 150 (review summary states).

## Hard constraint

Jakub does **not** want any new text in the UI. No new strings in `Localizable.strings`. Use existing icons and existing strings only. The rules/modes help and the first-launch tutorial are ticket 159, **not** part of this one.

## Design stance (Jakub)

The player must never have to think about switching modes. A lesson that is due for review today must start ready for the review, whichever door the player came through.

## Problems and rules

### A. Review opened from Library or Home plays as ordinary practice

Today `LessonLaunch.review(lesson)` (`AppNavigation.swift`) presets From memory and the goal tempo, but only the Today flow uses it. Library (`LibraryScreen.open`, `selectedLesson = .lesson(lesson)`, initial `launchTarget`) and the Home pad (`HomeScreen`, `libraryTarget` → `.lesson(lesson)`) always open `.lesson`. With From memory off the run is not a hidden pass, so it cannot count as a review (see `isHiddenPass` in `PracticeSession.swift`, ~1049).

1. Add one small pure helper, e.g. on `ProgressStore` or next to `LessonLaunch`: "is this lesson a review due today" = same condition as `PracticeSession.isDueReview` (`reviewSchedule.isDue(on: today)` and `lastReviewedDay != today`, not After me, not Mix). Reuse the existing logic; do not duplicate the date rule a third time.
2. Everywhere Library or Home turns a lesson tap into a launch, use `.review(lesson)` when the helper is true, otherwise `.lesson(lesson)` exactly as today. Find **all** such places (`grep` for `.lesson(` launches and `selectedLesson =`); report the list.
3. The preset only sets the starting state (From memory on, goal tempo). The player can still change them while stopped. No extra UI, no prompt, no banner.
4. Today, Training (Mix, After me) and lessons that are not due behave unchanged.
5. Counting is already route-independent (checked 2026-11-09 after the first A5 stop): `PracticeSession` (~1050–1105) updates the review schedule, `recordReviewRun` and the 3rd star from any route. Only the Today day plan (`TodayPlan` step outcomes, the "Passed / Did not count" summary) is fed by `TodaySessionCoordinator.record` via `onStepResult`, i.e. only from Today. Do **not** route Library/Home results into the coordinator. Fix it with A6 instead. Cover with a test that a Library-route hidden-pass run advances the schedule the same as a Today-route run.

### A6. Today reconciles with reviews done elsewhere (added 2026-11-09, approved by Jakub)

Problem: a review played from Library/Home counts in the schedule, but Today still shows that step as unplayed, offers it again, and on Skip/Finish calls `postponeIfUnplayed` → `postponeReview` on a schedule that was already decided today.

1. Add one small pure function (e.g. on `TodayPlan` or `TodaySessionCoordinator`) that, given the plan and the `ProgressStore`, marks every **review** step that has no counted outcome yet and whose lesson has `reviewSchedule.lastReviewedDay == plan.day` as decided: passed when the lesson's `lastReviewFailDay != plan.day`, otherwise not passed (`reviewNotPassed`). Use existing `PracticeStepOutcome` fields/states only (`reviewFeedback`, `reviewPendingReason`, `played`); no new enum cases with UI text, no new strings.
2. Run it when Today opens and when it returns from practice (`.task` / `leavePractice`), and before Skip/Finish. Persist via the existing `save()`.
3. A step decided this way is treated as played: the session moves past it (not offered again as the current step), `postponeIfUnplayed` does nothing for it, and it shows in the summary and step markers exactly like the same result played in Today (passed = existing passed marker, not passed = the exclamation circle from B).
4. Review steps not yet reviewed today, new-lesson and Mix steps: unchanged. Never overwrite an outcome Today already recorded.
5. Tests: plan with a review step + progress with `lastReviewedDay == today` → step becomes passed / not passed per `lastReviewFailDay`; `postponeReview` not called for it; step without today's review stays untouched; existing Today outcome is not overwritten.

### B. Played-but-uncounted review shows an empty circle

In Training / Today a review step that was played but did not count shows the same grey circle as an unplayed one, so it says nothing. The summary line "Passed: … · Did not count: …" already explains the reason in text.

1. For a review step with `outcome.played == true` and not passed, draw the existing `exclamationmark.circle` symbol (already used in `TodaySessionScreen.swift`, ~433) in place of the plain circle. Same size, same palette (orange/black/white), no new colour.
2. Unplayed and passed steps look exactly as now.
3. Add an accessibility label using an **existing** localized string (e.g. "Did not count") if one exists; otherwise leave the existing label unchanged. Do not add strings.
4. Check both places that draw step markers (`TrainingScreen.swift` ~505–530 and `TodaySessionScreen.swift`); change them consistently.

## Files to read

`AGENTS.md`, this ticket, `docs/2026-11-08-ai-panel-action-plan.md`, `SmackAPad/Sources/UI/AppNavigation.swift`, `LibraryScreen.swift` (~55–65, ~885–900), `HomeScreen.swift` (`libraryTarget`, ~630–640, ~1210–1220), `PracticeSession.swift` (`isDueReview`, ~278; hidden pass and review recording, ~1046–1110), `ReviewScheduler.swift`, `TrainingScreen.swift` (~500–540), `TodaySessionScreen.swift` (~1–60 coordinator, ~145–176, ~425–440, ~790), `Progression/TodayPlan.swift` (`PracticeStepOutcome`), `Persistence.swift` (`postponeReview` ~1516, `recordReviewRun` ~1562).

## Tests

- Helper: due today → true; not due, already reviewed today, unstarted lesson → false.
- Launch selection: a due lesson opened from Library/Home yields `.review`, a non-due lesson yields `.lesson`.
- Recording: a From-memory hidden-pass run started via the Library route is counted by the review scheduler the same as via Today (extend an existing review test rather than adding a new harness).
- Step marker: played-not-passed review picks the exclamation symbol; unplayed and passed do not (test the small pure mapping, not the view).

## Acceptance criteria

- [ ] A lesson due for review today, opened from Library or from the Home pad, starts with From memory on and at the goal tempo; the player changed nothing.
- [ ] A lesson that is not due opens exactly as before.
- [ ] A qualifying run from that route counts as a review (schedule advances as from Today).
- [ ] Today then shows that review step as done (passed, or exclamation circle if not passed), does not offer it again and does not postpone it (A6).
- [ ] A played-but-uncounted review shows the exclamation circle in Training and Today; unplayed and passed steps are unchanged.
- [ ] No new strings; build succeeds; the full existing test suite passes (AGENTS.md); new tests above added.
- [ ] **iPad test (Jakub)**: with a review due, open that lesson from the Library, then from the Home pad: it starts From memory at the goal tempo; play a qualifying run, then open Today: the step shows as passed and is not offered again. Then fail a review run and see the exclamation circle on its step.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: small change, but it touches navigation and review counting; the risk is changing how runs are scored or missing one of the entry points.

## Done rule

Run the full test suite and stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad. Report the list of entry points changed and the files touched. Report the A6 reconciliation call sites. If anything beyond the Today day plan turns out to depend on the launch route, stop and report.

## Test result (Jakub, iPad, 2026-11-10)
Tested on the iPad with the `reviewDueToday` debug scenario (Full access) per the acceptance list: review from Library and from the Home pad starts From memory at goal tempo, qualifying run counts, Today shows the step as done and does not offer it again, not-passed review shows the exclamation circle. All passed. Ticket closed.
