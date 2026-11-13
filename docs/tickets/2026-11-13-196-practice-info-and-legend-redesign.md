# 196 — Practice: new look for the Lesson info and Pad legend popovers

Status: ready-for-review. Completed on 2026-11-13.

## Goal

The two popovers on the practice screen (Lesson info, Pad legend) look like a generic list: a back arrow inside a popover, divider lines, small headings, a legend whose hand symbols contradict the band, and text cut off at the bottom. Give them a calm, ordered look built from the app's own elements: big numbers, pattern blocks exactly as on the band, and blocks separated by a tone step.

## Rules (both popovers)

1. **No back button and no title row.** A popover closes by tapping outside; the toolbar button that opened it stays selected while it is open.
2. **Blocks, not lines.** Each part sits in its own rounded block one tone step lighter than the popover ground (`Theme` surface colours). Delete the dividers.
3. **Block headings** in Barlow Condensed (`Theme.display`), sentence case, small, secondary colour. Not uppercase, not tracked, not monospaced.
4. **Height fits the content.** No more estimated height (`count * 64 + 320`); size to content up to the screen height, scroll only beyond that. Nothing may be cut off (today the legend's last sentence is cut).
5. Width stays 420 pt. Colours from `Theme` only. Czech and English both checked.

## Lesson info

1. **Top row, three figures** set large in Barlow Condensed, each with a small label under it: level ("1", "Level"), bars ("1", "Bar"/"Bars"), tempo ("55 → 80", "BPM, start to goal"), with the arrow in orange.
2. **The goal** under it as the largest text in the popover (about 20 pt, Plex Sans medium), with the small label "Goal" under it. The lesson title is not repeated; it is already in the screen header.
3. **Block "How to play":** the instruction text as now.
4. **Block "Fingers":** one row per pad and hand: the pattern block (as on the band), "Kick, left hand" and "Middle finger (3)" under it, and a large "L3" / "R2" at the right edge. Drop the line "1 = thumb … 5 = little finger"; each row names the finger in words.
5. Lessons without intro data keep today's fallback texts.

## Pad legend

1. **"Pads in this lesson":** one row per pad and hand used in the lesson, with the pattern block drawn exactly as on the band, the instrument name and the hand in words under it.
2. **Block "Hands":** one filled block = left hand, one outlined block = right hand, matching the band. **Delete the old "□ left ■ right" squares**, which said the opposite of the band.
3. **Block "Band colour":** three swatches side by side in the three real band colours for Listen, Play and From memory (from `Theme`), clearly different from each other, labelled under them; under the swatches one line: "Deeper colour = closer to the goal tempo."
4. **Block "Timing glow":** a small band strip with a glow at the left edge and at the right edge, labelled "Left edge: dragging" and "Right edge: rushing". This must match what the band really does; if the code shows the opposite, stop and report instead of changing the meaning.
5. The first-time automatic opening of the legend stays as it is.

## Files to read

`AGENTS.md`, `PracticeScreen.swift` (`legend`, `lessonInfo`, `infoBlock`, `handLegend`, `bandLegend`, `infoGroup`), `PracticeComponents.swift` (`PatternBlock`), `PatternField.swift` (band colours and the timing glow), `Theme.swift`, `en.lproj/Localizable.strings`, `cs.lproj/Localizable.strings`.

## Tests

None (layout only). If a localization test lists removed keys (for example the "1 = thumb …" line), update it.

## Acceptance criteria

- [x] Neither popover has a back button, a title row or divider lines.
- [x] Lesson info shows the three figures, the goal as the largest text, How to play and Fingers with "L3"-style marks.
- [x] Pad legend shows the blocks as on the band, filled = left and outlined = right, three distinct band colours and the timing glow strip.
- [x] Nothing is cut off in either popover, in English and Czech, for a lesson with one pad and one with many pads.
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

Open "Kick on every beat" and a lesson with many pads; open Info and Legend in English and Czech: everything readable from arm's length, nothing cut off, the hand blocks look the same as on the band.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
