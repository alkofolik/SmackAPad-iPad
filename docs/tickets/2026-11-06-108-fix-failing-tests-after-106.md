# 108 — Fix three failing unit tests (found 2026-11-06)

Status: ready-for-agent. Source: Jakub, 2026-11-06 (Xcode: 166 tests, 3 failing; run at 06:27 on main, commit 3c25498).

## Goal

The test suite passes again (166 tests, 0 failures). Decide per test whether the **test** is outdated or the **app code** has a real bug. Fix the test only when the code follows its ticket; if the code contradicts its ticket, stop and report.

## Failing tests (exact messages from the Xcode result)

1. `ReviewScheduleTests.testBelowGoalTempoOrNotFromMemoryOrNotYetDueUnchanged` (~line 96).
   Expected `lastReviewedDay: nil`, got `lastReviewedDay: "2026-11-05"`. `ReviewScheduler.evaluate` now sets `lastReviewedDay = today` (ReviewScheduler.swift:127, added with ticket 104). Question to answer: should a run that does NOT count (below goal tempo / not from memory) really stamp `lastReviewedDay`? Ticket 98 rule 3 says "does not count → schedule unchanged". Read ticket 98 and 104. If stamping is only for runs that count, this is a code bug (fix the code line); if the stamp is intended, update the test's expected value.
2. `AfterMeSessionTests.testPerfectResponseScoresOneHundredPercentWithoutChangingProgress` (~line 69).
   Score is 0.875 (7 of 8 hits) instead of 1.0, three assertions.
3. `AfterMeSessionTests.testSectionLoopDefinesBothPhraseHalvesAndContinuousCycleLength` (~line 115).
   Score is 0.75 (3 of 4 hits) instead of 1.0.

For 2 and 3: exactly one hit is lost in each. Suspects: (a) the test uses real host time and a timing window, so it may be flaky; (b) ticket 104/106 changed `PracticeSession.swift` (it now calls `recordAfterMeResponse` and has new memory-pass logic, ~lines 31 and 57 of the 106 diff) and may have changed which hit counts. Run the two tests 3 times in a row first. If they fail every time, it is not flakiness: find the cause in `PracticeSession.swift` (`git diff 49bda07 HEAD -- SmackAPad/Sources/UI/PracticeSession.swift`). Also check whether ticket 106 intentionally breaks the rule "After me must not record ... anything" in the test helper (`progress.records == before`); that assertion is NOT failing now, so do not weaken it.

## Rules

- Do not change app code unless a test proves a real bug and the ticket says the code is wrong.
- No new tests. Use the tdd skill only if the fix touches timing or scoring code.
- Keep what each test proves (call/response scoring, section loop, unchanged schedule).

## Files to read

`AGENTS.md`, this ticket, tickets 98, 101, 104, 106, `SmackAPadTests/ReviewScheduleTests.swift`, `SmackAPadTests/AfterMeSessionTests.swift`, `SmackAPad/Sources/Progression/ReviewScheduler.swift`, `SmackAPad/Sources/UI/PracticeSession.swift`.

## Acceptance criteria

- [ ] The three tests pass; no other test newly fails.
- [ ] Build succeeds.
- [ ] Final report says for each test: "test outdated" or "code bug", in one line.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: test 1 is a small decision from tickets; tests 2 and 3 need real diagnosis (flaky timing vs a regression), so thinking level is high, not medium.

## Done rule

Run the full test suite once. Stop after success. Commit (Jakub pushes).
