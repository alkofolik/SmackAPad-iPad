# 62 — One "Controller" place: choose, connect, map and calibrate the controller

Status: ready. Source: Jakub, 2026-11-04. Run after ticket 61 (done).

## Problem

Connecting and calibrating the controller is the most important set-up step (the app is played on an external MIDI controller), but in Settings it sits near the end: the user has to scroll past sound kit, tempo, practice mode, appearance, language… to reach "Hardware and calibration", and the controller profiles, controller buttons, tempo knob and input monitor are spread across separate sections. The home screen also has two pads (Controller, Calibration) for what is one task.

## Goal

1. A single screen **"Ovladač / Controller"** that holds everything about the MIDI controller, in the order a player needs it.
2. The home pad **Ovladač** opens this screen directly. The **Kalibrace** pad is removed; its cell stays empty until ticket 63 puts **Odznaky** there.
3. Settings links to the same screen from its **first** row.

## The Controller screen

Extract the existing sections from `SettingsView.swift` into a new view `ControllerSetupView` (move the code; do not duplicate it). Order, top to bottom:

1. **Connection**: input picker (`midi.selectedSourceID`), the hint when nothing is connected, "Connect Bluetooth MIDI", the error + "Reconnect MIDI". At the top one clear status line: the connected controller name, or "Připoj ovladač / Connect a controller".
2. **Calibration**: the "Timing calibration" link to `CalibrationView`, with the saved latency value shown on the row (or "Nezměřeno / Not measured").
3. **Controller profiles** and MIDI learn (the current "Controller profiles" section).
4. **Controller buttons** and **Tempo knob** (`ControllerMappingSections`).
5. **Input monitor**.

Keyboard, touch pads and everything else stay in Settings where they are. No behaviour, setting key or string changes inside the moved sections.

## Entry points

- **Home**: pad 5 "Ovladač / Controller" (second line unchanged: controller name or "Připoj ovladač") presents `ControllerSetupView` in a sheet with its own `NavigationStack` (so the calibration and MIDI-learn links still push) and a Done button. Remove pad 6 "Kalibrace" and its sheet; its cell stays in the grid as an empty space of the same size (no frame, not focusable), so the grid does not shift.
- **Settings**: the first row of the form (above `PurchasesSection`) is a navigation row "Ovladač a kalibrace / Controller and calibration" with the status (controller name / "Not connected") on the right, pushing `ControllerSetupView`. The old sections are no longer in Settings.

## Strings

Only new keys, cs and en: "Controller and calibration", "Not connected" (if missing), and the screen title "Controller" if missing. Remove keys that become unused only if they are clearly unused everywhere.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/SettingsView.swift`, `SmackAPad/Sources/UI/HomeScreen.swift`, `SmackAPad/Sources/UI/CalibrationView.swift` (how it is presented), `SmackAPad/Sources/UI/ContentView.swift` (`MIDILearnView`), both `Localizable.strings`.

## Acceptance criteria

- [ ] Home → Ovladač opens the Controller screen; calibration and MIDI learn work from there and Done closes it.
- [ ] Settings shows "Ovladač a kalibrace" as its first row and pushes the same screen; the moved sections are gone from Settings.
- [ ] The home grid shows an empty cell where Kalibrace was; no other pad moved.
- [ ] Cs and en; light and dark.
- [ ] Build passes; do not run tests (see AGENTS.md).
- [ ] **iPad test (Jakub)**: connect the controller, calibrate, learn a profile, both from Home and from Settings.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium** thinking: moving existing sections into one view plus two entry points. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
