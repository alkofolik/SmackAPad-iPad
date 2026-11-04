# 67 — Practice: tempo step lands one run late (bug)

Status: ready. Source: Jakub, 2026-11-04 (iPad test of ticket 66). Use the tdd skill (timing code).

## Problem

Jakub: "the run ruler seems to be half of the measured run, it always fills twice before the tempo goes up."

The ruler is right: it spans one scored run (`repeatsPerRun × practiceLesson.bars`), and stars count per run. The bug is in the tempo step:

- `PracticeSession` queues the next pass about 0.5 s before the current one ends (`horizon = time + 0.5`) and takes its BPM from `tempo.queue(after:…)`.
- The result of the current pass (`tempo.completed(nextBpm:)` in `finishCompleted`) arrives only after `pass.finalTime` (pass end + timing window), so after the next pass is already queued.
- The tempo request is therefore consumed by the pass **after** the next one. The player hears the faster tempo one full run late, so it feels like a run is two ruler lengths.

## Rule

The tempo step decided by run N must start with run N + 1, at the ruler's restart.

- At queue time, decide the next BPM from the run's result **as known so far**: every note whose matching window has closed counts as usual; notes still inside their window (the last fraction of a beat) are left out of that decision.
- The final, complete result still drives stars, verdicts, the lap vault, summaries and saving exactly as now. Only the tempo decision moves earlier.
- If the early decision and the final result disagree (a late miss), keep the tempo already queued; never change tempo inside a running pass.
- Keep `tempo.tempoUpEvent` and the TempoUp banner showing at the moment the faster pass starts (already so).
- Section loops and listen mode: same rule; listen keeps its fixed BPM.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeSession.swift` (tick loop around `horizon`, `makePass`, `finishCompleted`), `SmackAPad/Sources/Scoring/PracticeTempo.swift`, the scorer that produces `nextBpm` (find it from `result.nextBpm`) and its tests.

## Acceptance criteria

- [ ] Test first (tdd): a passed run N produces the higher BPM on run N + 1, not N + 2.
- [ ] Test: a run whose last note is missed after the early decision does not change the already queued tempo.
- [ ] Stars and verdicts still use the full result (existing tests stay green).
- [ ] Build passes.
- [ ] **iPad test (Jakub)**: a lesson with tempo steps; the tempo rises exactly when the ruler starts again after a good run.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**: audio timing in the tick loop. Fallback: Gemini 3.8 Flash, high.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
