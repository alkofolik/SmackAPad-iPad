# 65 — Library: hide completed lessons (setting, on by default)

Status: ready. Source: Jakub, 2026-11-04. Run after ticket 62 (both touch `SettingsView.swift`).

## Problem

Lists fill up with lessons the player has already finished, mainly on the Intro page, so the next lessons are hard to find.

## Rules

- **Completed** = `progressStore.isCompleted(lessonId:)` (star 1 and star 2), the same definition the stage unlock uses. Star 3 is not required.
- New setting **"Skrýt hotové lekce / Hide completed lessons"**, **on by default**, stored like the other library settings in `SettingsManager` (`Persistence.swift`). Place it in Settings in the section with "Next lesson from" (rename that section header to "Knihovna / Library" if it reads better; say so in the report).
- When on, completed lessons are left out of: the Intro page list, every library group (path stages, genres, techniques).
- Search results still show all matching lessons (otherwise a player cannot find a finished lesson to replay).
- A group or the Intro page whose lessons are all completed shows one quiet line "Všechny lekce jsou hotové / All lessons completed" with a button "Zobrazit hotové / Show completed" that turns the setting off.
- Counts like "completed 11/25" and star totals still count all lessons.
- Not affected: the home screen (the Intro pad stays), Continue, the library's "Next" banner, stage unlock logic.
- Use the existing list motion (`Theme.Motion`) when a lesson disappears after it is completed; Reduce Motion as elsewhere.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Persistence/Persistence.swift` (`SettingsManager`, `isCompleted`), `SmackAPad/Sources/UI/SettingsView.swift` (section "Next lesson from"), `SmackAPad/Sources/UI/LibraryScreen.swift`, `SmackAPad/Sources/UI/IntroScreen.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] Fresh install: setting is on; completed lessons are hidden on the Intro page and in all groups; search still finds them.
- [ ] Turning it off shows them again immediately.
- [ ] An all-completed group shows the line and the button.
- [ ] Cs and en; light and dark.
- [ ] Build passes; do not run tests (see AGENTS.md).
- [ ] **iPad test (Jakub)**: Intro page with some lessons completed, toggle the setting, search a completed lesson.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium** thinking: one setting and list filtering in two screens. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
