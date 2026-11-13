# 198 — Practice HUD: short tempo-up sign in the centre, timing cue next to the band

Status: ready-for-agent. Design approved by Jakub on 2026-11-13 (mockups "A" and "B" in that conversation).

## Goal

During practice the tempo increase appears as a long orange banner ("Tempo up: 60 → 65 BPM") squeezed next to the BPM number at the top left, where it is easy to miss and takes a lot of room. The timing cue (the small rushing/dragging scale) sits high up under the star meter, far from the band it belongs to. Make the tempo-up a short, iconic sign centred above the band, and put the timing cue right above the band, aligned with the band's right edge.

## Rules

1. **HUD grid.** The practice HUD (`practiceHUD`) becomes three zones over the band's exact width: left = BPM number (as now), centre = tempo-up sign, right = star meter and accuracy (ticket 199 changes the meter's content). All three share one baseline row. The left edge of the BPM and the right edge of the accuracy capsule line up with the band's left and right edges.
2. **Tempo-up sign.** Replace the text banner with a compact orange capsule: an "up" symbol (for example `chevron.up.2` or `arrow.up`) plus the **new** BPM number only, e.g. "⌃ 65". No words, no "from → to". Centred horizontally above the band, with at least `Theme.Space.small` gap to the band (not glued to it). Shows for the same time as today, same pulse, respects Reduce Motion. VoiceOver keeps announcing "Tempo 65".
3. **Goal reached sign.** When the auto step lands on the goal tempo, the same spot shows a target symbol + goal BPM ("◎ 80") once, so the player knows the climb is over. Same timing as the tempo-up sign.
4. **Timing cue.** Move `TimingCue` out of the top-right stack into its own row directly above the band, right-aligned with the band's right edge, same small gap as rule 2. The HUD gets shorter, not taller: the old second-line layout of `ViewThatFits` is removed if it is no longer needed.
5. **Everywhere it is used.** Apply the same sign and placement in every place the tempo-up label or the timing cue appears: the practice screen (normal lessons, training mix, review runs) and the help illustrations (`HelpIllustration.swift`, `TempoUpLabel`). The help must show the new short sign, not the old text.
6. Delete the old long label text "Tempo up: %lld → %lld BPM" from both string files and the code that built it, once nothing uses it. Colours only from `Theme`; check light and dark, English and Czech.

## Files to read

`AGENTS.md`, `PracticeScreen.swift` (`middleZone`, `practiceHUD`, `hudTempo`, `runMeter`, `tempoUpBanner`), `TempoUpBanner.swift`, `PracticeInstruments.swift` (`TimingCue`, `PracticeProgressMeter`), `HelpIllustration.swift` (tempo example and timing example), `PracticeTempo.swift` (`TempoUpEvent`), `Theme.swift`, `en.lproj/Localizable.strings`, `cs.lproj/Localizable.strings`.

## Tests

None new (layout only). If a localization or help test lists the removed "Tempo up" key, update it. If `TempoUpEvent` needs a "reached goal" flag for rule 3, add one unit test for it in `PracticeTempoTests`.

## Acceptance criteria

- [ ] A tempo increase shows a short orange "up + new BPM" sign centred above the band, with a visible gap to the band.
- [ ] Reaching the goal tempo shows the target sign once.
- [ ] The timing cue sits directly above the band, right edge aligned with the band.
- [ ] The help illustrations show the same new sign.
- [ ] The old long text is gone from code and strings.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

Play a lesson with auto tempo step on (start below goal): watch the sign appear in the centre at each step and the target sign at the goal. Check the timing cue sits right above the band. Repeat in Czech and in light appearance; open Help and check the tempo picture.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
