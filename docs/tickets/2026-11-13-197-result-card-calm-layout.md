# 197 — Result card: calm layout without overlapping chips

Status: ready-for-agent. Design approved by Jakub on 2026-11-13 (mockup "C" in that conversation).

## Goal

The end-of-run card (`ResultCard`) shows a status title plus a row of capsule chips ("Comes back tomorrow for a review", "7 runs · best 100%", "Earned 2 new badges") and a separate chart button. The chips wrap unevenly, the first chip runs under the chart button, and the card reads as a pile of text. Replace the chips with a short, ordered list of icon lines, and turn the run summary itself into the button that opens the session results.

## Rules

1. **Three columns, fixed order:** score (big %, under it "accuracy · 80 BPM"), the three stars (tap opens star rules, as now), then the facts column. On narrow widths (`isCompactWidth`) the facts column moves under score and stars, full width.
2. **Facts column = status title + at most three lines.** No capsules. Each line is one SF Symbol + short text, one line, never truncated with an ellipsis (shrink with `minimumScaleFactor` down to 0.8, otherwise the column gets more width).
   - Status title as now ("Passed", "Review passed", "Not counted" …), with its icon.
   - Review line, calendar icon, short text: EN "Review tomorrow", CS "Opakování zítra". The gap texts after a passed review ("next in 3 days") use the same line style.
   - Runs line, chart icon: "7 runs · best 100 %" with a chevron at the right end. **This whole line is the button** that opens session results (replaces `ResultDetailButton`). It has a thin outline so it reads as tappable; minimum height 44 pt.
   - Badge line, award/rosette icon, orange text, no orange fill: EN "2 new badges", CS "2 nové odznaky" (correct Czech plural forms for 1 / 2–4 / 5+).
3. **Delete** the separate `ResultDetailButton` / `BarChartGlyph` from the card and the chip capsule styling. Remove localized strings that are no longer used ("Comes back tomorrow for a review", "Earned %lld new badges") and add the new short ones in both languages.
4. Lines that do not apply are left out (no empty space). Order is always: status, review, runs, badges.
5. Colours only from `Theme`; check both light and dark appearance and both languages. Nothing in the card may overlap at any width the practice screen uses.

## Files to read

`AGENTS.md`, `PracticeInstruments.swift` (`EndOfRunChip`, `EndOfRunCardModel`, `ResultCard`, `ResultDetailButton`, `BarChartGlyph`), `PracticeScreen.swift` (where `ResultCard(` is built, around line 896), `Theme.swift`, `en.lproj/Localizable.strings`, `cs.lproj/Localizable.strings`, existing tests that build `EndOfRunCardModel`.

## Tests

Update the existing `EndOfRunCardModel` tests to the new line model (status + review / runs / badge lines, in that order, absent lines left out). Add one test for the Czech badge plural (1, 2, 5). No layout tests.

## Acceptance criteria

- [ ] The card shows score, stars and a facts column with at most three icon lines under the status; no capsules.
- [ ] The runs line opens session results; there is no separate chart button.
- [ ] Nothing overlaps or is cut off, in English and Czech, light and dark, wide and compact width.
- [ ] Unused strings and the old chip/button code are deleted.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

Finish "Kick on every beat" so that a review and new badges appear; check the card in English and Czech, light and dark. Tap the runs line: session results open.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
