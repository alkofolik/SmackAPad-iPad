# 232 — Unified guided path (Intro → Path) and always-ready 3–5 minute Today plan

Status: ready-for-agent

## Goal

Connect the 25 `Intro` exercises directly to the front of the guided `Path` in `ProgressionManager` (with a reversible one-tap skip for experienced players), remove the competing first-run pulse on the Home `Intro` pad, and ensure `TodayPlan` always builds a 3–5 minute daily session with step count and estimated minutes on the Home `Today` pad—even when no spaced reviews are due.

## Rules

1. **Skip-basics setting (`SettingsManager`).**
   - Add `introSkipped: Bool` (default `false`, key `"smackapad.progression.introSkipped"`) to `SettingsManager` (`SettingsManager+Preferences.swift` / `SettingsManager.swift`) and include it in `PortableSettings` (`ProgressBackup.swift` & `ProgressMerge.swift`) with safe optional decoding for existing backups.
   - When `!settings.introSkipped` and either no `catalog.path` lesson has been passed yet or `anchor` is nil / an `intro` lesson, `ProgressionManager.nextLesson(after:source: .path)` returns the next unpassed playable exercise from `catalog.introLessons` (ordered 1…25) before advancing into `catalog.path.first`. If `anchor` is already a `path` lesson (existing active user), continue from `anchor` naturally unless all `path` lessons are passed.
   - Respect 8-pad mode (`!settingsManager.activeProfile().isEightPad || EightPadLayout.slots(for: lesson) != nil`) in `nextLesson` for both `Intro` and `Path` lessons.
2. **One-tap skip/restore in `IntroScreen.swift`.**
   - When `!isAllIntroCompleted`, show a calm inline banner/button at the top of `IntroScreen`: `"Already know the basics? Skip to Path"` (`"Už základy umím · přejít na Cestu"`), which sets `settings.introSkipped = true` (and when `settings.introSkipped == true`, shows `"Basics skipped · Resume Intro"` / `"Základy přeskočeny · Vrátit se k Úvodu"` so the user can re-enable it anytime).
3. **Single undisputed entry on Home (`HomePadGrid.swift`, `HomeScreen.swift`, `HomePadView.swift`).**
   - Remove `shouldPulseIntroPad` and `introFocusEligible` from `HomePadGrid.swift` and `HomeScreen.swift`, and delete obsolete tests enforcing `shouldPulseIntroPad`. Pad 1 (`TODAY`, orange hero) is now always the single primary starting point, even on first launch.
4. **Always-ready 3–5 minute `TodayPlan` (`TodayPlan.swift`, `HomeScreen.swift`, `TrainingScreen.swift`).**
   - Update `TodayPlan.make(day:dueLessonIDs:nextLessonID:followUpLessonID:mixLessonIDs:)`: do **not** return `nil` when `dueLessonIDs.isEmpty`.
     - Up to `LearningRules.dailyReviewLimit` (`2`) `.review` steps from `dueLessonIDs`.
     - Append `.newLesson` with `nextLessonID` if available.
     - If `dueLessonIDs.isEmpty` and `mixLessonIDs.count < LearningRules.minimumMixLessons`, append a second `.newLesson` step with `followUpLessonID` (the next unpassed playable lesson after `nextLessonID`, if distinct) so Day-1 beginners get a crisp 2-lesson (~3–4 min) block.
     - Append `.mix` if `mixLessonIDs.count >= LearningRules.minimumMixLessons`.
     - Return `nil` only if `steps.isEmpty`.
   - Add computed `estimatedMinutes: Int` on `TodayPlan` based on remaining unplayed steps (`review` = 1.5 min, `newLesson` = 2.0 min, `mix` = 2.0 min; rounded, minimum `2` when `!isFinished`, `0` when finished).
   - Update `HomePadSubtitles.today(plan:language:)` to format `"3 kroky · 5 min"` / `"3 steps · 5 min"` when unfinished, and `"Hotovo pro dnešek"` / `"Done for today"` when `plan.isFinished == true` (update `HomeScreen.todayPlan` so a finished plan for today is passed through to `HomePadSubtitles.today` instead of coerced to `nil`).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Progression/Progression.swift` (lines 560–585), `SmackAPad/Sources/Progression/TodayPlan.swift`, `SmackAPad/Sources/Progression/TodaySessionCoordinator.swift`, `SmackAPad/Sources/UI/Home/HomePadGrid.swift`, `SmackAPad/Sources/UI/Home/HomePadView.swift` (`HomePadSubtitles`), `SmackAPad/Sources/UI/Home/HomeScreen.swift` (lines 405–475), `SmackAPad/Sources/UI/Library/IntroScreen.swift`, `SmackAPad/Sources/Persistence/SettingsManager.swift`, `SmackAPad/Sources/Persistence/SettingsManager+Preferences.swift`, `SmackAPad/Sources/Persistence/ProgressBackup.swift`.

## Tests

Update `TodayPlanTests`, `HomePadSubtitlesTests`, `FirstRunAndLegibilityTests`, and `ProgressionTests` (delete old `shouldPulseIntroPad` and nil-when-no-reviews assertions; add tests for: fresh user `nextLesson` starts at Intro 1 and transitions to Path after Intro 25; `introSkipped == true` jumps straight to Path; 8-pad profile skips 16-pad-only lessons; `TodayPlan.make` builds a 2-step plan on Day 1 and `estimatedMinutes` + `HomePadSubtitles.today` format correctly). Run full test suite (`Progression` and `Persistence` touched).

## Acceptance criteria

- [ ] On a fresh profile, `Today` pad shows `"2 steps · 4 min"` (`"2 kroky · 4 min"`), `Intro` pad does not pulse, and starting Today opens Intro exercise 1 followed by Intro exercise 2.
- [ ] Tapping `"Skip to Path"` in `IntroScreen` switches guided `nextLesson` to `Path` Stage 1 and can be undone.
- [ ] In 8-pad controller mode, neither `nextLesson` nor `TodayPlan` selects a 16-pad-only lesson.
- [ ] After finishing all steps of Today, the Home `Today` pad shows `"Done for today"` / `"Hotovo pro dnešek"`.
- [ ] Full test suite passes.

### Manual iPad checks for Jakub

Test with Debug scenario "Fresh install" and "Active learner": check Home `Today` subtitle, start Today on fresh install (verify Intro 1 opens), test skipping basics in Intro, and finish a daily plan to verify the finished subtitle on Home.

## Agent assignment

Gemini 4 Carbon (or Codex GPT-6.1 Sol), thinking **high**.

## Done rule

Build, run full test suite per `AGENTS.md`, commit on `release-polish`, stop for Jakub's iPad check.
