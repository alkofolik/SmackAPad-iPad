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

- [x] No beat number is covered by the downbeat mark, at any scale (1, 2, 4 bars shown; landscape and portrait).
- [x] In the static 2-bar view the playhead and the progress line(s) agree at every bar line; no jump at the bar line or at the loop wrap.
- [x] Single-bar and scrolling view unchanged except for the downbeat mark.
- [x] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: a 2-bar lesson (e.g. Rock 1) in the static view, several loops.

## Comments

### Investigation: what jumped and why
1. **Playhead (`drawMarker`)**: was positioned at `gutter + (visiblePosition + 0.5) * cellWidth`. This caused it to cross the bar line half a step early (at step 15.5 instead of 16.0), and be already 0.5 cells past the bar line when bar 2 notes sounded (step 16.0). At the end of the loop, it reached the right edge at step 31.5, ran off-screen from 31.5 to 32.0, and on wrap jumped back from 32.5 to 0.5 (a visible jump of 0.5 steps / half a cell).
2. **Bottom progress (`PatternPassProgress`)**: had redundant `.padding(.horizontal, Theme.Space.page)` making it 48 pt too narrow, and mapped across full width rather than starting after the pad label gutter. For a 2-bar lesson, its bar notch was at width / 2 instead of `(width + gutter) / 2` (about 20 pt behind the actual bar separator line).
3. **Top spine ruler (`BandTopSpineRuler`)**: used 1 pt full-height black hairline dividers across the 4 run sectors. At 50%, this black divider sat ~20 pt away from the visible bar line (at ~52.5%), creating the false appearance of a misaligned bar line.

### Implemented solutions
- **Downbeat mark**: scaled from `lanes.countY`, placed directly under the number "1" (`lanes.countY + 12 * scale`, width `max(4, 6 * scale)`, height `max(2.5, 4 * scale)`). Line top and separator line also scale with `lanes.countY + 14 * scale`. Never touches or overlaps the number at any scale (1, 2, 4 bars; portrait and landscape).
- **Playhead**: in `StaticPattern`, removed the `+ 0.5 * cellWidth` offset. The playhead now starts at `gutter` at step 0.0, crosses the bar line at step 16.0, reaches `size.width` at step 32.0, and wraps smoothly back to `gutter` at constant speed without any half-step jump or off-screen clipping.
- **Bottom progress line**: removed the duplicate horizontal padding and passed `gutter` to `PatternPassProgress`. Notches and progress now start at `gutter` and match the cell area (`gutter + trackWidth * bar / count`), so the bar notch sits exactly under the bar line and the progress fill reaches it at step 16.0 in sync with the playhead.
- **Top spine ruler**: removed the black hairline dividers and styled the sectors as distinct segments with a 2 pt transparent gap (`HStack(spacing: 2)`) and rounded corners (`cornerRadius: 1.5`). It now clearly reads as a segmented run track at the top edge, with zero expectation of aligning with pattern bar lines below.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
