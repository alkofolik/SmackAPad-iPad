# 29 — Start/stop from the MIDI controller and tempo knob

Status: ready-for-ipad-test (2026-11-02). Source: legacy comparison 2026-11-02 (legacy manual §8.3). Jakub plays on a MIDI controller; he should not need to reach for the iPad to start, stop or change tempo.

## Goal

Let the user assign controller buttons (MIDI Note or CC) to practice actions, and a knob (CC) to tempo.

## Actions

| Action | Effect on the practice screen |
|---|---|
| Start / stop (default, one button) | Same as the big START/STOP button. |
| Restart | Same as RESTART. |
| Listen | Same as the Listen mode button. |
| Tempo − / Tempo + | −5 / +5 BPM (one named constant). |

- Actions work only on the practice screen with a lesson open. Elsewhere they are ignored.
- **Tempo rule (Jakub's decision): tempo changes only while stopped.** Tempo −/+ and the knob are ignored while a run is active (no restart, no queued change). Use the existing tempo limits in `PracticeTempo`.
- Separate actions (Restart, Listen, Tempo −/+) are under an "Advanced" disclosure; Start / stop is always visible.

## Learning a mapping

1. User taps "Learn" next to an action, then presses the controller button once.
2. The app stores `{kind: note|cc, channel 1–16, number 0–127}` for that action. Learning must not start playback or play a pad sound.
3. **CC button behaviour** (only for CC), default first: press >= 64 (rising edge) · press > 0, release = 0 · every value change.
4. **Conflicts**: one signal cannot be mapped to two actions or to an action and the knob — show a short message and keep the old mapping. If the signal is a note used by the active pad profile, warn: "This pad will no longer play a sound." and require confirmation.
5. "Clear" removes a mapping.
6. A signal mapped to an action is consumed **before** pad mapping: it never produces a pad hit, never reaches scoring.

## Tempo knob

- Learn by turning the knob slightly; stores channel and CC number.
- Knob mode: **Absolute 0–127** (with Minimum/Maximum BPM inside the tempo limits, defaults = the limits) or **Relative** in one of three formats: 1 / 127 (two's complement), 65 / 63 (binary offset), 1 / 65 (signed bit). Relative steps change tempo by 1 BPM.
- **Pickup** for Absolute (default on): the knob only takes over after its value reaches or crosses the current tempo, to avoid jumps.
- **Reverse direction** option.

## Technical notes

- `MIDIInput` currently decodes only note on/off (`noteEvents`, status 0x8/0x9). Add control change (0xB) decoding for MIDI 1.0 in UMP. Transport/knob timing is not scored; timestamps are not needed for them.
- Dispatch actions on the main actor to the current `PracticeSession`.
- Persist mappings in `SettingsManager`. They are global, not per controller profile.
- The input monitor in Settings shows CC messages too (type, channel, number, value).

## UI

Settings → MIDI and controller: new section "Controller buttons" (Start / stop + Advanced with the others) and "Tempo knob". Each row: action name, current mapping text (e.g. "CC 20 · ch 1", "Note 60 · ch 10" or "Not assigned"), Learn, Clear. Existing Settings look (ticket 25A), three colours.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/MIDI/MIDIInput.swift`, `SmackAPad/Sources/UI/PracticeSession.swift`, `PracticeScreen.swift`, `SettingsView.swift`, `SmackAPad/Sources/Scoring/PracticeTempo.swift`, `SmackAPad/Sources/Persistence/Persistence.swift`, localisation catalogs.

## Tasks

1. CC decoding; transport/knob routing before pad mapping.
2. Mapping model, persistence, learning with conflict checks.
3. Settings UI and `en`/`cs` texts.
4. Unit tests (only these): CC edge detection for the three behaviours; the three relative formats; absolute pickup; a mapped note never becomes a pad hit.

## Acceptance criteria

- [x] A learned button starts and stops practice; a mapped pad note no longer plays or scores.
- [x] Tempo −/+ and the knob change tempo only while stopped, within limits.
- [x] Conflicts are refused with a clear message.
- [x] Mappings survive app restart.
- [x] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: assign a button and a knob on his controller; play a lesson started and stopped only from the controller.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**.
- **Reasoning**: CoreMIDI parsing and routing in front of scoring; a mistake can break pad input.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task.

## Implementation and validation (2026-11-02)

- Added MIDI 1.0 UMP CC decoding alongside notes, preserving packet order. Controller learning and control routing run before pad mapping, audio, calibration callbacks and scoring. Mapped presses and releases remain consumed outside practice; only the active, ready PracticeSession executes actions.
- Added global UserDefaults mappings, Learn/Clear controls, duplicate-signal rejection, confirmation before taking a pad note, and the three CC button behaviors. Start/stop stays visible; Restart, Listen and tempo buttons are under Advanced. Listen selects the existing Listen mode while stopped, matching the on-screen button.
- Added absolute tempo mapping with limits, pickup and reverse direction, plus all three relative formats. Each relative step is one BPM; accelerated messages can contain multiple steps. Practice and knob settings share the existing 30–400 BPM limits through PracticeTempo. Tempo controls do nothing while running; pickup rearms after tempo changes, runs and suspension.
- Added English/Czech strings and CC type/channel/number/value in the Settings input monitor. Assignment learning is cancelled when Settings closes or the MIDI source/profile changes.
- Only the four requested unit tests ran: CC edges for three behaviors; three relative formats, direction and limits; absolute pickup and rearming; mapped-note routing never returning the pad path, including releases. All four passed on the first run using a macOS Swift package in `build/ticket-29/pure`, symlinked to production MIDIControl/PracticeTempo and the test file; TempoUpEvent was extracted unchanged from PracticeSession. No passed tests were rerun.
- Localization files passed `plutil -lint`; `git diff --check` passed. App build succeeded with `xcodebuild build -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ticket-29/app CODE_SIGNING_ALLOWED=NO 'OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox'`. No further tests or builds after success.
- Jakub still verifies a real controller button and knob on iPad. Concurrent ticket-30 edits were preserved and excluded from this task's commit.
