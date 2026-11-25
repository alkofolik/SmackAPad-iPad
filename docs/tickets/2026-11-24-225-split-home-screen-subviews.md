# 225 — Split `HomeScreen.swift` into sub-views

Status: open. Follow-up B5 from ticket 210 (Desloppify baseline 92.6 / 100 on 2026-11-24). Recommended after 223 (`UI/` subfolders) so new files land directly in `UI/Home/`.

## Goal

Extract sub-views from `SmackAPad/Sources/UI/HomeScreen.swift` (1872 lines) into separate focused files without changing Home screen layout, hardware-controller look, MIDI reactivity, or performance.

## Rules

1. Run Code Simplifier only on `HomeScreen.swift` and the extracted sub-view files.
2. Respect ticket 209: per-hit / high-frequency MIDI values must be read only in leaf views, never hoisted into `HomeScreen.body`.
3. Keep all Home screen behaviour (faders, language knob, appearance switch, pad grid, MIDI activity) identical.
4. Register all new files in `SmackAPad.xcodeproj`.
5. Re-run the Desloppify objective scan after committing and note the new objective score in this ticket.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/HomeScreen.swift` (or `UI/Home/HomeScreen.swift` after 223), `docs/tickets/2026-11-18-209-playhead-stalls-on-every-pad-hit.md`, `docs/tickets/2026-11-21-210-desloppify-baseline-cleanup-plan.md`.

## Tests

Build and run Home-related tests (`-only-testing`) if any exist. No new tests.

## Acceptance criteria

- [x] `HomeScreen.swift` sub-views are extracted into separate focused files.
- [x] Leaf-view observation rule (ticket 209) is preserved.
- [x] App builds and relevant tests pass.
- [x] Desloppify objective scan re-run and new score noted: **94.1 / 100** (File health 88.5 %, Code quality 91.8 %, Duplication 98.8 %, Security 100.0 %; 49 issues, up from 92.6 / 100).

### Manual iPad checks for Jakub

Open Home in portrait and landscape, light and dark mode; test language knob, appearance switch, faders, and MIDI controller hits.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run area tests, commit, re-run Desloppify scan and record score, then stop for Jakub's iPad check.
