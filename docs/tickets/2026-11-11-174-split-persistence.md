# 174 — Split Persistence.swift into smaller files (no behaviour change)

Status: ready-for-agent. Approved by Jakub on 2026-11-11. Corresponds to AI panel item #29. Run after ticket 173 (both touch `AppLanguage` / `Persistence.swift`) and before the iCloud sync ticket 162.

## Goal

`Persistence/Persistence.swift` (about 2,100 lines, 83 KB) holds several unrelated parts. Split it into smaller files by content by moving code only. No logic, value, name or stored-data format changes.

## Rules

- Move code whole; never retype or rewrite it.
- No public API change. If a member needs wider visibility only because it now sits in another file (`private` → `fileprivate`/internal), allow it and list each case in the final report.
- No new UI text, no new features, no clean-up "while at it".
- Keep the existing files in `Persistence/` (`ProgressBackup`, `ProgressMerge`, `BackupStorage`, `BadgeStore`, `Debug*`) under their names.
- The project uses synchronized folder groups, so new files are picked up automatically. Do not edit `project.pbxproj`.

## Known starting point (verify first)

Parts of `Persistence.swift`: `AppCalendar` (~14), settings types `SettingsKey`/`AppAppearance`/`BpmStep` (~85–143), `AppLanguage` (~144–210), `SettingsManager` (~216–985, with MARK sections Defaults, Stored Properties, Memory Star Hint, Computed Helpers, Initialization, Persistence Helpers, Calibration, Controller Profiles, Lesson Kit Override, Device ID & Export/Import), `LessonProgress`/`TrainingLog`/`ProgressRoot` (~986–1262), `ProgressStore` (~1267–2048, with MARK sections Load & Save, Export/Import, Query Methods, Mutation Methods), `LegacyProgressImport` (~2049).

## Proposed layout (agent may adjust names if a better boundary exists)

1. `AppCalendar.swift`
2. `SettingsTypes.swift` (keys, appearance, BPM step)
3. `AppLanguage.swift`
4. `SettingsManager.swift` (core) plus extensions `SettingsManager+Calibration.swift`, `+ControllerProfiles.swift`, `+KitOverrides.swift`, `+Export.swift`
5. `ProgressModels.swift` (`LessonProgress`, `TrainingLog`, `ProgressRoot`)
6. `ProgressStore.swift` (core) plus `ProgressStore+LoadSave.swift`, `+ExportImport.swift`, `+Queries.swift`, `+Mutations.swift`
7. `LegacyProgressImport.swift`

## Steps

1. Run the full test suite first; note the test count and result.
2. Move one block at a time; build after each move.
3. Check the result: `git diff --stat -M` shows moves, not rewrites; line totals match the original apart from file headers.
4. Write a short file map to `docs/design/2026-11-11-174-persistence-split.md`.

## Tests

No new tests. The full suite must give the same count and result as before the split.

## Acceptance criteria

- [ ] Same test count and all passing.
- [ ] No file in `Persistence/` has more than about 800 lines.
- [ ] No logic, value or name changed; visibility changes (if any) listed.
- [ ] File map documented.

### Manual iPad check for Jakub

Start the app and confirm settings (language, appearance, tempo step, calibration, controller profile), stars and progress are intact; then try progress Export and Import (ticket 161).

## Agent assignment

Codex GPT-6.1 Sol, thinking high (fallback Gemini 3.8 Pro, high). Do not use Flash: with a 2,100-line file it can silently drop or rewrite code while moving it.

## Done rule

Build, full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check. If the build fails twice, stop and report. Final report: max 5 lines.
