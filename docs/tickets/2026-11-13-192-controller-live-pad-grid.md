# 192 — Controller screen: live pad grid in the controller's own layout

Status: ready-for-agent. Decided by Jakub on 2026-11-13 (taste audit findings 57 and the "one big idea", variant 2).

## Goal

The Controller screen shows no controller, only text rows ("MIDI note", "Velocity", "Mapped pad"). Draw the player's controller as a pad grid that lights up live as they hit the real pads, in the same rows and columns as the hardware in front of them. Controllers differ (8 pads in 2×4 or 4×2, 16 pads in 4×4 or 2×8), so the profile has to know the arrangement.

## Rules

1. **Arrangement in the profile.** Add rows × columns to `ControllerProfile`. Allowed: 16 pads → 4×4 or 2×8; 8 pads → 2×4, 4×2 or 1×8. Profiles saved before this ticket decode without error and get the default: 16 → 4×4, 8 → 2×4 (4 columns, matching today's `PhysicalPadGrid.columns`). The built-in 16-pad preset is 4×4.
2. **One geometry rule.** Slot 0 is the bottom-left pad, slots go left to right, then row by row upwards (the same order the 16-pad preset already uses for notes 36–51). Put this in one place (extend `PhysicalPadGrid`) and use it everywhere a physical grid is drawn: MIDI learn, the live grid, the Touch pads section in Settings and the practice pad legend. Delete the old fixed-four-columns logic once nothing uses it.
3. **MIDI learn asks for the arrangement.** After the pad count, the learn sheet offers the allowed arrangements for that count (default as in rule 1). The highlighted pad to hit follows the geometry rule, so the grid on screen matches the hardware while learning. The arrangement is saved with the profile.
4. **Live grid on the Controller screen.** In the input monitor section, draw the active profile as a grid of pads in its arrangement, styled like the Home pads (`Theme` colours only). Each pad shows its MIDI note number. A hit lights the pad (brightness by velocity) using the existing `midi.pressedPadIndices`; it fades out on note off. A note that the profile does not map shows one plain line "Note N is not mapped", with no pad lit. The grid replaces the "Mapped pad" row; keep "Received MIDI hits" and the last note/channel/velocity rows below it.
5. **No navigation from pads.** Hitting a pad on the Controller screen never opens or changes anything; it only lights. Pads set up as controller buttons (`MIDIControl`) are shown as pads with their button name instead of a note and do not play a sound, as today.
6. **Portrait and landscape:** the grid keeps the hardware's shape and fits the section width; pads keep at least the touch size from `Theme.Size.touch`.
7. **Accessibility:** the grid is one element labelled "Controller, R rows by C columns"; the last hit is announced only by the existing text rows, not on every hit.

## Files to read

`AGENTS.md`, `ControllerSetupView.swift`, `ContentView.swift` (`MIDILearnView`), `LessonData.swift` (`ControllerProfile`), `MIDIInput.swift` (learning, `pressedPadIndices`, `lastPad`), `MIDIControl.swift`, `SettingsView.swift` (Touch pads section, `PhysicalPadGrid` use), `PracticeComponents.swift` (pad legend, `PhysicalPadGrid` use), `SettingsManager.swift` (profile saving), `Theme.swift`, `HomeScreen.swift` (pad style only).

## Tests

1. A profile saved in the old format (no rows/columns) decodes and gets the default arrangement for 8 and for 16 pads.
2. The geometry rule: slot → (row, column) for every allowed arrangement, with slot 0 at bottom-left.

## Acceptance criteria

- [ ] Controller screen shows the active controller as a grid in its own rows and columns, with note numbers.
- [ ] Hitting a real pad lights the matching pad on screen; harder hits light brighter; unmapped notes show the plain line.
- [ ] MIDI learn lets the player pick the arrangement and the highlighted pad matches the hardware order.
- [ ] Existing profiles still load and work in lessons without being learned again.
- [ ] Touch pads in Settings and the practice legend use the same arrangement.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- With your controller: every pad you hit lights the pad in the same place on screen.
- Learn a new 8-pad profile as 4×2 (if you have such a controller or can pretend with a 16-pad one): the screen shows 4 rows of 2.
- An old saved profile still plays a lesson correctly.

## Agent assignment

Codex GPT-6.1 Sol, thinking **high** (profile migration plus a shared geometry rule across four screens). Fallback: Gemini 3.8 Flash, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
