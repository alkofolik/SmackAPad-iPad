# 226 — Review run: unclear result, no progress shown after a decision, no stop

Status: ready-for-agent (needs Jakub's OK before any code is touched). Reported by Jakub on 2026-11-23.

## What Jakub saw

Lesson opened as a review after several days (review due).

1. He played. The run stopped by itself at the end of a pass and said the requirements were not met and he can play again. He expected the run to keep going until the requirements are met or he stops it himself.
2. He started again. This time there was no sign of what he had already met and what was still missing. The run never stopped. He gave up and pressed STOP; the result card showed that he had met everything long ago in that round. He expected the run to stop by itself once the requirements were met.

## What is known (code reading, not yet reproduced)

All in `PracticeSession.swift` and `ReviewScheduler.swift`:

- A review is decided after 2 qualifying hidden passes (`LearningRules.reviewDecisionPasses`): 2 good passes = passed, 2 bad passes = failed.
- Only `.passed` / `.settled` set `stopAfterPass` (~line 1301). `.failed` does not stop the run.
- After ANY decision the schedule gets `lastReviewedDay = today`, so `isDueReview` becomes false for the rest of the day. From then on:
  - `reviewRunProgress` returns nil, so the counter (x of 2) disappears. This matches "I no longer see what I met".
  - The whole review branch is skipped (~line 1280), so later passes can never change today's outcome and nothing stops the run. A second attempt on the same day after a failed review is a plain practice run that cannot end.
- `reviewPendingReason` is set to `.unfinishedReview` after every review pass (~line 1292) and is not cleared when the window is decided, so the end-of-run line can say "not finished, play again" although the review is already decided for today.
- Not yet explained: why the first run stopped by itself at all (a failed decision does not stop it per code). Candidates: a pass that did not count (notes visible, below goal tempo), the Today/Continue path, or a short lesson ending its loop. Reproduce before guessing.

## Rules

1. **Reproduce first** with the `reviewDueToday` debug scenario: (a) fail the review (two bad hidden passes at goal tempo) and note exactly what stops the run and what the card says; (b) start again the same day and note what the HUD shows and whether the run ever stops. Write the findings into this ticket before changing code.
2. Decide with Jakub what a failed review should do, then implement one consistent rule. Options to put to him:
   - A: failed decision ends the run with a clear result ("not met, review moves to tomorrow"); starting again the same day is plain practice and is labelled as such.
   - B: the review stays open for the day and keeps running until it is passed or Jakub stops it.
3. Whatever the rule: while a review is open the HUD shows what is met and what is missing (counter stays visible until the run ends); once the review is decided as passed, the run stops (already true); a decided review is never shown as "unfinished".
4. Do not change scoring, star rules, review gaps or the 2-pass decision rule unless Jakub asks.
5. Delete the old code and tests that enforce any rule this ticket replaces.

## Files to read

`AGENTS.md`, `docs/tickets/` 176 and 189 (search only), `SmackAPad/Sources/UI/PracticeSession.swift` (search: `reviewRunProgress`, `isDueReview`, `reviewPendingReason`, `stopAfterPass`), `SmackAPad/Sources/Progression/ReviewScheduler.swift`, `SmackAPad/Sources/UI/PracticeInstruments.swift` (~line 715–790, 916–960).

## Tests

One regression test per confirmed cause (for example: after a failed review the same-day run shows a defined state and a defined stop behaviour). Run the full suite (touches review rules).

## Acceptance criteria

- [ ] Reproduction and cause written into this ticket.
- [ ] After a failed or passed review the same-day behaviour matches the rule Jakub chose.
- [ ] The HUD never loses the review progress while the run can still change the outcome.
- [ ] The end-of-run line never says "unfinished" for a decided review.
- [ ] Build and tests pass.

### Manual iPad checks for Jakub

Same lesson as in the report, review due: fail it, start again; then pass it. Both times the screen tells what is met and what is missing, and the run stops when the rule says so.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (reproduction before the fix). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run tests per `AGENTS.md`, commit, stop for Jakub's iPad check.
