# 201 — Bug: finished mix is still offered on Training

Status: ready-for-agent. Reported by Jakub on 2026-11-13 (iPad review, photo 8).

## Goal

Jakub finished today's mix. Back on Training the Mix tile still said "now" and the fourth tile still offered the mix. He did not play it again; he left Training, came back, and only then the tiles showed the mix as done and the fourth tile changed to "Summary · Done for today". Training must show the true state of the day the moment it appears.

## Rules

1. **Find the cause first.** Use the `diagnosing-bugs` skill. Reproduce with a test or a debug scenario: finish the last mix lesson, return to Training, read the tiles. Write the cause in the implementation notes before changing code.
2. **One source of truth.** The tiles on Training and the fourth tile ("Continue" / "Summary") must be derived from the saved day state (`TodayPlan` / progress store), not from a copy that is only refreshed on `onAppear` or on navigation. When the mix result is recorded, Training updates without leaving the screen.
3. The same must hold for reviews and the new lesson: after each step the tiles are correct right away.
4. Do not change what counts as "done"; only when the screen learns about it.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/TrainingScreen.swift`, `TodaySessionScreen.swift` (session model at the top: `record`, `finish`, `advance`, `save`), `SmackAPad/Sources/Progression/TodayPlan.swift`, `TrainingMix.swift`, `SmackAPad/Sources/Persistence/ProgressStore.swift`.

## Tests

One unit test: after the last mix lesson's outcome is recorded, the Today state reports the mix as done and the next action as the day summary, without any extra reload call.

## Acceptance criteria

- [ ] After the last mix lesson, Training shows the Mix tile as done and the fourth tile as Summary immediately.
- [ ] Same immediate update after a review and after the new lesson.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Play the whole day (reviews, new lesson, mix). After each step look at Training without leaving it: every tile is right.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check. Do this ticket before 204.
