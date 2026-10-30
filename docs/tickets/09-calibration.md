# 09 — Calibration

Status: ready-for-agent

## Goal

Implement the 10-click guided calibration procedure that measures per-device timing offset.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.5 Calibration, §5.2 Latency Compensation)
- `docs/DECISIONS.md` (§8 Calibration, §10 Audio engine)

## Critical design constraint

**Calibration measures against the actual sound time (AVAudioEngine output timestamp), so the offset contains MIDI input path + human reaction, NOT output latency.**

- The ground-truth clock is `AVAudioSession` output timestamp — the moment the metronome click actually reaches the speaker.
- The calibration offset therefore captures: MIDI input delay + human perception + any systematic bias.
- `AVAudioSession.outputLatency` is used ONLY to schedule when to start audio playback so the click arrives at the intended wall-clock moment. It is NOT part of the calibration offset calculation.
- The scoring engine applies the calibration offset once. Adding outputLatency to scoring would double-count what calibration already measured.

## Tasks

1. 10-click guided procedure: metronome at 1 s intervals, user taps along on their MIDI controller (or on-screen pads).
2. For each click: record the difference between the user's tap timestamp and the click's output timestamp.
3. Compute median of the 10 differences. Cap result to ±200 ms.
4. Store the signed offset per device (keyed by MIDI device identifier) in UserDefaults.
5. Acceptance thresholds must be significantly looser than legacy (legacy failed >50% of the time). A normal human tapping should succeed >90% of the time.

## Acceptance criteria

- [ ] 10-click procedure completes successfully >90% of the time for a normal human.
- [ ] Produces a signed offset capped ±200 ms.
- [ ] Stored per device; survives app restart.
- [ ] **iPad test**: calibration with USB controller, BLE controller, and on-screen pads.

## Skill

Use the **tdd** skill for this ticket. Calibration offset calculation must be test-driven.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Precise audio timing against hardware output. Must interact correctly with AVAudioEngine timestamps.

## Done rule

Stop after successful build; Jakub tests on iPad.
