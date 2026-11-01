# Practice screen: feedback round after iPad test (2026-11-01)

Status: implemented; iPad check pending. Builds, and all 51 tests pass on the iPad Air 11-inch (M4) simulator.

## Decisions

- **Reverses an earlier decision.** The 2026-10-30 spec said no live per-hit feedback. Jakub changed his mind: played pads are now marked by colour only, no shapes or text.
- **Pattern colours** (orange band, decentní): green = correct (perfect or good), dark yellow-brown = played off the beat, dark red = note not struck within its window. Hand stays visible as the frame colour of the note (white = right, black = left).
- **Pad layout** is shown by default (setting stays in More tools; no hide button on the main screen). Each strike flashes its pad for 0.4 s in the same colours (red = wrong pad); neutral orange in Listen mode or when nothing is scored.
- **Tempo field** has the standard bordered control style, so it reads as tappable.
- **Pass counter removed** (informational only; scoring and stars never used it).
- **Count-in** is one large black numeral over the dimmed pattern (as in the legacy app), not a status-bar text.
- **Vertical beat lines** sit exactly on the beat (centre of the step), the same x as the playhead and the notes.

## To check on the iPad

1. Play a lesson: right hits turn green, late or early ones turn brown, skipped ones turn red shortly after their time.
2. Pad layout flashes with each strike; try a wrong pad (red).
3. Count-in numbers are large and readable; the pattern behind is dimmed.
4. Beat lines meet the playhead exactly when a note is played.
5. If the layout was switched off earlier, switch it on in More tools (a stored choice wins over the new default).
