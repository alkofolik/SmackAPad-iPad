# 06 — MIDI Input + Controller Profiles + BLE Fallback

Status: ready-for-agent

## Goal

Implement CoreMIDI input, controller profile management (including MIDI learn), and BLE timestamp fallback.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.1 MIDI Input, §4.4 Controller Profile, §6 8-Pad Controller Rule)
- `docs/DECISIONS.md` (§2 Pad layouts, §4 CoreMIDI)

## Tasks

1. **CoreMIDI integration**: receive note-on/off events from connected USB/BLE controllers. Use mach timestamps directly.
2. **BLE fallback**: if MIDI timestamp is >250 ms stale or >50 ms in the future relative to receipt time, fall back to message receipt time.
3. **Controller profiles**:
   - Model: `{ profileName, noteMap: [midiNote: padIndex], padCount: 8|16 }`.
   - Ship 2–3 preset profiles (Akai MPD, NI Maschine, TBD).
   - MIDI learn: user presses each pad, app builds a custom profile.
   - Store profiles in UserDefaults via SettingsManager.
4. **On-screen pads**: touch input as bonus alternative to MIDI (simple touch targets, same padIndex output).

## Acceptance criteria

- [ ] CoreMIDI receives note-on/off from a connected USB controller.
- [ ] BLE fallback triggers when timestamp is >250 ms stale or >50 ms future.
- [ ] Controller profile correctly maps note numbers to padIndex.
- [ ] MIDI learn builds a working profile from user input.
- [ ] **iPad test**: USB and BLE controllers both register hits.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Real-time MIDI handling with precise timestamp logic requires careful implementation. Hardware-facing code.

## Done rule

Stop after successful build; Jakub tests on iPad.
