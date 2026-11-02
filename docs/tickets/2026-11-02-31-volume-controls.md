# 31 — Separate volume for metronome, pads and pattern sound

Status: ready. Source: legacy comparison 2026-11-02 (legacy manual §4.9, Click / Pads sliders). Today the metronome and pattern sound can only be switched on or off.

## Goal

Three volume sliders, 0–100 % in steps of 5:

| Slider | Affects | Default |
|---|---|---|
| Metronome | practice clicks and count-in | 80 % |
| Pads | sounds of the student's own hits (MIDI and touch) | 100 % |
| Pattern sound | lesson playback in Listen, and in Play when "Pattern sound in Play" is on | 70 % |

## Rules

- **Calibration clicks are never affected.** Calibration detects click onsets in a mixer tap; it must keep its current fixed level. Check `startCalibrationClicks` and the tap before changing any shared node.
- Volume must not change timing: do not add nodes between players and the main mixer that report presentation latency, or verify that `mainMixerNode.outputPresentationLatency` is unchanged. Scheduling code stays as it is.
- Pad velocity scaling (`node.volume = velocity / 127`) stays; the slider multiplies on top (e.g. via a submixer per group).
- If the student's pads and the pattern sound share the same player nodes today, separate them into two groups (e.g. two `AVAudioMixerNode`s) so they can have different volumes.
- 0 % means silent but the feature stays on (the on/off toggles remain).
- Values persist in `SettingsManager`.

## UI

- Settings → Sound: the three sliders, with value in %.
- Practice screen → "More tools" popover: the same three sliders (one touch away, Jakub's rule). Existing look, three colours.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Audio/AudioEngine.swift`, `AudioOutputTiming.swift`, `SmackAPad/Sources/UI/PracticeSession.swift`, `PracticeComponents.swift` (`PracticeTools`), `SettingsView.swift`, `SmackAPad/Sources/Persistence/Persistence.swift`, localisation catalogs, `docs/DECISIONS.md` §10.

## Acceptance criteria

- [ ] Each slider changes only its own group, immediately, also during a run.
- [ ] Calibration still works unchanged.
- [ ] Values survive app restart.
- [ ] Texts in `en` and `cs`.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: metronome at 30 %, pattern sound at 50 %, pads at 100 % during Play; then run calibration once.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), **high**.
- **Reasoning**: small audio-graph change plus UI; the calibration and timing guards above are the only risk, so read DECISIONS §10 first. If Flash is unavailable, use Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; Jakub tests on iPad. Commit after the task.
