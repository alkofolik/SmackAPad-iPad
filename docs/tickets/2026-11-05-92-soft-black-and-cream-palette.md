# 92 — Palette: soften pure white and pure black (cream white, warm soft black)

Status: ready. Source: Jakub, 2026-11-05: likes the simple palette, but pure white feels too harsh and pure black too black. Wants white slightly creamy and black softened.

## Problem

`Theme.swift` uses `Color.white` / `Color.black` and grey values built from `UIColor(white:)`. Pure #FFFFFF and #000000 give maximum glare on the iPad display, especially in a dim room where the app is mostly played.

## Rule

Change the values **only in `Theme.swift`** (the one central place). No view file gets its own colour. Starting values (warm, never neutral grey, so cream and ink match):

| Token | Light | Dark |
|---|---|---|
| `Theme.white` (fixed) | `#F4EFE6` | same |
| `Theme.black` (fixed) | `#1F1D1A` | same |
| `Theme.background` | `#F4EFE6` | `#1F1D1A` |
| `Theme.ink` | `#1F1D1A` | `#F4EFE6` |
| `Theme.surface` | `#EBE5DA` | `#2A2824` |
| `Theme.secondary` | `#5E5950` | `#B3ADA2` |
| `starColor` (not done) | `#D6D0C4` | `#3E3B36` |

- Orange `#FF6B00` and the three result-mark colours stay unchanged.
- Replace the leftover direct `Color.white` / `Color.black` uses (PatternField, HomeScreen and similar; find them with a search) by the Theme tokens, so nothing stays pure black or pure white.
- Keep the hand markers R (dark) and L (light) clearly distinguishable.
- If the cream looks too yellow or too grey on the iPad, Jakub adjusts the single hex value in `Theme.swift`; say in the report where they are.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/Theme.swift`; for the leftover direct uses only the lines found by a search for `Color.white`, `Color.black`, `.white`, `.black` in `SmackAPad/Sources/UI/` (PatternField.swift, HomeScreen.swift, PracticeComponents.swift).

## Acceptance criteria

- [ ] No pure #FFFFFF / #000000 left on screen in light or dark mode.
- [ ] Text contrast stays at least 7:1 (ink on background is about 14:1).
- [ ] Orange text/labels, result marks, pad flashes and the playhead stay clearly visible.
- [ ] Light and dark; landscape and portrait.
- [ ] Build passes; do not run tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium** thinking. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
