# 207 — Home reacts to the MIDI controller

Status: implemented; build and full suite passed; ready for iPad test. Decided by Jakub on 2026-11-13 (iPad review, photos 2 and 11: "pady MIDI nefungují"). Blocked by: 206 (uses its display status line).

## Goal

The faders on Home work, but hitting the real controller on Home does nothing, so the "real hardware" feeling breaks. Ticket 192 only lit pads on the Controller screen. On Home, a hit on the controller should be heard and seen, without ever navigating anywhere.

## Rules

1. **Sound:** a note-on from the active controller plays that pad's sound at the Pads volume, the same way it sounds in practice (same kit, same velocity handling). Controller buttons (`MIDIControl`) do not play a sound, as everywhere else.
2. **Display:** the display's status line (ticket 206) shows the last hit for about 1.5 s: drum name and note, for example "Kick · 36", then returns to the controller line. An unmapped note shows "Note 61 · not mapped".
3. **Activity light:** a small "MIDI" LED on the hardware next to the display flashes on every incoming note (brightness by velocity) and fades out.
4. **No navigation and no pad lighting on Home.** The eight Home tiles are menu buttons; they never light or open anything from a MIDI hit (lighting them would look like a selection). Write this in a code comment where the hit is handled.
5. Only while Home is the visible screen; when another screen is on top, Home does not play or show anything. No double sound when practice is open.
6. Accessibility: hits are not announced.
7. Use the existing `MIDIInput` hit stream (`lastPad`, `pressedPadIndices` or the event the practice screen uses); do not add a second CoreMIDI listener.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/HomeScreen.swift` (display from 206, visibility check near `AppNavigation.shared.route == .home`), `SmackAPad/Sources/MIDI/MIDIInput.swift`, `MIDIControl.swift`, `SmackAPad/Sources/Audio/AudioEngine.swift` (how pad sounds are played), `ControllerSetupView.swift` (how 192's live grid listens), `PracticeComponents.swift` (`PadVoice.displayName`).

## Tests

Unit test for the status line text builder: mapped note → "Kick · 36"; unmapped → "Note 61 · not mapped"; controller button → its button name.

## Acceptance criteria

- [x] On Home, hitting a real pad plays its sound and shows the drum on the display; the MIDI LED flashes.
- [x] No Home tile opens or lights from a hit.
- [x] No sound from Home while another screen is open.
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

- On Home, drum on your JP-Mini: sound, display, LED. Then open Library and hit pads: Home stays silent.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
