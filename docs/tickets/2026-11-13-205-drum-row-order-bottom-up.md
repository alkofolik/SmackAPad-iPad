# 205 — Drum rows in the band ordered bottom-up like the pad layout

Status: ready-for-agent. Decided by Jakub on 2026-11-13 (iPad review, photo 10).

## Goal

The orange band lists rows in an order that does not match the pad layout: for example Hi-hat sits above Open hi-hat, but on the pad layout Open hi-hat is above Hi-hat. Order the rows from the bottom up by how drummers think and how the pads lie: kick at the bottom, then snare family, hats, open hat, percussion, toms, cymbals at the top.

## Rules

1. **New order, top of the band to bottom** (pad indices from `PadVoice`):
   Crash (2), Ride (3), High tom (0), Low tom (1), Cowbell (6), Wood (5), Shaker (4), Open hi-hat (7), Hi-hat (8), Hi-hat (11), Clap (9), Rim (10), Snare (13), Snare (14), Kick (12), Kick (15).
   So from the bottom: Kick, Snare, Rim, Clap, Hi-hat, Open hi-hat, Shaker, Wood, Cowbell, Low tom, High tom, Ride, Crash.
2. Change `PadVoice.rowOrder` only. Every view that orders rows must use it: the practice band (`PatternField`), the mix line-up mini pattern (`MixLineupScreen`), and `LessonPatternStrip` (today it sorts on its own; switch it to `rowOrder`, keeping its 3-row limit by taking the 3 most used pads and then drawing them in `rowOrder`).
3. Only rows the lesson uses are shown (as now).
4. Do not change lesson data, scoring or sounds.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeComponents.swift` (`PadVoice`), `PatternField.swift`, `MixLineupScreen.swift`, `LessonPatternStrip.swift`.

## Tests

Unit test: for a lesson using kick, snare, hi-hat and open hi-hat, the row order is Open hi-hat, Hi-hat, Snare, Kick (top to bottom).

## Acceptance criteria

- [ ] In every lesson the kick row is at the bottom, open hi-hat above hi-hat, cymbals at the top.
- [ ] Mix line-up and library previews use the same order.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Open "Jazz swing 2": rows top to bottom Open hi-hat, Hi-hat, Snare, Kick. Does it feel natural while playing?

## Agent assignment

Gemini 3.8 Flash, thinking **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
