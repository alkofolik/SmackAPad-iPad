# 102 — Fix three unit tests that fail after tickets 97–100

Status: ready-for-agent. Source: Jakub, 2026-11-05 (Xcode reported failed tests). Checked on commit `49bda07` (before ticket 93–96 follow-ups and the pad-key/one-bar fix): the same three tests fail there, so the cause is tickets 97–100, not the UI work.

## Goal

The test suite passes again (154 tests, 0 failures). The app code is probably right and the tests are outdated; confirm against tickets 97 and 98 before changing anything.

## Failing tests

1. `IntroProgressMigrationTests.testEveryRemovedRecordMovesToItsSpecifiedIntroLessonAndKeepsLessonSix` (line ~26 and ~28) and
2. `IntroProgressMigrationTests.testExistingTargetStarsScoreAndTempoAreNeverLowered` (line ~57):
   the test expects migrated records to have `reviewStep`, `reviewDueDay` and `settled` empty (nil). The code now sets `reviewStep: 0`, `reviewDueDay: "2026-11-06"`, `settled: false` for mastered lessons (spaced review, ticket 98).
3. `PracticeSessionTests.testMemoryStarAtEightyPercentEmitsEventAndAutomaticallyStopsAfterRequiredPasses` (line ~123):
   no star event is emitted. Most likely cause: ticket 97 rule 3. If the lesson earns star 2 on the same day, From memory earns no credit until a later day. The test must start from a record whose `masteryDay` is before today (or use the injectable clock from ticket 97).

## Rules

- Decide per test: if the code follows tickets 97/98, fix the **test** (new expected values, earlier `masteryDay`). If the code contradicts the ticket, stop and report instead of changing code.
- Do not change app code unless a test proves a real bug. No new tests.
- The migration tests must still prove the original point: records move to the right intro lesson, stars/score/tempo are never lowered, lesson six is kept.

## Files to read

`AGENTS.md`, this ticket, tickets 97 and 98, `SmackAPadTests/IntroProgressMigrationTests.swift`, `SmackAPadTests/PracticeSessionTests.swift`, `SmackAPad/Sources/Persistence/Persistence.swift`.

## Acceptance criteria

- [ ] The three tests pass; no other test newly fails.
- [ ] Build succeeds.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: small test updates, but the agent must decide test-vs-code from tickets 97/98.

## Done rule

Run the full test suite once. Stop after success; do not commit. Claude commits afterwards.
