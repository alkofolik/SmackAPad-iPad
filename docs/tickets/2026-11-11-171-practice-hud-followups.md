# 171 — Practice HUD follow-ups: BPM disappears, indicators too small, lesson title, calmer idle layout

Status: ready-for-agent. Jakub decided on 2026-11-11: the band MAY move or grow between idle and running, with one smooth animation (this replaces the "band must not move" rule of ticket 165). Follows ticket 165 (tested by Jakub on the iPad on 2026-11-11; mostly passed).

## Goal

Make the new practice HUD from ticket 165 readable and reliable: the BPM readout stays visible when the tempo goes up, the three indicators are big enough to read at a glance while drumming, the lesson title looks right when the lesson is stopped, and the idle screen uses its space better now that the HUD only matters during a lesson.

## Rules

### A. BPM readout must not vanish after a tempo-up
- Symptom: after START the starting BPM is visible in the HUD row; after the first tempo increase it disappears (the tempo itself keeps working).
- Likely cause (verify first): `PracticeHUDLayout` (`PracticeScreen.swift` ~1543) hides the BPM (`bpmFits`) whenever the trailing group (tempo-up banner + `PlayingLastRunChip` + `RunMeterView`) is wider than the side space next to the cue. The banner/chip make the trailing group wide, so BPM gets width 0.
- Fix: the BPM readout has the highest priority in the row. It is never hidden while `focusActive`. When space is short, shrink or move the *other* items first: tempo-up banner and last-run chip go on a second line (or under the meter) before BPM or the meter are dropped. The row must not overlap the band.
- BPM readout follows tempo-up steps (already required in 165) and must still be visible with the banner showing, in portrait, in a narrow window and in Czech.

### B. Indicators are too small
Enlarge, keeping the 165 design (B1 pip, C2 stepped LED meter, three colours, no new words):
- **BPM readout**: number at least `Theme.display(28)` bold, monospaced digits; "BPM" in `Theme.meta` under or next to it.
- **TimingCue**: from 88×16 pt to about 180×30 pt; centre notch about 2×20 pt; pip about 14×20 pt; deadband marks scaled to match; travel scale updated (`offset * 36` becomes half-track minus half-pip). Pip colour rules unchanged.
- **RunMeterView**: blocks from 24 pt to about 40 pt tall, wider blocks, larger star badge number (`Theme.rowTitle`). Micro-steps stay 3 per block.
- HUD row height from 48 pt to what the larger items need (about 64 pt). Use `@ScaledMetric` so Dynamic Type enlarges them too.
- Check legibility from normal playing distance on the iPad; if still small, go up one more step rather than adding new elements.

### C. Lesson title shows badly when the lesson is stopped
- Symptom (Jakub): "při vypnuté lekci se špatně zobrazuje název lekce." No screenshot yet; Jakub to add one if the cause is not obvious.
- Agent: reproduce in the simulator with the lesson stopped, in landscape, portrait, a narrow split window and Czech, with 1-line and long titles, with and without header stars and the subtitle line. Candidate causes to check: title wrapping or clipping in `titleAndSubtitle` (`PracticeScreen.swift` ~255) when `topZone` stacks (`width < 850`), competition with the mode/pattern/help tools row, `BadgeBanner` overlay on top of the top zone, subtitle height reservation, or something left over from the 165 fade (opacity or frame not restored after STOP).
- Fix what is actually wrong. If the title does not fit, allow two lines before truncating; never overlap the stars or the tools.

### D. Calmer idle layout (decided: band may move smoothly)
- The space reserved above the band for the HUD row (`hudHeight` + `phaseHeight` in `middleZone`) only matters while a lesson runs. In idle (not `focusActive`) the layout may use that space differently, for example: title and stars on a larger, calmer header; tools grouped; band and pad area larger.
- Whatever idle layout is chosen, the HUD row must have its full height available during a lesson (focus mode), and Listen mode keeps its full chrome.
- The band may move or resize between idle and running: one smooth `Theme.Motion.standard` animation at START and STOP, no jump during count-in (Reduce Motion: 0.15 s fade or instant).
- Propose the layout as a short HTML preview first (as in ticket 164) and let Jakub choose before building. Do not change scoring, input or MIDI code.

### General
- Three colours only, IBM Plex Sans, `Theme.swift` tokens, motion from `docs/design/2026-11-01-motion-proposals.md`. No new UI text.
- Must work with 1–4 bars, scrolling and static view, Listen and Play, After me, From memory, section loop, Mix, portrait and landscape, narrow window, Czech.
- When a rule from 165 changes (sizes, row height, BPM priority), delete the old values and tests that enforce them; no dead code.

## Files to read

- `AGENTS.md`
- `docs/tickets/2026-11-10-165-practice-hud-and-focus.md`
- `docs/design/2026-11-10-164-practice-hud-and-focus.md`
- `SmackAPad/Sources/UI/PracticeScreen.swift` (`topZone`, `titleAndSubtitle`, `middleZone`, `practiceHUD`, `PracticeHUDLayout`)
- `SmackAPad/Sources/UI/PracticeInstruments.swift` (`TimingCue`, `RunMeterView`)
- `SmackAPad/Sources/UI/Theme.swift`

## Tests

None required for A–C (layout only). If a pure sizing or priority helper is extracted, one unit test for it. Then run the full test suite.

## Acceptance criteria

- [ ] After a tempo-up the BPM readout is still visible, together with the banner, in landscape, portrait, narrow window and Czech.
- [ ] BPM readout, timing cue and run meter are clearly larger and readable at playing distance; nothing overlaps the band.
- [ ] Lesson title and stars look correct with the lesson stopped (cause found and fixed, or reported if not reproducible).
- [ ] Part D delivered as a preview approved by Jakub first, then built; HUD row and focus mode from 165 still work.
- [ ] Build succeeds and the full test suite passes.

### Manual iPad checks for Jakub

1. Start a lesson with a tempo-up: BPM stays visible before, during and after the "Tempo up" banner.
2. Compare the sizes with the 165 build: can you read all three indicators while playing?
3. Stop the lesson: open several lessons (short and long titles, Czech) and check the title in landscape and portrait.
4. Check START/STOP transitions for any jump.

## Agent assignment

Codex GPT-6.1 Sol, high (layout stability across window sizes). Fallback: Gemini 3.8 Flash, high. Part D preview can be done separately with Gemini 3.8 Flash, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.

## Decision (Jakub, 2026-11-11)

The band may move or grow between idle and running, animated smoothly. Delete the old 165 rule and any code or test that keeps the band frame fixed.
