# 54 — Hit timing is chaotic over Bluetooth MIDI

Status: ready-for-agent. Source: Jakub's iPad test, 2026-11-03.
Agent: Gemini 3.8 Pro, high thinking (fallback: Codex GPT-6.1 Sol, high).
Two phases: A (diagnostic build), then B (fix) after Jakub sends a log.

## Symptom

- Audio from the iPad speaker. MIDI controller on a USB cable: timing is stable and accurate.
- The same controller over Bluetooth MIDI: accuracy marks are correct for a while, then for about two bars not a single hit is matched, although Jakub plays exactly. Two pads struck at the same instant: one is judged perfect, the other totally off.
- Happens in random lessons and persists after a full app restart. Bluetooth latency itself is small (Jakub measured it).
- The app must work well with Bluetooth MIDI controllers. Telling the user to use a cable is not a fix.

## Known from the code (hypotheses, not confirmed)

- `MIDITimestamp.resolve` keeps the packet timestamp only if it is at most 250 ms older or 50 ms newer than the receipt time; otherwise it uses the receipt time. Bluetooth MIDI delivers notes in batches with varying delay, so within one run (even within one chord) some hits may keep the controller timestamp while others fall back to the delayed receipt time. `MIDIInput` already records this per event as `usedReceiptTime`.
- `ScoringEngine` adapts a timing centre: the median of the last 8 matched errors. It learns only raw errors within 110 ms; a hit more than 200 ms away counts as extra and teaches nothing. Inconsistent timestamps can push the centre off, and it may not recover.

Confirm with data before fixing.

## Phase A: diagnostic build (then stop)

1. Add temporary logging of every note-on during a practice run: device id, raw packet timestamp, receipt timestamp, resolved timestamp, `usedReceiptTime`, the matched expected step (or none), the timing error and `ScoringEngine`'s current timing centre. Also log `pass.start` and bpm for each pass.
2. Write the log to a text file in the app's Documents folder and make it visible in the iPad Files app, so Jakub can send it back. One file per run; keep the newest 5.
3. Build, commit (`diag: Bluetooth MIDI timing log`), stop. Tell Jakub in Czech, in plain words, how to find and send the file.

## Phase B: fix (only after Jakub sends a log from a bad Bluetooth run)

1. From the log, state the cause in at most 5 lines.
2. Fix it at the source of the timestamp, not by widening scoring windows. Direction: treat each device's timestamps consistently. For example, estimate a stable per-device offset between controller timestamps and receipt time, never mix the two time sources within one run, and keep notes from one packet on one timestamp basis. Make sure the adaptive timing centre cannot get stuck after a burst of late hits.
3. Unit test (the tdd skill is allowed, as this is timing code): feed a simulated Bluetooth stream (batched packets, jitter, some stale timestamps) of a perfectly played two-bar groove and assert that all hits are matched. Cable-style input must still score 100%.
4. Remove the Phase A logging, or hide it behind a debug flag that is off.
5. Build, commit, stop. Final report max 5 lines.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/MIDI/MIDITimestamp.swift`, `SmackAPad/Sources/MIDI/MIDIInput.swift`, `SmackAPad/Sources/Scoring/ScoringEngine.swift`, `SmackAPad/Sources/UI/PracticeSession.swift` (`receive(_:)` and the `Pass` class only), `SmackAPad/Sources/Audio/AudioTimingDiagnostics.swift`.

## Do not

- Do not change scoring windows, star rules or difficulty.
- Do not run this ticket at the same time as ticket 56 (both touch `PracticeSession.swift`).
- If something fails twice, stop and report.

## Acceptance criteria

- [ ] Over Bluetooth MIDI, a run played accurately is judged accurately for its whole length.
- [ ] Two pads struck together get the same judgment.
- [ ] Cable input behaves exactly as before.
