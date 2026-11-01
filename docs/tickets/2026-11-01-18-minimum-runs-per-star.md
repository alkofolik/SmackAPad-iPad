# 18 — Minimum number of runs per star (short lessons)

Status: ready-for-ipad-test (2026-11-01). Implementation, three new unit tests and simulator build complete. Tickets 15 and 17 were committed before this work.

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

- [x] A 4-hit lesson needs 4 consecutive qualifying passes for each star.
- [x] A non-intro lesson with 16 or more hits behaves as before; intro lessons retain the stricter minimum of 3.
- [x] The existing auto-stop after a newly awarded 2nd or 3rd star uses the completed streak, as does the animation.
- [x] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: one short intro-level lesson and one long lesson.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), high thinking.
- **Reasoning**: Changes the rules for earning stars and interacts with scoring, tempo and persistence; Flash is not recommended.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task.

## Implementation and validation (2026-11-01)

- Added the pure `StarStreak` policy with one `minimumHitsPerStar` constant, the clamped hit-count rule and the intro minimum in the same function. Checked ticket 14, `IntroScreen.swift` and `Progression.swift`: the intro screen reuses practice and has no separate consecutive-pass policy.
- Three session-only counters independently consume the existing per-pass qualifications. START/RESTART/STOP reset them. Tempo scheduling and `ScoringEngine.finish()` are unchanged. Cumulative summary flags, persistence and `StarAward` receive only stars whose streak reached the requirement.
- A quiet counter next to the score follows the first unearned star, then memory when enabled or goal tempo otherwise. It is hidden for single-pass lessons, Listen, section loops and when all applicable stars are already earned. Both languages include the format and the VoiceOver description/value.
- Three new XCTest cases passed, each after first demonstrating the missing behavior: required runs for 4/6/8/16 hits and intro minimum; independent consecutive qualifications and failure resets; resets between runs, passing progress across tempo changes and single-pass long lessons. Tests ran on macOS through a temporary Swift package under `build/ticket-18/pure` symlinked to the actual production policy and test file. No previously passed tests were rerun.
- Final command: `xcodebuild build -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ticket-18/app CODE_SIGNING_ALLOWED=NO` — **BUILD SUCCEEDED**. `git diff --check` passed. No further builds or tests were run after success.
- Jakub still verifies a short intro lesson and a long lesson on iPad, including star animation and automatic stop.
