# 160 — Debug test scenarios: jump into any progress state, keep Jakub's real profile safe, shift the day

Status: approved by Jakub 2026-11-09 ("připrav mi to, nechám to na tobě"). Ready for the agent. Independent of 158/159 (may run in parallel only if the agent does not touch `TodaySessionScreen.swift` / `TrainingScreen.swift`; otherwise run after 158 is tested).
Recommended agent: **Codex GPT-6.1 Sol, reasoning high** (touches progress persistence; a mistake could wipe Jakub's real progress). Fallback: Gemini 3.8 Flash, high.

## Why

Jakub tests on one device with one profile that already has ~96 lessons with stars. He regularly needs to test features that only appear for a beginner (empty profile, first-run pulse from 157, legend shown once) or only after conditions he does not meet (3rd star from memory, review due today, stage unlock, free tier vs Full). Industry practice: named **seeded states / fixtures** loaded from a debug-only menu or launch argument, plus a safe backup/restore of the real data, plus an injectable clock.

## Hard constraints

1. **Everything is `#if DEBUG` only.** Nothing of this ticket may compile into a Release / TestFlight / App Store build. Verify by building Release and grepping the binary/strings or by a compile-time check; report how you verified it.
2. **Jakub's real progress must never be lost.** The real state is backed up automatically before the first scenario is applied and is never overwritten while a scenario is active.
3. No new entries in `Localizable.strings`. Debug UI uses plain English `Text(verbatim:)` and is not localised.
4. No change to any user-facing behaviour in Release. No change to the progress file format.

## What the app stores today (checked 2026-11-09)

- Lesson progress: `ProgressStore`, `<Documents>/progress.json` (`Persistence.swift` ~1024–1330; `save()`, `load()`, `resetAll(deleteFile:)`, existing `progress.corrupt-*.json` backup helper ~1140).
- Settings and first-run flags: `UserDefaults.standard`, keys prefixed `smackapad.` (e.g. `smackapad.legend.shownOnce`, `smackapad.practice.*`, `smackapad.library.*`, `smackapad.training.*`, `SettingsKey.*`).
- Badges: `BadgeStore` (UserDefaults).
- Purchases: `StoreManager.hasFullAccess` / `isUnlocked(_:)` from StoreKit entitlements.
- Day logic: `AppCalendar.todayProvider` (`Persistence.swift` ~18) is already injectable and used ~32×. Some places still call `Date()` directly (`BadgeStore` ~99/133, `ReviewReminderScheduler` ~69, `Persistence.swift` ~430).
- Existing debug-only precedent: `LegacyProgressImportSection` in `SettingsView.swift` (ticket 44).

## A. Snapshot = one folder with the whole app state

1. A snapshot contains: a copy of `progress.json` (or "absent"), all `UserDefaults.standard` keys with prefix `smackapad.` (as a plist), and the debug overrides from C and D.
2. Snapshots live in `<Documents>/DebugSnapshots/<name>/`. Small pure helper type (e.g. `DebugSnapshotStore`) with `capture(name:)`, `apply(name:)`, `list()`, `delete(name:)`. Testable with a temp directory and a separate `UserDefaults(suiteName:)`.
3. **Real profile backup:** reserved snapshot `_real`. Before any scenario or custom snapshot is applied, if no scenario is currently active, capture `_real` first (overwrite the old `_real` only in that case). A flag `smackapad.debug.activeScenario` records what is active. While it is set, `_real` is never touched.
4. **"Restore my real profile"** applies `_real`, clears the active-scenario flag and all debug overrides. `_real` itself is kept (never deleted automatically).
5. Applying a snapshot must leave the app in a consistent state. Simplest reliable way: write everything to disk, then terminate the app (`exit(0)`, DEBUG only) after a confirmation alert "The app will close. Open it again." If you can reload all stores in place reliably (`ProgressStore.load()`, `SettingsManager`, `BadgeStore`, `StoreManager`), that is allowed instead; explain which you chose.

## B. Built-in scenarios (generated in code from the lesson catalog, not hand-written JSON)

Each built-in scenario starts from an empty state (no `progress.json`, all `smackapad.` keys removed = fresh install), then adds what it needs:

| id | State |
|---|---|
| `fresh` | Brand new player. First-run pulse (157) and one-time legend must appear. |
| `introDone` | All Intro lessons 2 stars, nothing else. |
| `stage1Done` | Intro + Path stage 1 lessons 2 stars → stage 2 unlocks by the normal rule. |
| `awaitingStar3` | Several lessons at 2 stars where the next step is the From-memory 3rd star. |
| `reviewDueToday` | 3–5 lessons with 3 stars whose review schedule is due today (`reviewSchedule` due on `AppCalendar.today()`, `lastReviewedDay` not today). Today/Training must offer them; Library/Home open them as review (158). |
| `advanced` | Most of Path with 2–3 stars, a mix of due and not-due reviews, some badges. |

Build them through the existing model/APIs (`LessonProgress`, `ProgressStore`, `ReviewScheduler`), never by guessing field names. Combine with C for free vs Full.

Also: **"Save current state as…"** (text field for a name) and a list of custom snapshots with Apply / Delete, so Jakub can freeze any state he reaches by playing and return to it.

## C. Purchase override

DEBUG-only `debugAccessOverride: real | free | full` (stored as `smackapad.debug.access`). `StoreManager.hasFullAccess` and `isUnlocked(_:)` respect it in DEBUG; in Release the code path does not exist. Does not call StoreKit, does not fake transactions.

## D. Day shift ("time travel")

1. DEBUG-only day offset in whole days (`smackapad.debug.dayOffset`, −30…+60). When non-zero, `AppCalendar.todayProvider` returns today + offset.
2. Find every place that decides **day-based logic** with `Date()` directly (at least the ones listed above) and route it through `AppCalendar` or a matching injectable `now`, so review due dates, Today plan, streaks and badges all see the shifted day. Audio/MIDI timing (`PracticeSession.clock`, pad flashes, diagnostics) must **not** be shifted. Report the full list of places you changed and the ones you deliberately left.
3. Local notifications (`ReviewReminderScheduler`) are not rescheduled with the shift; leave a code comment.
4. Buttons: −1 day, +1 day, +7 days, Reset to real date.

## E. Visible marker so Jakub never forgets a test state is active

DEBUG only: while a scenario, access override or day offset is active, show a small unobtrusive tag in a screen corner that does not cover the pattern band or START/STOP (e.g. `TEST: reviewDueToday · FULL · +3 d`). Tapping it opens the debug menu. Inside the three-colour palette.

## F. Where the menu lives, launch arguments

1. A "Developer" section in Settings next to `LegacyProgressImportSection` (DEBUG only), containing B, C, D and "Restore my real profile".
2. Launch arguments for runs from Xcode (Product → Scheme → Edit Scheme → Run → Arguments): `-debugScenario <id>` applies a built-in scenario at launch (after the automatic `_real` backup from A3), `-debugDayOffset <n>`, `-debugAccess free|full`. Read them via `UserDefaults` / `ProcessInfo`. Applied before the stores load.
3. Add a short how-to to `docs/agents/` or `docs/CONTEXT.md` (debug scenarios: where the menu is, list of ids, launch arguments, how to restore).

## Tests

- Snapshot capture → apply round-trip restores identical `progress.json` and `smackapad.` keys (temp dir + suite defaults).
- `_real` is captured before the first scenario and **not** overwritten when a second scenario is applied; restore brings it back exactly.
- Each built-in scenario produces the intended state (e.g. `stage1Done` → stage 2 unlocked by `Progression`; `reviewDueToday` → `isDue(on: today)` true for those lessons).
- Day offset: `AppCalendar.today()` shifted; review due computation follows it.
- Access override: `free` locks a Full lesson, `full` unlocks it.
- Existing tests still pass.

## Out of scope

Automated XCUITest suites (may reuse these scenarios later), multiple real user profiles, any Release feature.

## Report back

What you changed (files), how Release exclusion was verified, list of `Date()` call sites changed/left, whether apply uses restart or in-place reload, test results. Commit only after Jakub has tested on the iPad.
