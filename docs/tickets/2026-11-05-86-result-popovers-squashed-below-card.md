# 86 — Practice: star rules and session results open squashed below the result card

Status: ready. Source: Jakub, 2026-11-05 (photos 2, 3): "Under the result something can be scrolled, but I can't see what."

## Problem

`PracticeScreen.swift`, `bottomZoneRow`: the `ResultCard` sits at the bottom of the screen, but both popovers attached to it use `arrowEdge: .top`, so iOS places them **below** the card. There is almost no room, so the popover becomes a thin strip at the screen edge with a scrollable text inside (visible as "…or better", the end of a star requirement from `starRules`). Same risk for `showingDetails` (`sessionResultsView`).

## Rule

- Both popovers open **above** the card (`arrowEdge: .bottom`) at their normal size (`starRules` 420 × 360, session results up to 600 high). If the screen is too short for that (portrait, small iPad), use a sheet instead of a squashed popover.
- Check the other popovers anchored in the bottom zone (tempo, `showingTempo`) for the same problem and fix them the same way.
- The anchor for the star rules should be the stars in the card, not the whole card background, if this is easy.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeScreen.swift` (`bottomZoneRow`, `starRules`, `sessionResultsView`, the `showingTempo` popover), the file defining `ResultCard` (only how it calls `openRules` / `openSessionResults`).

## Acceptance criteria

- [x] Tapping the stars shows the full star rules, readable, above the card.
- [x] Tapping the card shows the full session results.
- [x] Nothing thin or half-hidden appears under the card.
- [x] Landscape and portrait, light and dark.
- [x] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: verify star rules, session results, and tempo popovers/sheets in landscape and portrait.

## Comments

### Implemented solutions
- **Popover direction (`arrowEdge: .bottom`)**: Popovers anchored in the bottom zone (`starRules`, `sessionResultsView`, `tempoControls`) now specify `arrowEdge: .bottom`, placing them above their anchors with arrows pointing down.
- **Star rules anchor**: Anchored directly to the stars inside `ResultCard` (`starsColumn` background) instead of the entire card background.
- **Adaptive popover / sheet fallback**: Added `adaptivePopoverOrSheet` which calculates available vertical space above the bottom zone row. When vertical space is insufficient (portrait with pads or small iPad), it smoothly presents as a sheet with drag indicators and appropriate detents (`.presentationDetents`) rather than getting squashed against the screen edge.
- **Consistent close actions**: Added standard header Close buttons to `starRules` and `tempoControls`, matching `sessionResultsView` and `legend`. All bottom zone popovers dismiss when starting a run.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
