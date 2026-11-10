# 164 — Practice screen: timing cue, run progress and focus mode (design phase)

Status: designed, awaiting Jakub's choice. Approved by Jakub on 2026-11-10. Design only: no Swift changes until Jakub picks a variant. Implementation follows as T165.

## Problems Jakub reported

1. The thin per-hit timing line (`HitTimingBar` above the band, `PracticeScreen.swift` ~515) is useless to him. He never looks at it.
2. The rushing/dragging read-out is useful and its position is fine. Its look is not: he wants it modern and calm, a discreet animation.
3. The run-progress display top right above the orange band (`LapVaultView`, `PracticeInstruments.swift` 486, used at `PracticeScreen.swift` ~538) is in the right place. But during a lesson he still does not know how he stands: what is done, what the requirement is, how much is left to the next star.
4. The screen is filling up again. Most controls are not needed while drumming.

## Design brief

A. **Remove** `HitTimingBar` from the practice screen. Keep `HitTimingPlot` in the result/detail view only if it still has a purpose there; say which.

B. **Timing cue (rushing / dragging).** Same position. One small calm element, for example a dot or short bar that glides left (ahead) or right (behind) from a centre mark with a soft spring and settles to centre when he is on time. No numbers, no per-hit flicker: smooth over several hits, like the current tendency. Must stay consistent with `BandEdgeGlow` (the band edge already glows for the same tendency); decide whether both stay or one carries it.

C. **Run progress.** Same position. Show at a glance:
   - which star he is working on,
   - how many qualifying runs (or hits, for the minimum ~16-hit rule) are required and how many are done,
   - how far the current run is (fills live),
   - in Learning mode that credit is kept; in Challenge mode that a failed run resets the streak (shown without text, e.g. segments emptying).
   Segments that fill are the suggested direction; propose 2–3 variants. Use only `progress`/`StarStreak` data already in `PracticeSession`; do not change any rule.

D. **Focus mode.** After START (once the count-in begins) fade out everything not needed for drumming: top bar, toolbar icons (`PracticeTools`), lesson info, volumes, back-to-library, any tempo controls beyond a small current-BPM readout. Keep: the orange band with the pattern, pad layout grid (it lights hits; still hideable in Settings), timing cue, run progress, STOP/RESTART, star and tempo-up announcements, count-in. On STOP or run end everything returns with a soft transition. Reduce Motion: instant swap. Nothing interactive may be hidden while it is still needed for the run (MIDI transport keeps working). The layout must not jump: the band keeps its size and place, or grows smoothly into the freed space; propose which.

## Constraints

- Three colours only (orange, black, white; light and dark variants), IBM Plex Sans, existing `Theme.swift` tokens and motion style from `docs/design/2026-11-01-motion-proposals.md`.
- No new UI text. No live per-hit feedback that flashes.
- Works with 1–4+ bars, scrolling and static view, Listen and Play, From memory, Mix (T168), portrait and landscape, narrow window, Czech strings.

## Deliverable

`docs/design/2026-11-10-164-practice-hud-and-focus.md` with 2–3 variants for B and C, one focus-mode proposal (what hides, what stays, transition timing), and still previews (SwiftUI preview screenshots or rendered PNGs in `docs/design/previews/164/`) in light and dark. Then stop for Jakub's choice.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md`, `PracticeScreen.swift`, `PracticeInstruments.swift`, `PracticeComponents.swift`, `PatternField.swift`, `PracticeSession.swift`, `StarStreak.swift`, `StarRequirement.swift`, `Theme.swift`.

## Agent assignment

Codex GPT-6.1 Sol, high. Visual judgement plus reading the scoring state correctly.

## Log

- Prepared design document `docs/design/2026-11-10-164-practice-hud-and-focus.md`.
- Rendered 7 retina preview PNGs in light and dark mode in `docs/design/previews/164/` using bundled IBM Plex Sans typography and exact Theme tokens:
  - `01-timing-cue-variants-light.png` / `02-timing-cue-variants-dark.png` (Variants B1, B2, B3)
  - `03-run-progress-variants-light.png` / `04-run-progress-variants-dark.png` (Variants C1, C2, C3 and mode dynamics)
  - `05-focus-mode-light.png` / `06-focus-mode-dark.png` (Full screen Focus mode reference)
  - `07-focus-mode-before-after.png` (Side-by-side transition comparison)
- Ran full test suite (238 tests passing).
- Zero Swift application code modified. Ready for Jakub's choice.
