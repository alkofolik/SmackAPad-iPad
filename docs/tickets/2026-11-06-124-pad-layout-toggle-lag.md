# 124 — Pad layout toggle sometimes lags

Status: ready-for-agent. Source: Jakub, 2026-11-06 (iPad).

## Problem

In Practice, tapping the pad layout button (bottom left grid with key labels TH, TL, CR…) sometimes takes a long time before the pads with their assigned keys appear; switching back is the same. Other times it is instant.

## Rules

1. Reproduce it (try with MIDI controller connected and not, during playback and when stopped, right after opening a lesson). Find what is slow: likely rebuilding the mapping/labels on the main thread, re-reading settings or controller mapping from disk, or the view being rebuilt from scratch each time.
2. Compute the pad layout and labels once per lesson/controller mapping and keep them; the toggle only shows/hides. The switch must feel instant every time and use the existing animation.
3. No changes to MIDI input timing or scoring.
4. Give measured times (before/after, worst case) in the report.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeInstruments.swift`, `SmackAPad/Sources/UI/PracticeScreen.swift` (layout toggle only), `SmackAPad/Sources/UI/PracticeComponents.swift`.

## Acceptance criteria

- [ ] Toggle feels instant every time, both directions (times in the report).
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: toggle 10× in a row, also during playback.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: intermittent performance issue, needs measuring.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
