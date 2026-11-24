# 221 — Share repeated blocks between Calibration, Content, ControllerSetup and Settings views

Status: done (2026-11-24). Follow-up A1 from ticket 210 (Desloppify baseline 92.6 / 100 -> 92.9 / 100 on 2026-11-24; boilerplate clusters 25 -> 19).

## Goal

Extract the repeated 6–13 line UI boilerplate blocks shared across `CalibrationView.swift`, `ContentView.swift`, `ControllerSetupView.swift`, and `SettingsView.swift` into shared view helpers/components without changing any visible UI or behaviour.

## Rules

1. Run Code Simplifier only on the four listed files and any new shared helper file.
2. Inspect the 6 boilerplate clusters flagged by Desloppify across `CalibrationView.swift` (lines 52, 53, 65, 125), `ContentView.swift` (lines 78, 134, 206), `ControllerSetupView.swift` (lines 30, 216, 294, 342), and `SettingsView.swift` (lines 32, 360, 420).
3. Extract one clean shared component/modifier per repeated pattern (e.g. into `Components.swift` or a dedicated shared view file registered in `SmackAPad.xcodeproj`).
4. Keep all visible layout, styling, accessibility, and behaviour identical. Do not touch timing, scoring, audio, or MIDI.
5. Re-run the Desloppify objective scan after committing and note the new objective score in this ticket.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/CalibrationView.swift`, `SmackAPad/Sources/UI/ContentView.swift`, `SmackAPad/Sources/UI/ControllerSetupView.swift`, `SmackAPad/Sources/UI/SettingsView.swift`, `docs/tickets/2026-11-21-210-desloppify-baseline-cleanup-plan.md`.

## Tests

Build only (pure UI refactor with no logic change), plus any existing tests for these views if present. No new tests.

## Acceptance criteria

- [x] Repeated boilerplate blocks across the four views are replaced by shared components/modifiers.
- [x] Visible UI and behaviour are unchanged.
- [x] App builds cleanly without warnings or errors.
- [x] Desloppify objective scan re-run and new score noted (92.9 / 100).

### Manual iPad checks for Jakub

Open Settings, Controller setup, and Calibration; verify layout and interactions look and behave identically.

## Agent assignment

Gemini 3.8 Flash, thinking **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Build, run area tests if any, commit, re-run Desloppify scan and record score, then stop for Jakub's iPad check.
