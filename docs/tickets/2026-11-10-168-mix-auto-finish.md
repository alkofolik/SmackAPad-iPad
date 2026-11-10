# 168 — Mix: finish by itself and show the result

Status: ready-for-agent. Approved by Jakub on 2026-11-10.

## Problem

When Jakub plays a mix of lessons, after the last lesson of the mix the session does not stop. It keeps cycling (`advanceMix`, `PracticeSession.swift` ~867: `mixIndex = (mixIndex + 1) % mixLessons.count`) and he cannot tell whether he met the requirements until he presses STOP.

## Required behaviour

1. When the last lesson of a mix round finishes (`mixIndex == mixLessons.count - 1` after its pass is scored, ~1198, where `recordFinishedMixRound` is called), stop the run automatically like an earned-star stop: no new count-in, no next round.
2. Immediately show the existing mix result (`mixResultsCard`, `PracticeScreen.swift` ~694) with a clear per-lesson outcome: met / not met and stars gained this round, plus whether the round counted (e.g. memory round, review step). Reuse existing icons and the star animation; no new sentences in the UI.
3. If the mix's purpose (Today/Training review, From memory) is fully met, show the existing star or done feedback. If not, the result shows what is missing via existing marks.
4. Offer the existing START to play the mix again from the first lesson. Credit already earned stays (as in Learning mode today).
5. Check whether the mix is meant to repeat by design anywhere (Training, Today, Home, LessonPicker). If some entry relies on endless cycling, stop and report before changing it.

## Tests

Session test with a 2- and 3-lesson mix on the test clock: after the last lesson's pass the session is stopped, `mixResults` are complete, `recordFinishedMixRound` is called once, nothing is scheduled after.

## Acceptance criteria

- [ ] A mix stops by itself after its last lesson and shows the result at once.
- [ ] The result makes clear which lessons were met and what was gained.
- [ ] STOP mid-mix still works as today.

### Manual iPad check for Jakub

Start a mix from Training/Today, play through to the last lesson, and check that it stops and shows the result without pressing STOP.

## Files to read

`AGENTS.md`, `PracticeSession.swift`, `PracticeScreen.swift`, `TrainingScreen.swift`, `TodaySessionScreen.swift`, `LessonPicker.swift`, `Progression/*`.

## Agent assignment

Codex GPT-6.1 Sol, high. Touches session state and progress recording.

## Done rule

Build, full test plan per `AGENTS.md`, commit, stop for Jakub's iPad check.
