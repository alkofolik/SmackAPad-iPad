# 191 — Home faders set the real sound volumes

Status: ready-for-agent. Decided by Jakub on 2026-11-13 (taste audit, finding 6, corrected).

## Goal

The faders on Home are now drawn decoration: four "CH 01–04" channels with dB scales and fixed cap positions that do nothing. Home without them was tried and felt empty, so they stay, but they must become real controls. Each fader sets one real sound volume, so the hardware on Home works like real hardware.

## Rules

1. **Three faders, one per real volume:** Metronome (`settings.metronomeVolume`), Pattern (`settings.patternVolume`), Pads (`settings.padsVolume`). Remove the fourth channel. Do not add a new master volume.
2. **Landscape:** left bay holds Metronome and Pattern (what the app plays), right bay holds Pads (what you play). **Portrait:** the three faders in one row below the plate. Keep the existing rule that faders are dropped in very short portrait windows, from the end.
3. **Real values:** the cap position shows the stored value. Dragging the cap changes the value in steps of 5 % (the same steps and clamping as `SettingsManager.clampVolume`), and the change is saved at once. Settings and the practice options show the same value afterwards, and the reverse: a change there moves the Home fader.
4. **Labels:** replace "CH 01–04" with the channel names ("Metronome", "Pattern", "Pads"), localized like the Settings rows, in sentence case. Not tiny uppercase, not monospaced. The scale shows the same unit as Settings (dB via `SoundSliderRow.formatDB(fromPercent:)`), and its marks sit at the real positions of those values, not at decorative ones.
5. **Feel:** the cap follows the finger; light haptic tick at 0 dB (100 %) and at the bottom. A double tap on a cap resets it to its default (`defaultMetronomeVolume`, `defaultPatternVolume`, `defaultPadsVolume`).
6. **Interaction split:** the faders are interactive now, so they can no longer live in the static `HomeControllerHardware` raster (it has `allowsHitTesting(false)`). Keep the plate and screws static; move the faders into their own view. Dragging a fader must not trigger a pad or scroll.
7. **Accessibility:** each fader is an adjustable element (VoiceOver swipe up/down changes by 5 %), named by its channel, with the value read out in the Settings unit.
8. **Colours from `Theme` only.** Delete the old fixed `capLevels` and the "CH %02d" label code; do not leave dead code.

## Files to read

`AGENTS.md`, `HomeScreen.swift` (`HomeControllerHardware`, `drawFaders`, `drawFader`, `HomeControllerLayout`), `SettingsView.swift` (`SoundSliderRow`, `formatDB`), `SettingsManager.swift` (volumes, defaults, `clampVolume`), `PracticeScreen.swift` (how volume changes reach the audio session), `Theme.swift`.

## Tests

Unit test for the fader value mapping: cap position ↔ volume percent (0, 100 and the 5 % steps, clamping at both ends). Nothing else; UI is checked by hand.

## Acceptance criteria

- [ ] Home shows three faders named Metronome, Pattern, Pads; no "CH" labels, no fourth channel.
- [ ] Moving a Home fader changes the value shown in Settings and in the practice options, and the reverse.
- [ ] The value survives an app restart.
- [ ] Double tap resets a fader to its default.
- [ ] Pads and the rest of Home still respond normally; dragging a fader triggers nothing else.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Landscape and portrait: the faders look like before (same hardware feel), only real.
- Move the Metronome fader on Home, start a lesson: the click is louder or quieter as set.
- Dim light: the cap position is easy to read.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
