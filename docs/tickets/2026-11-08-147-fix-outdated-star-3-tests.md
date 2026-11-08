# 147 — Fix 5 outdated tests after the star 3 rule change

Status: ready-for-human. Blocked by: none. Source: Xcode test run 2026-11-08 01:25 (177 tests, 5 failing, 0 build errors).

## Goal

Ticket 143 moved star 3 from Practice ("From memory" the next day) to two passed reviews in Training. Five old tests still check the old rule, so they fail. The app code is correct; only the tests are outdated. Update the tests to the new rule. Do not change app code.

## Failing tests

1. `MemoryStarRuleTests.testNextDayEarnsMemoryCredit` — now `mayEarnMemoryCredit` is always `false`; change the assertion to `XCTAssertFalse` (rename to say "no longer earns").
2. `MemoryStarRuleTests.testOldRecordWithoutDayEarnsMemoryCredit` — same.
3. `MemoryStarRuleTests.testMemoryCreditQualificationWithFadingNotesSetting` — same: both settings give no credit in Practice.
4. `PracticeSessionTests.testMemoryStarAtEightyPercentEmitsEventAndAutomaticallyStopsAfterRequiredPasses` — From memory at 80 % in Practice no longer gives a star event or a stop. Rewrite it to assert that no `StarEvent` is emitted (or delete it if `Star3ReviewTests` already covers this case: "From memory run in Practice → no star 3").
5. `StarRequirementTests.testTwoStarsRequirementWithSingleAndMultipleRuns` — the star 3 line is now "Star 3: two reviews in Training · 0 of 2" / "Třetí hvězda: dvě opakování v Tréninku · 0 ze 2" (and the "Next: …" variants). Update the expected strings; keep the checks for stars 1 and 2 unchanged.

## Files to read

`AGENTS.md`, this ticket, `docs/tickets/2026-11-07-143-star-3-through-two-reviews.md`, `SmackAPadTests/MemoryStarRuleTests.swift`, `SmackAPadTests/StarRequirementTests.swift`, `SmackAPadTests/PracticeSessionTests.swift`, `SmackAPad/Sources/UI/StarRequirement.swift` (read only).

## Acceptance criteria

- [x] The 5 tests above pass; all other tests still pass.
- [x] No app code changed, no new tests added.
- [x] Build succeeds.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: mechanical test updates, the new rule is fully described in ticket 143.

## Done rule

Stop after successful build and tests. Commit (AGENTS.md); Jakub pushes.

## Implementation — 2026-11-08

- Updated `MemoryStarRuleTests`: `testNextDayNoLongerEarnsMemoryCredit`, `testOldRecordWithoutDayNoLongerEarnsMemoryCredit`, and `testMemoryCreditQualificationWithFadingNotesSetting` assert `XCTAssertFalse` for Practice `mayEarnMemoryCredit`.
- Updated `PracticeSessionTests.testMemoryStarAtEightyPercentDoesNotEmitEventOrStop`: asserts that running From memory at 80% in Practice does not emit `starEvent`, does not stop, and does not award star 3.
- Updated `StarRequirementTests.testTwoStarsRequirementWithSingleAndMultipleRuns`: updated Star 3 requirement text expectations to the new format "Star 3: two reviews in Training · 0 of 2" / "Třetí hvězda: dvě opakování v Tréninku · 0 ze 2".
- Ran test suite on iPad Air 11-inch (M4) simulator: 177 tests executed, 0 failures.
