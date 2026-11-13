# 200 — Invisible chips, even mix cards, aligned day summary

Status: ready-for-agent. Decided by Jakub on 2026-11-13 (iPad review, photos 1, 5, 7).

## Goal

In dark mode some capsule chips draw cream text (`Theme.ink`) on a cream background (`Theme.white`), so they show as empty white blobs. On the Daily mix line-up these chips also add a second row to one card, so the three cards are no longer even. On the Done-for-today screen the stat tiles and the buttons do not line up.

## Rules

1. **Mix line-up drum chips are removed.** In `MixLineupScreen.swift` delete the drum-name chips (the `ForEach(padLabels.orderedPads …)` capsules next to the BPM chip). The mini pattern above already names every row. Keep the BPM chip. Delete `MixLineupLabels` fields or helpers that nothing uses any more.
2. **Mix cards are even.** All cards on the line-up have the same height, and the mini pattern, the BPM chip and the Listen / Try buttons sit at the same height in every card, whatever the title length or number of pattern rows. Do this with layout (shared heights), not fixed point values.
3. **Practice "previous mix lesson" chip is readable.** In `PracticeScreen.swift` `previousMixResultChip`: text and background must contrast in both light and dark mode. Use a dark capsule with light text, like the "MIX n / n" chip next to it. The text must read like "2 · Soul motown · 97 %".
4. **Sweep:** search the UI code for any other place that uses `Theme.ink` (or another adaptive foreground) on `Theme.white`, and fix it the same way. List the places you changed in the implementation notes.
5. **Done for today alignment.** On the day summary screen (photo 7) the bottom edge of the three stat tiles (Reviews, New lesson, Mix) lines up with the bottom edge of the Extra mix / End training buttons, in landscape. In portrait keep the current order but use the same spacing.
6. Colours from `Theme` only.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/MixLineupScreen.swift`, `PracticeScreen.swift` (`previousMixResultChip`, `mixProgressChip`), `TodaySessionScreen.swift` or the file that draws the day summary (search "Done for today"), `Theme.swift`.

## Tests

None (UI only). Full suite must pass.

## Acceptance criteria

- [ ] No empty white chip anywhere on the mix line-up or in practice during a mix.
- [ ] The three mix cards are the same height; patterns and buttons line up.
- [ ] Day summary: stat tiles and buttons share the bottom line in landscape.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Daily mix with one lesson that has 5 drum rows: cards still even.
- During mix lesson 2 and 3, the chip top left shows the previous lesson's name and score.
- Repeat both in light mode.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
