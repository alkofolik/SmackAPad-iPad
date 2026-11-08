# 149 — Progress is never overwritten after a load failure

Status: ready-for-human. Blocked by: none. Source: AI panel round 1 (`docs/reviews/ai-panel/results/synthesis.md`, item 1), verified in code; `docs/2026-11-08-ai-panel-action-plan.md`, Batch 1.

## Goal

If `progress.json` exists but cannot be decoded, the app must never replace it with an empty file. Today `ProgressStore.load()` (Persistence.swift, catch block) sets `records = [:]` and `trainingLog = TrainingLog()`, and the next `save()` (also called on background and on terminate) writes that empty state over the player's only copy. All stars, imported legacy progress and training history would be lost after one bad read.

## Rules

1. When loading fails with a decode or read error on an existing file, copy the original file once to `progress.corrupt-<yyyyMMdd-HHmmss>.json` in the same folder, before anything else. Never overwrite or delete an earlier `progress.corrupt-*` file. Keep at most the 5 newest backups.
2. While `lastLoadError != nil`, `save()` must not write `progress.json`. It must not throw on the background/terminate paths (those use `try?`); it simply skips and keeps state in memory. Any other code that mutates records and calls `save()` stays unchanged.
3. A missing file is not an error: first launch still starts empty and saves normally.
4. The player must be told. Show one plain alert at app start while `lastLoadError != nil`: "Your saved progress could not be read. A copy of the file was kept. Progress will not be saved until you choose an option." Two buttons: **Start with empty progress** (clears `lastLoadError`, allows saving; the backup copy stays on disk) and **Not now** (keeps saving blocked; alert returns next launch). Use existing localisation path; add Czech strings next to the English ones. No new screen.
5. `importLegacyBackup` keeps its current behaviour (it already throws when `lastLoadError` is set).
6. Do not change the file format, the migrations or any scoring/learning rule in this ticket.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Persistence/Persistence.swift` (`ProgressStore`: `load`, `save`, `lastLoadError`, lifecycle observers, `importLegacyBackup`), `SmackAPad/Sources/App/SmackAPadApp.swift`, `SmackAPadTests/IntroProgressMigrationTests.swift` and `LearningCreditPersistenceTests.swift` (how tests build a store with a temp file URL), localisation files used by existing alerts.

## Tests (write first)

Use a temp `fileURL` per test.
- Corrupt file (`"not json"`) → store loads empty, `lastLoadError != nil`, a `progress.corrupt-*.json` exists with the original bytes.
- After that failed load, calling `save()` leaves `progress.json` byte-identical to the corrupt original.
- After "start with empty progress" is chosen (call the store method behind the button), `lastLoadError == nil` and `save()` writes a valid file; the backup still exists.
- Valid file → no backup created, normal save works.
- Missing file → no error, no backup, save creates the file.
- Two failed loads in a row create two different backups; 6 failures keep only 5.
- Golden files: a valid current-format `progress.json` fixture with star 3 and a training log loads without error and round-trips unchanged.

## Acceptance criteria

- [x] A corrupt `progress.json` can no longer be replaced by an empty one by any code path (save, background, terminate).
- [x] The original bytes are preserved in a `progress.corrupt-*` copy.
- [ ] The alert appears and both buttons behave as described, English and Czech.
- [x] All tests in the project pass, not only the new ones (run the full test suite before commit).
- [x] No change to file format or migrations.

## Out of scope (separate later ticket)

Format version number in the file and per-lesson tolerant decoding (one bad lesson must not discard the rest). Mention this in the final message so Jakub can ask for it.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Claude Opus 5.5, extended thinking.
- **Reasoning**: touches the only copy of the player's data; needs careful reasoning about every save path.

## Done rule

Stop when the acceptance criteria are met and the full test suite passes. Commit (AGENTS.md); Jakub pushes.

## Implementation and verification

- Blocked `save()` after a load failure, including lifecycle-triggered saves, while keeping new changes in memory.
- Added non-overwriting timestamped copies, keeping the five newest. Recovery retries a failed backup before allowing the original file to be replaced.
- Added English and Czech startup alerts and explicit empty-progress recovery. Choosing Not now leaves saving blocked until a later launch and choice.
- Wrote seven regression tests before implementation. The full suite passed: 184 tests, zero failures, on the iPad Pro 13-inch (M5) simulator, including a byte-identical current-format golden-file round trip.
- Xcode built the app and reported `All tests passed`, but `xcodebuild` stalled while finalizing test logs. The command was stopped after several minutes; no tests were rerun.
- Remaining manual check: verify the startup alert and both choices on iPad in English and Czech.
- Follow-up remains out of scope: an explicit file-format version and tolerant per-lesson decoding.
