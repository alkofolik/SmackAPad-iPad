# 229 — Band margin: drum icons and light dots instead of text names

Status: done (2026-11-25). Previous: implemented, awaiting Jakub's iPad check. Jakub on 2026-11-23: the text names in the band margin from ticket 218 (variant A) did not look right; chose **variant 4**: a narrow margin with a drum icon and a colour dot per row. The hand colours from 218 (right = cream note, left = black note with outline) stay as they are.

## Goal

Replace the text names in the band margin (`BandMarginView` in `PatternField.swift`, `BandLabelLayout` in `PracticeInstruments.swift`) with a small drum icon and a dot per row, so the margin is narrow and the notes get more room.

## Rules

1. **Icon.** One simple drum glyph per pad (kick, snare, hi-hat, open hi-hat, clap, toms, crash/ride, other as a generic drum). Drawn as SwiftUI shapes or SF Symbols, whichever reads better at row height; no image files unless needed. Cream in dark mode, soft black in light mode (adaptive `Theme` colour), centred on the row.
2. **Dot.** A small dot next to the icon, in the pad's colour. It lights (about 0.15 s fade in) while that pad is struck. It must be a leaf view that reads the pressed pads itself; do **not** read per-hit values in `PracticeScreen.body` (ticket 209).
3. **Full name on demand.** Tapping an icon shows the full English drum name in a small bubble for about 2 s. Same name in Czech and English, as in ticket 218 rule 1. No text in the margin otherwise.
4. **Margin width.** Fixed narrow width that depends only on the row height (icon size), not on the longest name. Remove the name-width fitting code from `BandLabelLayout` that is no longer needed. Delete tests that enforce the old text-fitting rule.
5. **Unchanged from 218.** Orange field starts after the margin; notes are clipped at its left edge; hand colours; abbreviations only inside note cells (keep the single constant that switches them off); hit-mark colours.
6. **Legend.** The pad legend popover shows the icons with their names (one line each), plus the two hand entries from 218. Czech and English.
7. Portrait, landscape, 1 to 8 rows, 1 to 4 bars, light and dark mode must look right. If rows are too small for an icon, the icon shrinks, never overlaps.
8. Do not change timing, scoring, the playhead or the beat ruler.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PatternField.swift` (`BandMarginView`, `PatternLanes`), `SmackAPad/Sources/UI/PracticeInstruments.swift` (`BandLabelLayout`), `SmackAPad/Sources/UI/PracticeComponents.swift` (pad legend popover), `docs/tickets/2026-11-18-209-playhead-stalls-on-every-pad-hit.md`.

## Tests

Update only the existing band layout tests (`PatternBandLayoutTests`) that checked the text margin width. No new tests.

## Acceptance criteria

- [x] Margin shows an icon and a dot per row, no text.
- [x] Tapping an icon shows the full drum name briefly.
- [x] A struck pad lights its dot without any hitch in the playhead.
- [x] Legend lists icons and the two hand colours.
- [x] Looks right for 1–8 rows, portrait and landscape, light and dark, Czech and English.
- [x] Build and tests pass.

### Manual iPad checks for Jakub

A lesson with 4+ pads and one with two pads, portrait and landscape; hit pads and watch the dots; tap icons; check the legend.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (drawing code). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run tests per `AGENTS.md`, commit, stop for Jakub's iPad check.
