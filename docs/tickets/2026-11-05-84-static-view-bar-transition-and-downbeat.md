# 84 — Practice: smooth bar transition in the static view; downbeat mark must not cover the "1"

Status: ready. Source: Jakub, 2026-11-05 (photo 1): "The transition between bars is wild and jumpy, not smooth. The first beat of the first bar in the static pattern is covered by the downbeat mark."

## Problem

### A — Downbeat mark covers the beat number
`PatternField.swift`, `drawBeat`: the bar-start mark is a fixed rectangle at `y: 12…20` (not scaled), while the beat number sits at `lanes.countY = 26 * scale`. With the small `fitScale` of the 2-bar and 4-bar static view the number "1" moves up into the mark, so the mark sits on the digit (visible on every "1" in photos 1–5).

### B — Bar transition looks jumpy
In the static 2-bar view (photo 1, a 2-bar lesson, run in progress) three position indicators move at the same time and do not agree with each other:
1. the playhead (`drawMarker`) inside the cells, which start after the pad-label gutter;
2. `PatternPassProgress` (black line at the bottom), which spans the **full** band width including the gutter, so at a bar line it is visibly behind/ahead of the playhead;
3. `BandTopSpineRuler` (top ruler), which shows the **run** (`runBars`, 4 bars) instead of the visible bars, with its own sector lines that do not line up with the bar lines below.
Also, on the photo the playhead is already well past the first notes of bar 2 although they were just played. Check whether the playhead or the notes lag at the bar boundary (`position` vs. `tapePosition`, wrap from the last step back to 0, and the moment `first` (page of bars) is recomputed).

## Rule

- A: The downbeat mark scales with the band and never overlaps the number: place it from `countY` (for example a small tick **under** the number, or drop the separate mark and draw the "1" of each bar bolder). Same in the single-bar, static and scrolling views.
- B: First find out what jumps (short note in the Comments of this ticket: which indicator, by how much, at which step). Then:
  - The bottom `PatternPassProgress` uses the same x mapping as the cells (starts at the gutter, bar notches exactly under the bar lines) **or** is hidden in the static multi-bar view, where the visible bars already show the position. Pick the first if it is easy.
  - The top run ruler stays (it shows run progress, ticket 59), but its sector lines must not look like bar lines: make them clearly a different element (only at the top edge, no visual line-up expectations), or align it with the cell area too. Keep it simple; describe the choice in Comments.
  - The playhead moves at one constant speed across the bar line and over the wrap from the last bar back to bar 1 (no jump back by half a step, no one-frame flash at the old position).
- Hits, judgments, memory-mode played hits keep their positions.

## Files to read

`AGENTS.md`, this ticket, ticket 69, `SmackAPad/Sources/UI/PatternField.swift` (`drawBeat`, `StaticPattern`, `PatternBar`, `PatternPassProgress`, `BandTopSpineRuler`, `drawMarker`), `SmackAPad/Sources/UI/PracticeScreen.swift` (only where `PatternField` is created, to see `position` and `tapePosition`).

## Acceptance criteria

- [ ] No beat number is covered by the downbeat mark, at any scale (1, 2, 4 bars shown; landscape and portrait).
- [ ] In the static 2-bar view the playhead and the progress line(s) agree at every bar line; no jump at the bar line or at the loop wrap.
- [ ] Single-bar and scrolling view unchanged except for the downbeat mark.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: a 2-bar lesson (e.g. Rock 1) in the static view, several loops.

## Agent assignment

- **Agent**: Gemini 3.8 Pro, **high** thinking. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
