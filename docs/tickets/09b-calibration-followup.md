# 09b — Calibration follow-up

Status: ready

## Goal

Ticket 09 follow-up: make calibration and practice use the same audible-time model, and make sure calibration never breaks practice audio.

## Files to read

- `AGENTS.md`
- `docs/tickets/09-calibration.md`
- `docs/DECISIONS.md` (§8, §10)
- `docs/SPEC.md` (§5.2)

Context: commit 637f259 implemented guided calibration. Do not change `CalibrationAnalysis`, `CalibrationMeasurement` or the thresholds.

## Task A — same audible-time model

- Calibration measures taps against the rendered click onset plus `engine.mainMixerNode.outputPresentationLatency`.
- Practice schedules clicks and scores against `playbackDelay = session.outputLatency + session.ioBufferDuration`.
- If these can differ, the stored offset absorbs a different delay than practice assumes, and scoring is shifted by the difference.
- Step 1: add temporary DEBUG-only logging that prints both values and their difference at the start and end of a calibration run and when a practice run starts. Make it removable in one place.
- Step 2: decide, with reasoning in `docs/DECISIONS.md`, whether practice scoring should use the same presentation-latency-based audible time as calibration. If yes, implement it in one place in the audio adapter. If both values are provably equal on iOS in supported configurations, document why and change nothing.
- Never add output latency to the calibration offset or to the scoring window separately (SPEC §5.2 stays true).

## Task B — audio session safety

- `CalibrationSession` creates its own `AudioEngine` and `audio.stop()` calls `AVAudioSession.setActive(false, .notifyOthersOnDeactivation)` while the practice engine shares the session.
- After calibration ends (completed, cancelled, failed, view closed, app backgrounded) the practice engine must play sound and metronome again without restarting the app.
- Prefer one shared engine or an explicit session-ownership rule over deactivating the shared session from the calibration engine. Keep the change small.
- Add a test or an explicit manual test step; if it cannot be unit-tested, say so.

## Rules

- Use TDD where behaviour can be tested without hardware (session ownership, state transitions). State clearly what could not be tested.
- Do not claim hardware success. Stop after a successful build; Jakub tests on iPad.
- Add a short "Follow-up" section to `docs/tickets/09-calibration.md`: what changed, what is pending on iPad.
- At the end list all files created or modified.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Precise audio timing and shared AVAudioSession ownership.

## Manual iPad checks

1. Calibrate with on-screen pads, USB and BLE controller.
2. Play a lesson right after calibration (sound + metronome work).
3. Restart the app; the saved offset is kept.
4. Cancel mid-run; previous offset is kept.
5. Disconnect the controller mid-run; previous offset is kept.
