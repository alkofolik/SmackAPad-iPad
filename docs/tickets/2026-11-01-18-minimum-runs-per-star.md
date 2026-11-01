# 18 — Minimum number of runs per star (short lessons)

Status: ready-for-agent (2026-11-01). **Start after tickets 15 and 17 are finished and committed** (both touch `PracticeSession.swift`).

## Problem

A lesson with only 4 hits can earn two stars in a few seconds (one pass is enough), which is too little practice.

## Rule

Every lesson has `expectedHits` = number of expected hits in one pass (for the current pad mode).

`requiredRuns = clamp(ceil(16 / expectedHits), 1, 4)`

| Hits per pass | Required runs |
|---|---|
| 1–4 | 4 |
| 5 | 4 |
| 6–7 | 3 |
| 8–15 | 2 |
| 16 and more | 1 |

The threshold `16` is one named constant (`minimumHitsPerStar`), easy to change.

A star is awarded only after `requiredRuns` **consecutive** qualifying passes:
- Star 1 (passed): `requiredRuns` consecutive passes with score >= 70 % (intro lessons 80 %), at any tempo.
- Star 2 (goal tempo): `requiredRuns` consecutive clean passes at tempo >= `targetBpm`.
- Star 3 (from memory): `requiredRuns` consecutive passes with score >= 80 % at goal tempo with the pattern hidden.

Each star has its own counter. A failing pass resets only the counters of the stars it failed. Counters live in the session (not persisted) and are cleared on START, RESTART and STOP.

## Unchanged

Per-pass scoring (`ScoringEngine.finish()`), the clean-run error limits, the tempo rise after a clean pass, the rule that the run stops automatically when the 2nd or 3rd star is earned and that earning the 1st star only plays the animation.

## Legacy note

The legacy app only asks for 3 clean runs on intro lessons (`lessonCompletionState` in `ui/practice-status.js`). Intro lessons keep that rule **if it is stricter** than `requiredRuns`: use `max(requiredRuns, 3)` for them. Check the iPad intro code (ticket 14) before changing anything and keep one place for the rule.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md` §8 Stars, `docs/design/2026-11-01-star-feedback.md`, `SmackAPad/Sources/UI/PracticeSession.swift`, `StarAward.swift`, `SmackAPad/Sources/Scoring/ScoringEngine.swift`, `SmackAPad/Sources/Progression/Progression.swift`.

## Tasks

1. Add the pure function `requiredRuns(expectedHits:)` and the three consecutive-run counters (testable without UI).
2. Use them where a pass result currently decides a star in `PracticeSession`; the star animation and auto-stop then fire only when a star is actually awarded.
3. Show the progress quietly in the status row while it is relevant (for example "2 / 4" next to the score), only for lessons with `requiredRuns > 1`. No new colours.
4. Unit tests: 4, 6, 8, 16 hits; a failing pass resets only the failed counters; tempo changes do not reset star 1; START/RESTART clears counters.
5. Texts via the localisation catalogs (`en` and `cs` keys).

## Acceptance criteria

- [ ] A 4-hit lesson needs 4 consecutive good passes for star 1 and the same for stars 2 and 3.
- [ ] A lesson with 16 or more hits behaves as before.
- [ ] Auto-stop after the 2nd or 3rd star still works.
- [ ] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: one short intro-level lesson and one long lesson.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), high thinking.
- **Reasoning**: Changes the rules for earning stars and interacts with scoring, tempo and persistence; Flash is not recommended.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task.
