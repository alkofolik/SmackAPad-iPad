# 224 — Split `SettingsManager.swift` by area

Status: open. Follow-up B4 from ticket 210 (Desloppify baseline 92.6 / 100 on 2026-11-24). Run after 221–223 or independently (no overlap with `UI/`).

## Goal

Split `SmackAPad/Sources/Persistence/SettingsManager.swift` (792 lines, 26 function groups) into focused files by responsibility (e.g. profiles, calibration, reminders, hints/appearance) without changing persistence keys, defaults, or behaviour.

## Rules

1. Run Code Simplifier only on `SettingsManager.swift` and the new split files.
2. Keep all `UserDefaults` / storage keys, property names, `@Observable` / published state, and behaviour 100 % identical so existing user settings migrate seamlessly.
3. Register all new files in `SmackAPad.xcodeproj`.
4. Because this touches Persistence, run the **full test suite** before committing (`AGENTS.md` rule).
5. Re-run the Desloppify objective scan after committing and note the new objective score in this ticket.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Persistence/SettingsManager.swift`, `SmackAPad.xcodeproj/project.pbxproj`, `docs/tickets/2026-11-21-210-desloppify-baseline-cleanup-plan.md`.

## Tests

Full test suite (`AGENTS.md` requires full suite when touching persistence). No new tests unless needed for the split.

## Acceptance criteria

- [ ] `SettingsManager.swift` is split into focused files by area.
- [ ] All persistence keys and behaviours remain identical.
- [ ] App builds and full test suite passes.
- [ ] Desloppify objective scan re-run and new score noted.

### Manual iPad checks for Jakub

Change a setting (appearance, calibration, or controller profile), relaunch the app, and confirm it persists.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run full test suite, commit, re-run Desloppify scan and record score, then stop for Jakub's iPad check.
