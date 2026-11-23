# 218 — Band: drum names in a dark margin, orange field starts after them; right/left hand shown on the notes

Status: implemented in c5bb207, rejected by Jakub on 2026-11-23 (text names); margin part superseded by ticket 229, hand colours stay. Jakub on 2026-11-22: the way the drums are listed in the band looks "very amateurish"; chose **variant A** of the mockup (design canvas "Smack-a-Pad – návrhy (kolo 22. 11.)", artboard C): names in the dark margin, the orange field starts after the names. Also from the checklist (2026-11-20, "Info popover and pad legend"): the notes must show which hand plays them, white = right hand, black = left hand.

## Goal

1. Each row's drum name is plain text in the dark margin to the left of the orange field, not in an orange box over the field.
2. Notes carry the hand: right hand = cream note, left hand = black note.

## Rules

1. **Names.** Full English drum names in both languages (Kick, Snare, Hi-hat, Open hi-hat, Clap, Low tom, High tom, …); no Czech translations, no abbreviation under the name. Style: condensed bold capitals, wide letter-spacing, cream colour in dark mode and soft black in light mode (adaptive `Theme` colour), right-aligned against the margin's inner edge, vertically centred on the row. Font size scales with row height as `BandLabelLayout.fontSize` does now.
2. **Margin width.** Computed from the longest name of the lesson at the chosen size (`BandLabelLayout.gutter`), clamped so portrait and many-row lessons still fit; if a name does not fit it shrinks (never wraps, never truncates with "…").
3. **Orange field.** Starts to the right of the margin. The old backdrop plates (`drawLabels` in `PatternField.swift`) are removed. Notes no longer slide under labels; they leave the field at its left edge (clip to the field). This replaces the earlier "notes slide under the pad chips" effect on purpose, as Jakub chose variant A.
4. **Pad abbreviations** (KD, SN, HH…) stay only inside the note cells, as decided before. Keep the single constant that turns the cell labels off (ticket round 7).
5. **Hand colours.** `LessonHit.hand` is "R" or "L". R notes cream (`Theme.white`), L notes soft black (`Theme.black`) with a 1 pt light outline so they stay visible on the dark row strips. The abbreviation text inside a note uses the opposite colour. This applies in the scrolling and in the static view, in Listen, Play and From memory (faded notes keep their hand colour at lower opacity).
6. **Hit marks.** Existing hit judgement colours (correct / early-late / wrong on the played hits) stay as they are and must stay distinguishable from the hand colours; check on a left-hand note that "correct" is still clearly visible.
7. **Row lights up on a pad hit.** A small orange dot next to the name lights while that pad is struck (fades in about 0.15 s). This must be a leaf view that reads the pressed pads itself; do **not** read per-hit values in `PracticeScreen.body` (ticket 209).
8. **Legend.** Add to the existing pad legend popover (the one with the abbreviations) two entries: white note = right hand, black note = left hand. Use the same note shapes as the band; no long text. Czech and English.
9. Portrait, landscape, 1 to 8 rows, 1 to 4 bars, light and dark mode, Czech and English must all look right. Rows keep one row per pad (decided earlier).
10. Do not change timing, scoring, the playhead or the beat ruler.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PatternField.swift` (`drawRows`, `drawLabels`, `PatternLanes`, note drawing), `SmackAPad/Sources/UI/PracticeInstruments.swift` and `PracticeScreen.swift` (`BandLabelLayout`, `PracticeBandStyle`), `SmackAPad/Sources/Data/LessonData.swift` (`LessonHit.hand`), `SmackAPad/Sources/UI/PracticeComponents.swift` (pad legend popover), `docs/design/` (band v2 documents), `docs/tickets/2026-11-18-209-playhead-stalls-on-every-pad-hit.md`.

## Acceptance criteria

- [ ] Names sit in the margin, plain text, no boxes; the orange field begins after them.
- [ ] Right-hand notes cream, left-hand notes black with outline, in every mode and view.
- [ ] Legend explains the two colours.
- [ ] A struck pad lights its row's dot without any hitch in the playhead.
- [ ] Looks right for 1–8 rows, portrait and landscape, light and dark, Czech and English.
- [ ] Build and tests pass.

### Manual iPad checks for Jakub

A lesson with many pads (4+) and one with two pads, portrait and landscape; hit pads and watch the dots; check one lesson where both hands play.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (drawing code, several layout cases). Fallback: Codex GPT-6.1 Sol, high. Run after tickets 212, 215 and 216 (same files), not in parallel with them.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
