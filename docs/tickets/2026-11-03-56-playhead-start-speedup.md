# 56 — Playhead briefly speeds up at the start of a run

Status: ready-for-agent. Source: Jakub's iPad test, 2026-11-03.
Agent: Gemini 3.8 Pro, medium thinking.

## Symptom

MIDI over cable, static pattern view, constant tempo. At the start of a run the playhead usually speeds up slightly for a moment, then runs stable and accurate for the rest of the run. Scoring over cable is fine, so this is most likely a drawing problem.

## What to check

- `patternFrame(at:)` samples the tape at `now` plus the frame's offset, clamped to ±50 ms. Right after the count-in, while the app is busy (audio start, first pass queued, SwiftUI updates), frames may be delayed and then catch up.
- The switch from count-in to pass 1 (`displayStart`) and the first `tick()`.

Find the cause, then make the playhead move uniformly from the first beat.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeSession.swift` (`start()`, `tick()`, `tapeFrame`, `patternFrame(at:)`, count-in handling), and the `TimelineView` in `SmackAPad/Sources/UI/PracticeScreen.swift` (around line 120).

## Do not

- Do not change audio scheduling or scoring times.
- Do not run this ticket at the same time as ticket 54 (both touch `PracticeSession.swift`).
- No new tests.
- If something fails twice, stop and report.

## Acceptance criteria

- [x] The playhead moves uniformly from the first beat of the run.
- [x] Scoring and audio timing are unchanged.
