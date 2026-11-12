# 186 — The top pattern row must stay inside the orange band

Status: done (tested on iPad by Jakub and pushed 2026-11-12). Approved by Jakub on 2026-11-12 (iPad check step 11, scenario reviewDueToday).

## Problem

In a lesson with 4 or more pads (seen with Hi-hat 9, Hi-hat 12, Open hi-hat, Snare, Kick = 5 rows) the top row is drawn over the beat-number ruler and the thin progress strip at the top of the band. It sticks out of the frame, and the beat numbers 2, 3 and 4 are half covered. The rows are laid out in `PatternField.swift` (see `rowHeight` around line 127 and the lanes around line 789); the row height seems to be computed without the height of the ruler/header.

## Goal

Every row of every lesson is fully inside the orange band, below the ruler and the progress strip, and nothing overlaps the beat numbers. The band does not grow beyond the space the practice screen gives it.

## Rules

- Compute the row height from the space that is really left after the ruler and the strip. With many rows the rows get smaller (down to a readable minimum), they never leave the band.
- Full English drum names on the left must stay readable (ticket 178 rule); if the minimum height is reached, shrink the font slightly or truncate in the middle, never overlap.
- Test 1 to 8 pads, static and scrolling view, with and without From memory, portrait and landscape, iPad window sizes (full screen and narrow).
- Do not change the look of the band for lessons with 1 to 3 pads.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PatternField.swift`, `PracticeScreen.swift`, `docs/tickets/2026-11-02-*band*`, `2026-11-11-178-*`, `2026-11-11-179-*`.

## Tests

Add a layout test (or a snapshot-free geometry test) that for 1 to 8 rows the computed row frames lie inside the band content rect and do not intersect the ruler rect. Run the full suite.

## Acceptance criteria

- [ ] Lesson with 5 pads (Hi-hat 9 / Hi-hat 12 / Open hi-hat / Snare / Kick): top row inside the band, beat numbers fully visible.
- [ ] No regression for 1 to 3 pads; portrait and narrow window fine.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

Open the lesson with the five rows (seen in the check) before START and during a run, in landscape and portrait. Nothing leaves the orange frame.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (it touches the band layout). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
