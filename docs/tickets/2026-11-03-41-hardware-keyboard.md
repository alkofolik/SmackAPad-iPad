# 41 — Play pads on a hardware keyboard

Status: ready (2026-11-03). Source: Jakub 2026-11-03 (widen the audience: iPad owners with a Magic Keyboard / Bluetooth keyboard but no pad controller).

## Goal

Let the user play the 16 pads with the keys of a connected hardware keyboard. Keyboard hits go through the same pipeline as MIDI and touch (`PadInputEvent`), so audio, calibration and scoring work without changes.

## Technical approach

- Use the **GameController** framework: `GCKeyboard.coalesced` / `GCKeyboardDidConnect` / `GCKeyboardDidDisconnect`, and `keyboardInput` with `keyChangedHandler` (iPadOS 14+, the app targets 17). Reason: key-down / key-up events with no auto-repeat and a low-latency path. Do **not** use SwiftUI `onKeyPress` or `UIKeyCommand` (auto-repeat, text-input side effects).
- Map by **physical key position** (`GCKeyCode`), never by the typed character. Czech QWERTZ and US QWERTY swap Y/Z; characters would break the layout.
- Take the timestamp (`mach_absolute_time()`) as the first statement of the handler.
- Add a `MIDIInput.keyboard(padIndex:isPressed:)` method modelled on `touch(padIndex:isPressed:)`, with `deviceID: "keyboard"`, the same guards (lesson open, 16 pads, not learning) and its own held-key bookkeeping (key up must release exactly the pad that key pressed; two keys never share a pad).

## Default mapping (fixed in v1, no rebinding)

The four key rows map to the four rows of the on-screen pad grid, left to right, **in the same visual order as `PadLayoutGrid`** (check the real order of `midi.padIndices` before coding):

| Grid row | Keys (physical positions) |
|---|---|
| 1 (top) | 1 2 3 4 |
| 2 | Q W E R |
| 3 | A S D F |
| 4 (bottom) | Z X C V |

The key-to-pad assignment must be shown in the pads themselves when the keyboard is active: in the pad grid cells (small key label next to the abbreviation, e.g. "SN · W"), and in Settings as a small table. If the layout grid is hidden, no labels are needed.

## Behaviour

- Active only on the practice screen with a ready session and 16 pads. In text fields, Settings, library etc. keys do nothing for pads.
- Keys held down produce one hit (no repeats); releasing sends note-off.
- Modifier keys (Cmd, Ctrl, Opt) held: ignore the key (system shortcuts must keep working).
- Does not conflict with MIDI: both can be connected at once; every event carries its own `deviceID`.
- Verify on a real iPad that key presses do not produce a system beep or move focus on the practice screen. If they do, report instead of working around it.

## Settings

Settings → MIDI and controller: new section **"Keyboard"** with a toggle "Play pads with keyboard" (default On, shown only while a hardware keyboard is connected, otherwise the text "No keyboard connected") and the mapping table. Existing Settings look (ticket 25A).

## Calibration

`CalibrationView` has an input picker (controllers and "touch"). Add "keyboard" as a calibration input when a keyboard is connected, so its latency can be measured and stored under `deviceID == "keyboard"` (existing `calibrationOffset(for:)`).

## Out of scope

Key rebinding / learn mode, Space for start/stop and other transport keys (possible later ticket), Mac-specific behaviour, on-screen keyboard.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/MIDI/MIDIInput.swift` (especially `touch(...)`, `emit`, `releaseHeldPads`), `SmackAPad/Sources/UI/PracticeComponents.swift` (`PadLayoutGrid`), `SettingsView.swift`, `CalibrationView.swift`, `Persistence.swift`, localisation catalogs.

## Tasks

1. Keyboard source in the MIDI layer (connect / disconnect, handler, held keys, timestamp).
2. Mapping by `GCKeyCode`, unit test for the mapping table and for key-up releasing the right pad (only these tests).
3. Settings section and key labels in the pad grid; `en`/`cs` texts.
4. Calibration input "keyboard".

## Acceptance criteria

- [ ] With a keyboard connected, a lesson is playable on the 16 keys; hits sound and score.
- [ ] Czech and US keyboard layouts give the same physical mapping.
- [ ] Holding a key gives one hit; two keys at once give two hits.
- [ ] Keys do nothing outside a ready practice session; Cmd/Ctrl/Opt combinations are ignored.
- [ ] Keyboard and MIDI controller can be used together. Build succeeds.
- [ ] **iPad test (Jakub)**: Magic Keyboard or Bluetooth keyboard, play an intro lesson; calibrate the keyboard.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **medium**. Small, well-delimited input source modelled on the existing touch method; high is not needed unless the first build fails.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task.
