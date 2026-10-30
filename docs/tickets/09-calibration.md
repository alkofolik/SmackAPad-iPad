# 09 — Calibration

Status: ready-for-human

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
- [x] Produces a signed offset capped ±200 ms.
- [x] Stored per device through existing UserDefaults persistence; physical restart check remains with Jakub.
- [ ] **iPad test**: calibration with USB controller, BLE controller, and on-screen pads.

## Reference implementation (legacy web app)

Algorithm reference: `/Users/kju/AI COWORK/Smack-a-Pad/Smack-a-Pad/2026-10-28-Smack-a-Pad-ipad/app/v21/src/engine/calibration.js` (read-only; do not copy the code, port the idea).

Keep from the legacy version:

- 4 audible count-in clicks, then 10 measured clicks, 1 s apart.
- Each tap is compared with the click's actual output time (not its scheduled time).
- Each tap is matched to the nearest click, so a duplicate tap cannot take the next beat.
- Offset = median of the deltas; outliers are dropped by a MAD-based cut.
- Calibration is cancelled if the audio clock changes during the run; previous settings stay unchanged.
- One signed offset per device, stored in `calibrationOffsets`.

Change from the legacy version:

- Legacy acceptance was too strict: spread at most 45 ms, start-to-end drift at most 70 ms, at least 8 usable taps, at most 2 extra taps. Loosen it (starting point: spread about 80 ms, at least 6 usable taps out of 10, no hard drift limit) and tune on a real iPad. Final values are chosen during implementation (DECISIONS §8, open item 3).
- Drop the legacy per-clock-mode and per-timestamp-source keys. CoreMIDI timestamps are used directly: one device = one offset.
- The rolling timing center is not part of this ticket (see DECISIONS §9 and ticket 08).

## Skill

Use the **tdd** skill for this ticket. Calibration offset calculation must be test-driven.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Precise audio timing against hardware output. Must interact correctly with AVAudioEngine timestamps.

## Done rule

Stop after successful build; Jakub tests on iPad.

## Implementation notes (2026-10-30)

- Guided calibration is available from MIDI settings. Choose a MIDI source or on-screen pads, listen to four count-in clicks, then tap ten measured clicks.
- Accepted offsets are stored through the existing per-device `SettingsManager` API. Existing practice scoring subtracts that offset once.
- Thresholds: at least 6 usable taps; robust spread ≤80 ms; outlier cut max(60 ms, 3 × 1.4826 × MAD); nearest-click window ±350 ms; no hard drift/extra-tap limit; signed result rounded and clamped to ±200 ms.
- Audio output records come from rendered click onsets and engine presentation timing, not planned click times. Audio clock changes and cancellation keep previous offsets.
- TDD: the median/sign/cap, tolerant acceptance/outlier rejection, and actual-output nearest-click/duplicate/cancellation behaviors each failed before implementation and then passed individually on Mac. Previously passing tests were not rerun.
- Build: Xcode 27.1, Debug, generic iOS destination, signing disabled — **BUILD SUCCEEDED**. No app was installed or launched on iPad. One Swift 5 warning notes implicit `self` in a nested closure would require explicit capture in Swift 6; the project uses Swift 5 mode. App Intents metadata extraction was skipped because the app has no App Intents dependency.
- Pending Jakub's iPad validation: USB, BLE, touch, restart persistence, and the >90% normal-human success target. The initial thresholds are not a claim of measured hardware success.
