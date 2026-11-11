# Ticket 174 — Persistence file map

The original 2,069-line `Persistence.swift` is split at existing top-level declaration boundaries. Each declaration is moved as one unchanged byte sequence, including its comments, whitespace and conditional compilation. Only file headers and imports differ.

Both complete managers fit below 800 lines after extracting the other declarations. Keeping their methods with their stored state avoids widening private access or private setters, including those used by Observation. The proposed extension files are therefore unnecessary for this split.

| File in `SmackAPad/Sources/Persistence/` | Responsibility | Original body lines | Total lines |
| --- | --- | ---: | ---: |
| `AppCalendar.swift` | Calendar day helpers and injectable debug time | 71 | 78 |
| `SettingsTypes.swift` | `SettingsKey`, `AppAppearance`, `BpmStep` | 58 | 65 |
| `AppLanguage.swift` | Language selection and the shared localization lookup | 35 | 42 |
| `SettingsManager.swift` | Settings state, defaults, persistence, calibration, profiles, kit overrides and settings export/import | 770 | 778 |
| `ProgressModels.swift` | `LessonProgress`, `TrainingLog`, `ProgressRoot` and their unchanged encoding/decoding | 277 | 284 |
| `ProgressStore.swift` | Progress state, lifecycle handling, loading/saving, migrations, export/import, queries and mutations | 784 | 795 |
| `LegacyProgressImport.swift` | Debug-only legacy backup mapping and merging | 61 | 68 |

`Persistence.swift` is removed. Existing `ProgressBackup`, `ProgressMerge`, `BackupStorage`, `BadgeStore` and `Debug*` files retain their original names and contents. The synchronized project groups discover the new files; `project.pbxproj` is unchanged.

## Preservation checks

- No logic, values, names, public API, storage keys or stored-data format changes.
- Visibility changes: none.
- Original declaration bodies: 2,056 lines. New declaration bodies: 2,056 lines. Original file header/imports: 13 lines; new headers/imports: 54 lines. Total source lines: 2,069 before, 2,110 after.
- A byte comparison reconstructs the original declaration body from the seven new files in original order. No declaration is dropped, duplicated or rewritten.
- Each of the seven block moves is followed by a successful app build. No tests are added or changed.
- `git diff --cached --stat -M30%` detects the split rename. The default `-M` threshold cannot label a rename because every resulting file contains less than half the original file. The byte comparison above verifies all extracted blocks independently of Git’s similarity heuristic.
- Existing blank separator lines are preserved at file ends. The whitespace check passes with `core.whitespace=-blank-at-eof`; no original body whitespace is rewritten.

## Validation

- Before the split: the full suite passed all 244 tests with zero failures on the iPad (A16), iOS 27.0 simulator; the command exited normally.
- After the split: all seven incremental app builds succeeded, and the full suite again passed all 244 tests with zero failures on the same simulator. The final command exited normally; no stalled log finalization occurred.

## Manual iPad check for Jakub

Start the app and confirm that language, appearance, tempo step, calibration and controller profile remain intact, along with stars and lesson progress. Then try progress Export and Import.
