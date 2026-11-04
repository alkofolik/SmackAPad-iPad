# 69 — Practice: static multi-bar view, pad labels only once and even beat spacing

Status: ready. Source: Jakub, 2026-11-04.

## Problem

In the static (non-scrolling) pattern with 2 or 4 bars on screen, every bar is drawn as its own canvas with its own 96 pt pad-label gutter (`PatternField.swift`, `canvas`: `gutter = 96 * scale`, `cellWidth = (size.width - gutter) / 16`). So:

- the pad names repeat at the start of bar 2, 3, 4;
- the gap between the last beat of one bar and the first beat of the next is wider than between other beats, so the playhead jumps across the gutter and the flow breaks.

## Rule

- Pad labels (`drawLabels`) appear **once**, on the left of the whole row of bars. Bars 2…n have no gutter.
- All steps across all visible bars have **the same width**: one gutter on the left, then `visibleBars × 16` equal cells. The playhead moves at one constant speed across bar boundaries.
- Keep a thin bar separator line between bars (hairline, existing style) so bars are still readable; it takes no width.
- Single-bar view and the scrolling view are unchanged.
- Hit marks, played hits in memory mode, judgments and verdicts keep their positions relative to their step.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PatternField.swift` (static bars layout, `canvas`, `PatternLanes.drawLabels`), `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [ ] 2-bar and 4-bar static view: labels only on the left; equal spacing; smooth playhead over bar lines.
- [ ] Memory mode (hidden notes) still draws played hits in the right place.
- [ ] Landscape and portrait, light and dark.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: a 2-bar and a 4-bar lesson with "bars shown" 2 and 4.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
