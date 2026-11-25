# 231 — Practice screen: anchored non-jumping layout and high-contrast tactile hit feedback

Status: ready-for-agent

## Goal

Anchor `PracticeScreen` so the orange pattern band never shifts position between idle and playing states, and replace the muddy green/brown/burgundy hit fills in `PatternField` with immediate leaf-isolated MIDI hit impulses and high-contrast shape-coded marks (`correct`, `early`, `late`, `wrong`).

## Rules

1. **Anchored top and bottom bars (`PracticeScreen.swift`).**
   - Keep the top zone at a constant height in both idle and `focusActive` states: Back button and lesson title/subtitle stay on the leading side; on the trailing side, smoothly cross-fade (`Theme.Motion.fast`) the idle mode/pattern/info/settings controls with `PracticeProgressMeter` (plus `MemoryPeekButton` when `session.supportsMemoryPeek` is true, and `TempoUpBanner` overlay) when `focusActive || session.listen` is active.
   - Remove the duplicate top-left `hudTempo` readout. Keep `TempoTile` permanently visible in the bottom zone (non-editable while `session.running`) alongside `TimingCue` (visible when `focusActive`, occupying fixed width without shifting neighbours), `PracticePadLayoutSquare` on the left, and `TransportControls` on the right.
   - Result: pressing Start or Stop causes **zero vertical jump** of `PatternField`.
2. **Signed off-beat direction without touching `ScoringEngine`.**
   - Do not modify `ScoringEngine.swift`.
   - Expand `HitMark` (`PracticeComponents.swift`) from `.correct, .off, .wrong` to `.correct, .early, .late, .wrong`.
   - In `PracticeSession.swift`, map `.off` judgments using `HitFeedback.timingErrorMilliseconds` (`< 0` → `.early`, `>= 0` → `.late`) into a per-pass hit-mark map and into `PlayedHit.mark` so both static and scrolling bands know whether an off-beat hit was early or late.
3. **High-contrast shape-coded note marks (`PatternField.swift`, `PracticeInstruments.swift`, `Theme.swift`).**
   - Delete `Theme.markCorrect`, `Theme.markOff`, `Theme.markWrong` and `PracticeBandStyle.hitColor(_:)`, plus any dead tests referencing them (keep semantic error tint in Settings/Calibration using `Theme.destructive`).
   - In `drawHit` (`PatternField.swift`):
     - **Unjudged note:** unchanged (`Theme.white` fill + black text for right hand; `Theme.black` fill + 1 pt white stroke + white text for left hand).
     - **`.correct`:** keep full hand fill (`white` / `black`) for crisp legibility, draw a 2 pt inner confirmation frame (`Theme.orange` inset by `2.5 pt`), and apply a brief `1.08×` scale pop over `120 ms` right after the hit (`!reduceMotion`).
     - **`.early` / `.late`:** keep the hand fill, draw a bold directional chevron/bar inside the leading edge (`‹` at `rect.minX`) for `.early` or trailing edge (`›` at `rect.maxX`) for `.late` in contrasting ink (`Theme.black` on right-hand white, `Theme.orange` on left-hand black), so timing direction is readable from arm's length.
     - **`.wrong` (missed or wrong):** hollow tile (no solid white/black fill; `Theme.black.opacity(0.14)` wash + `1.5 pt` `Theme.black.opacity(0.55)` stroke) with a crisp diagonal slash across the cell so missed notes visually drop out at a glance.
   - Update `HelpIllustration.swift` (`signals` / `hitColours` cards) and `Localizable.strings` (`cs` and `en`) so the help legend accurately illustrates and describes the new marks.
4. **Immediate MIDI strike impulse (`PatternField.swift`, Ticket 209 rule).**
   - Never read `session.padFlashes` in `PracticeScreen.body`.
   - In `BandMarginView`, extract a leaf row indicator wrapping `DrumGlyph` + `BandRowDot` driven by `BandRowDotSchedule`: on strike (`age < 0.14 s`), pulse `DrumGlyph` scale (`1.0 → 1.18 → 1.0`, disabled under Reduce Motion) and brighten the dot (`8 pt`).
   - Inside the playhead `Canvas` of `StaticPattern` and `ScrollingPattern`, draw a subtle `140 ms` horizontal highlight flash (`Theme.white.opacity(0.24 * strike)`) at the intersection of the struck row and the playhead.

## Files to read

`AGENTS.md`, `docs/tickets/2026-11-18-209-playhead-stalls-on-every-pad-hit.md`, `SmackAPad/Sources/UI/Practice/PracticeScreen.swift` (lines 135–360, 675–1040), `SmackAPad/Sources/UI/Practice/PatternField.swift`, `SmackAPad/Sources/UI/Practice/PracticeComponents.swift` (lines 1–60), `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift` (lines 1–115, 270–365, 470–565), `SmackAPad/Sources/UI/Practice/PracticeSession.swift` (hit recording around `hitJudgments` / `playedHits` / `padFlashes`), `SmackAPad/Sources/UI/Shared/HelpIllustration.swift`.

## Tests

Update `PlayedHitTests` and `PatternBandLayoutTests` for `.early` / `.late` `HitMark` cases and anchored band geometry; add unit test verifying negative `timingErrorMilliseconds` maps to `.early` and positive maps to `.late`. Run `-only-testing:SmackAPadTests/PlayedHitTests`, `-only-testing:SmackAPadTests/PatternBandLayoutTests`, and `-only-testing:SmackAPadTests/PracticeSessionTests`.

## Acceptance criteria

- [ ] Pressing Start and Stop on `PracticeScreen` does not shift the vertical position or height of `PatternField`.
- [ ] `TempoTile` remains in the bottom bar during playback; top bar swaps trailing tools with `PracticeProgressMeter` in place.
- [ ] Striking a MIDI pad triggers an immediate `DrumGlyph` pulse and playhead-row flash with zero playhead hitching.
- [ ] Notes render crisp shape-coded `.correct`, `.early`, `.late`, and hollow `.wrong` states; `markCorrect`/`markOff`/`markWrong` are removed from `Theme.swift` and Help matches the new marks.
- [ ] Works in static and scrolling modes, 1–8 rows, portrait and landscape, light and dark, Reduce Motion on/off.

### Manual iPad checks for Jakub

Place iPad at arm's length next to the MIDI controller: start/stop a lesson (verify band stays rock-steady), play on-time, intentionally early, intentionally late, and miss a note; check Help → Signals / Tutorial card 2.

## Agent assignment

Gemini 4 Carbon, thinking **high** (combines 2100-line `PracticeScreen` layout anchoring, `Canvas` hit-mark geometry, and Ticket 209 leaf-isolated MIDI impulses). Fallback: Claude Opus 5.5, high. Run after 230 and before 233.

## Done rule

Build, run area tests and full suite if shared models changed per `AGENTS.md`, commit on `release-polish`, stop for Jakub's iPad check.
