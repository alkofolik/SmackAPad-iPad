# 90 — Static view: one bar line only (extra vertical line at the bar boundary)

Status: resolved. Source: Jakub, 2026-11-05 (iPad, photo 1, after ticket 84): "There is still an extra vertical line."

## Problem

In the static 2-bar view, at the start of bar 2 (the second "1") two vertical lines are drawn next to each other:
1. `drawBeat` draws the bar-start line at the **centre** of step 0 of bar 2 (`x = gutter + (visibleStep + 0.5) * cellWidth`, `bar = step.isMultiple(of: 16)`, thick line);
2. the separator in `StaticPattern` draws a second hairline at the **cell edge** (`sepX = gutter + barIndex * 16 * cellWidth`), half a cell to the left.
The same pair can also appear at the start of bar 1 (line plus the downbeat tick below the number). Together they look like a doubled line.

## Rule

- Exactly one vertical line per bar start, at the same x as the first beat of that bar (centre of step 0), same style as the other bar lines. Remove the extra separator (or the duplicate in `drawBeat`) — keep whichever gives one line.
- Check the same on the single-bar and scrolling views: no doubled lines there either.
- The playhead, notes and the downbeat tick keep their positions.

## Files to read

`AGENTS.md`, this ticket, tickets 69 and 84, `SmackAPad/Sources/UI/PatternField.swift` (`drawBeat`, `StaticPattern` separator block, `ScrollingPattern`).

## Acceptance criteria

- [x] 2-bar and 4-bar static view: one line at each bar start, no extra line left of the second "1".
- [x] Single-bar and scrolling view unchanged.
- [x] Light and dark; landscape and portrait.
- [x] Build passes; do not run tests.
- [x] **iPad test (Jakub)**: 2-bar and 4-bar static view has exactly one bar line per bar start.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium** thinking. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
