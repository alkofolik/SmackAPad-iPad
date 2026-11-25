# 235 — Training & Day Summary: instrument layout, Mon–Sun weekly rhythm, and stage milestones

Status: ready-for-agent

## Goal

Restyle `TrainingScreen` and `DaySummaryView` to match the strict `8 pt / 6 pt` studio-instrument design system, add a non-punitive Monday–Sunday practice rhythm strip (`practiceDays` tracked for all completed practice runs without altering badge `trainingDays`), and surface stage-unlock milestones in `DaySummaryView`.

## Rules

1. **Track `practiceDays` for all completed runs (`ProgressModels.swift`, `ProgressStore.swift`, `ProgressMerge.swift`).**
   - Add `public var practiceDays: Set<String>` to `TrainingLog` (`ProgressModels.swift`).
   - On decode, initialize `practiceDays` from decoded `practiceDays` unioned with `trainingDays` and `Set(lessons.values.compactMap(\.lastPlayedDay))` so existing users keep their history. Merge via `.union` in `TrainingLog.merging`.
   - Insert `today` into `trainingLog.practiceDays` whenever a full lesson run is recorded in `ProgressStore` as well as in `recordReviewRun`, `recordFinishedMixRound`, and `recordAfterMeResponse`. Keep `trainingLog.trainingDays` unchanged so `BadgeEvaluator` rules do not shift.
2. **Pure `WeeklyRhythm` helper (`SmackAPad/Sources/Progression/WeeklyRhythm.swift`, registered in `SmackAPad.xcodeproj`).**
   - Compute the 7 calendar days (`Monday...Sunday`, ISO week in `AppCalendar` / Gregorian with `firstWeekday = 2`) containing `today`, marking for each day: `dayString`, localized short weekday, `practiced: Bool`, `isToday: Bool`, plus `practicedThisWeek: Int` and `totalPracticedDays: Int` (`practiceDays.count`). No streak-break warnings or red states—rest days are neutral `Theme.surface` cells, practiced days light up with a crisp `Theme.orange` indicator.
3. **`TrainingScreen.swift` visual & hierarchy redesign.**
   - Replace `20–24 pt` corner radii and `Barlow Condensed` 40 pt `"TODAY"` with `Theme.Radius.panel` (`8 pt`) panels and `IBM Plex Sans` (`Theme.screenTitle` 26 pt, `Theme.sectionTitle` 19 pt).
   - **Today hero panel:** crisp `8 pt` orange panel (`Theme.orange`). Inside it, replace `Theme.white.opacity(0.5)` low-contrast waiting tiles with solid `Theme.white` (for current/done) and opaque warm cream (`Theme.Skin.Plate.top` with `1 pt` `Theme.black.opacity(0.20)` border for waiting steps, `2 pt` `Theme.black` border + `"NOW"` tag for current step) so every label meets ≥ 4.5:1 contrast. Keep one prominent dark primary `Start / Continue` action showing remaining steps and `~X min`.
   - **Weekly rhythm strip:** compact `8 pt` panel directly under the Today panel showing the 7 `Mon–Sun` cells + `"Tento týden: %lld× · Celkem %lld dní"` (`"This week: %lld× · %lld days total"`).
   - **Calm secondary tools:** place `Play after me`, `Extra mix`, and a single clean divided `8 pt` panel holding `Review queue`, `Memory & next 7 days`, and `Badges` below, using `PadPrimaryButtonStyle` / `PadSecondaryButtonStyle`.
4. **`DaySummaryView.swift` redesign & stage milestone.**
   - Replace the `24 pt` black box + `20 pt` giant checkmark icon + `64 pt` `Barlow Condensed` heading with an `8 pt` studio summary layout in `IBM Plex Sans`: clear `26 pt` title, date, divided 3-column stat strip (no icons in circles, tabular figures), the updated `Mon–Sun` `WeeklyRhythm` strip lighting up today, and a **Stage milestone row** showing progress toward the next locked `LibraryStage` (`"Další milník: %@ · %lld / %lld lekcí se 2★"` / `"Next milestone: %@ · %lld / %lld 2★ lessons"`, or `"Milník splněn · %@ odemčeno"` when unlocked).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Persistence/ProgressModels.swift`, `SmackAPad/Sources/Persistence/ProgressStore.swift`, `SmackAPad/Sources/Persistence/ProgressMerge.swift`, `SmackAPad/Sources/UI/Practice/TrainingScreen.swift`, `SmackAPad/Sources/UI/Practice/DaySummaryView.swift`, `SmackAPad/Sources/Progression/Progression.swift` (`unlockProgress(for:)`).

## Tests

Add `SmackAPadTests/WeeklyRhythmTests.swift` (and extend `TrainingLogAndBadgesTests` & `ProgressBackupTests`) verifying Monday–Sunday week calculation, Day-1 beginner lesson lighting `practiceDays` while leaving `trainingDays` badge count untouched, and `ProgressMerge` unioning `practiceDays`. Run full test suite (`Persistence` and `Progression` touched).

## Acceptance criteria

- [ ] Completing any lesson (including Intro 1 on Day 1) lights today in the Mon–Sun rhythm strip without inflating `BadgeEvaluator`'s `trainingDays`.
- [ ] `TrainingScreen` and `DaySummaryView` use `8 pt` panels, `6 pt` tactile buttons, `IBM Plex Sans` typography, and high-contrast opaque step tiles (no 20–24 pt bubbles, no 50% translucent tiles, no giant checkmark tile).
- [ ] `DaySummaryView` displays the weekly rhythm strip and the exact distance to (or completion of) the next `LibraryStage` milestone.
- [ ] Full test suite passes.

### Manual iPad checks for Jakub

Open Training and Day summary in landscape and portrait, light and dark mode; verify legibility of Today step tiles, check the Mon–Sun rhythm strip after completing a lesson, and check the stage milestone readout in Day summary.

## Agent assignment

Gemini 4 Carbon (or Codex GPT-6.1 Sol), thinking **high**.

## Done rule

Build, run full test suite per `AGENTS.md`, commit on `release-polish`, stop for Jakub's iPad check.
