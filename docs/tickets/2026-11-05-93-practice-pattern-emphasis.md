# 93 — Practice screen: the orange pattern band is the one focus; pad map readable

Status: ready. Source: Jakub, 2026-11-05 (iPad photos): the Practice screen feels empty between the pattern band and the bottom controls. Decision: do not fill the space with content; make the orange band the dominant element and keep everything else quiet.

## Rule

- The pattern band (orange field, static and moving view) gets **more height**: taller lanes, larger pad labels and beat numbers, scaled to the free vertical space. Keep the existing proportions and the bar/beat grid logic.
- The band sits **vertically centred in the free area** between the top toolbar and the bottom controls (equal space above and below), not stuck to the top.
- The bottom controls (pad map, BPM box, Start/Restart) stay visually **quiet**: no new colour, no new elements. Their left and right edges align exactly with the left and right edges of the band.
- The pad map (bottom left): raise the contrast of its cell outlines and labels so it is readable at a glance (target: label text at least 4.5:1 on the cell; outlines clearly visible on the cream background). No size change unless needed for the 44 pt touch minimum.
- Do not add decoration, backgrounds, patterns or new labels.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeScreen.swift` (layout only), `SmackAPad/Sources/UI/PatternField.swift` (lane height and font scaling only), `SmackAPad/Sources/UI/PracticeInstruments.swift` (pad map), `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [ ] Band visibly larger; spacing above and below it equal on iPad portrait and landscape.
- [ ] Band, pad map and Start/Restart share the same left/right margins.
- [ ] Pad map readable in light and dark.
- [ ] 1, 2, 3 and all bars shown still fit; running playhead and result marks unchanged.
- [ ] Build passes; do not run tests.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high** (touches the pattern drawing). Fallback: Gemini 3.8 Flash, high.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
