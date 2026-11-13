# 195 — Pad layout shows keyboard keys only after a tap, never by itself

Status: implemented and verified, pending Jakub's iPad check. Reported by Jakub on 2026-11-13 with an iPad screenshot ("TH · 1", "KD · Z" on the pad layout without tapping it).

## Cause (from the code)

- `PracticePadLayoutSquare` keeps the toggle in `@AppStorage("smackapad.practice.showPadKeys")`. One tap turns the keys on for every later lesson and every app start.
- `SettingsManager` (about line 688) and `ProgressBackup` (about lines 84 and 165) default `showPadKeys` to **true**, so a restored backup or a missing value turns the keys on without any tap.

## Rules

1. The key labels are a **temporary view state**: off every time the practice screen opens. A tap on the pad layout shows them; another tap hides them. Leaving the lesson (or going to the next lesson in a mix or Today session) turns them off again.
2. Keep it as plain view state (`@State`) on the practice screen, not in `UserDefaults`, not in `SettingsManager`, not in the backup.
3. **Delete the old rule completely:** the `@AppStorage` key, `showPadKeys` in `SettingsManager` (read and write) and in `ProgressBackup` (field, init parameter, coding key). Old backups that still contain `showPadKeys` must decode without error; the value is ignored. Remove the stored `smackapad.practice.showPadKeys` value once at launch so it cannot come back.
4. Delete tests that enforce the old persisted or default-true behaviour.
5. Nothing else about the pad layout changes (size, flashes, tap target, accessibility hint).

## Files to read

`AGENTS.md`, `PracticeComponents.swift` (`PadLayoutModel`, `PadLayoutGrid`, `PracticePadLayoutSquare`), `SettingsManager.swift` (about lines 680–780), `ProgressBackup.swift`, the backup tests in `SmackAPadTests`.

## Tests

1. A backup JSON that contains `"showPadKeys": true` decodes without error.
2. A newly encoded backup contains no `showPadKeys` key.

## Acceptance criteria

- [x] Opening any lesson shows the pad layout without key labels.
- [x] Tap shows the keys, tap again hides them.
- [x] After leaving the lesson, the next lesson starts without keys again; same after an app restart and after restoring a backup.
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

Open a lesson, tap the pad layout (keys appear), go back, open another lesson: no keys. Quit and reopen the app: no keys.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
