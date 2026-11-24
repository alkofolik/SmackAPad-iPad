# 223 — Group `UI/` into subfolders

Status: open. Follow-up A3 from ticket 210 (Desloppify baseline 92.6 / 100 on 2026-11-24).

## Goal

Organize the flat `SmackAPad/Sources/UI/` folder (currently 39 files, 0 subfolders) into domain subfolders (`Home`, `Practice`, `Library`, `Settings`, `Shared`) and update `SmackAPad.xcodeproj` accordingly.

## Rules

1. Pure file move — do not edit Swift code inside the files except if needed for anything project-relative (none expected).
2. Group files clearly into `Home/`, `Practice/`, `Library/`, `Settings/`, and `Shared/` under `SmackAPad/Sources/UI/`.
3. Update file paths and groups in `SmackAPad.xcodeproj/project.pbxproj` (do not touch `build/` or `DerivedData/`).
4. Do not touch `SmackAPadTests/` in this ticket.
5. Re-run the Desloppify objective scan after committing and note the new objective score in this ticket.

## Files to read

`AGENTS.md`, `SmackAPad.xcodeproj/project.pbxproj`, directory listing of `SmackAPad/Sources/UI/`, `docs/tickets/2026-11-21-210-desloppify-baseline-cleanup-plan.md`.

## Tests

Build only (pure file move with no code changes). No new tests.

## Acceptance criteria

- [ ] `SmackAPad/Sources/UI/` files are organized into `Home/`, `Practice/`, `Library/`, `Settings/`, and `Shared/`.
- [ ] `SmackAPad.xcodeproj` builds cleanly with all moved files.
- [ ] Desloppify objective scan re-run (`flat_dirs` for `UI` resolved) and new score noted.

### Manual iPad checks for Jakub

None required (pure file organization); optional smoke launch.

## Agent assignment

Gemini 3.8 Flash, thinking **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Build, commit, re-run Desloppify scan and record score, then stop.
