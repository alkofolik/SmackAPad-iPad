# 73 — Home: Controller pad shows the selected input device (bug, follows 70)

Status: ready. Source: Jakub, 2026-11-04 (photos 1–2): in the controller setup the Input is "JP-Mini Bluetooth", but the home Controller pad says "Standard 16-Pad · Automatic". He expects to see the controller he set.

## Cause

Ticket 70 shows profile + sound kit (`settings.selectedKitId`, "Automatic" when the kit is auto-chosen). The sound kit is not chosen in the controller setup at all, so "Automatic" looks wrong, and the actual input device is missing.

## Rule

- Subtitle line 1: the name of the selected MIDI input (`midi.selectedSourceID` resolved to its source name, the same text the setup's Input picker shows, e.g. "JP-Mini Bluetooth").
- Subtitle line 2: the controller profile name ("Standard 16-Pad"), quieter.
- Drop the sound kit from the pad entirely.
- No input selected or the selected source is not connected: line 1 = "Not connected" / "Nepřipojeno"; line 2 still the profile.
- Each line one line only; truncate the device name at the tail if it does not fit. Remove the `boundingRect` measuring code from `pad5`.
- Updates immediately when the setup sheet closes or a device connects/disconnects (observed state).
- VoiceOver: "Controller, JP-Mini Bluetooth, Standard 16-Pad".

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/HomeScreen.swift` (`pad5`), `SmackAPad/Sources/UI/ControllerSetupView.swift` (Input picker around line 75), the MIDI manager file that defines `selectedSourceID` and `sources`, both `Localizable.strings`.

## Acceptance criteria

- [ ] Selected JP-Mini shows "JP-Mini Bluetooth" + profile on the home pad.
- [ ] Switching input or profile in the setup is visible right after closing it.
- [ ] Unplugged: "Not connected" + profile.
- [ ] Cs and en; light and dark.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
