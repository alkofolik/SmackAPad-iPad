# 44 — Import progress from the legacy tool's backup (debug builds only)

Status: ready. Source: Jakub, 2026-11-03 (approved). Stage unlock "L1-ghost" is explicitly **out of scope**.

## Problem

Jakub's completed lessons and stars exist only in the legacy web app's backup (`smack-a-pad-backup-2026-10-30.json`, `formatVersion` 1, `app` = "padwork"). The iPad app starts without them.

## Goal

A debug-only import that merges the legacy stars into the app's progress. It must not exist in Release/App Store builds.

## Source data (verified on the real backup)

- `rewards.stars` is an object keyed by legacy lesson id (string): `{ passed: Bool, mastered: Bool, memory: <ISO timestamp, optional> }`. 96 lessons; 23 have ★★★, 65 ★★, 7 ★, 1 has passed + memory without mastered.
- `progress` is keyed by lesson id: `bpm`, `best` (0–100), `plays`, `passed`, `mastered`, `introChecks` (ignore).
- All 96 ids exist in the app's lesson data, or are retired First-steps ids that `ProgressStore.duplicateIntroLessonMap` already maps (1→10001, 2→10015, 3→10008, 4→10010, 5→10011, 7→10016, 8→10013, 9→10014).

## Mapping

- `passed` → `LessonProgress.passed` (★1); `mastered` → `mastery` (★2); presence of `memory` → `memory` (★3).
- `progress[id].bpm` → `currentBpm`; `progress[id].best / 100` → `bestScore` (app scale is 0–1).
- `hasPlayed = true` for every imported lesson.
- Import only lessons present in `rewards.stars` (at least one star). Rarely played lessons without stars are skipped.
- Retired ids: write the record under the Intro twin using the same rule as `migrateDuplicateIntroProgress()` (reuse it; do not duplicate the logic).
- **Merge, never lower:** for an existing record take the logical OR of the three star flags, the higher `bestScore`, keep an existing `currentBpm` if > 0. Never remove or reduce existing progress.
- Ignore every other key in the file (settings, MIDI maps, `unlockedStages`, training, songs, etc.).

## Rules

- Add the import in Settings behind `#if DEBUG`: a section "Import from legacy backup" with a button that opens `.fileImporter` for a JSON file.
- Validate the file (`app == "padwork"`, `formatVersion == 1`, `rewards.stars` present). On a wrong file show an error and change nothing.
- Back up the current `progress.json` to `progress.json.pre-import` in Documents before writing; keep it if it already exists only when the new backup would overwrite an older import (overwrite is fine).
- Apply through `ProgressStore` (not by writing the file directly) and save; show a result message: number of lessons imported, how many stars were added. Importing the same file twice must change nothing the second time.
- Add unit tests for the mapper (pure function: legacy JSON → `[Int: LessonProgress]` and the merge), including a retired id, a memory-only star, and idempotency. These are the only tests to add or run for this ticket if AGENTS.md allows test runs for new code; otherwise write them and report that they were not run.
- Strings: add cs and en entries. No changes to colours or typography.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Persistence/Persistence.swift` (`LessonProgress`, `ProgressStore`, `migrateDuplicateIntroProgress`), `SmackAPad/Sources/Progression/LibraryCatalog.swift` (`LibraryStarFilter.stars`), `SmackAPad/Sources/UI/SettingsView.swift`. Do not read or copy the legacy app's code.

## Acceptance criteria

- [ ] Debug build: after importing the backup, the library shows 23 lessons with ★★★, 65 with ★★ and 8 with 1 star or mixed stars, matching the counts above (Intro twins merged into the Intro lessons).
- [ ] Release build contains no import UI or code path (`#if DEBUG`).
- [ ] Re-importing changes nothing; an invalid file changes nothing and shows an error.
- [ ] Existing stars are never lowered; `progress.json.pre-import` exists after import.
- [ ] Build passes.
- [ ] **iPad test (Jakub)**: put the backup on the iPad (Files/AirDrop), run the import from Settings, check the library counts and a few lessons.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app), **medium** reasoning. Small, isolated, but it touches the progress file, so a mistake there would damage saved stars; the back-up and merge-only rules above are the safeguards.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.

## Implementation — 2026-11-03

- Added DEBUG-only JSON import in Settings, validation, merge-only mapping, shared Intro migration, original-file backup, save rollback, and localized results.
- Added mapper, retired ID, memory-only star, merge, idempotency, invalid-input and backup regression tests in `IntroProgressMigrationTests.swift`. Tests were not run under AGENTS.md.
- Generic iOS Debug build passed with signing disabled. Sandbox initially blocked Swift macro tools; the unrestricted build succeeded.
- Existing localization content was preserved byte-for-byte; new entries were appended.
- Real-backup counts and device acceptance remain for Jakub on iPad. Commit follows the explicit conversation AGENTS.md instruction.
