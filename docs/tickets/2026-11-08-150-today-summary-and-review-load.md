# 150 — Today summary, legacy ★3 and review load

Status: implemented, ready for iPad review. Approved by Jakub in this conversation. Blocked by: none. Source: AI panel round 1 (`docs/reviews/ai-panel/results/synthesis.md`, items 3, 4, 5); `docs/2026-11-08-ai-panel-action-plan.md`, Batch 1.

## Goal

Three reviewers agree the Today flow is confusing and discouraging. Fix three linked problems without changing the review schedule itself.

1. **Summary contradicts the steps.** A step shows ✓ and 100 % while the summary says "Reviews 0 of 2". The step ✓ means "played", the summary counts only "passed/settled" (`TodaySessionScreen.swift` around lines 332–337 vs 759–766). First trace why the two reviews did not pass (write the finding into this ticket). Then give every step one of three clear states: **Played**, **Passed**, **Did not count** — the last one with a short reason. Step marks and summary must use the same states and the same numbers.
2. **Legacy ★3 next to "Review · 0 of 2 passed".** Lessons imported from the legacy app have ★3 but no review history (`Persistence.swift` around lines 1118 and 1140). Decide the least surprising display (for example: such a lesson starts its review chain quietly, with no "0 of 2" shown until the first review is played) and implement it. Do not change stored stars, only what is shown and how the chain starts.
3. **Review load looks like debt.** Today plays at most 2 reviews (`TodayPlan.swift` line 28, `prefix(2)`), but Home and Training show "29 due" in orange. Show "2 today" on Today; show the rest as a separate, calm queue (not orange, not a count of failure); label the forecast so it is clear what it counts; remove the orange backlog number from Home.

## Rules

- The review schedule, `prefix(2)` limit, scoring and star rules stay as they are.
- Both English and Czech strings; no new screen.
- Write tests first for the state logic (Played / Passed / Did not count, legacy ★3 start, "today" vs queue counts).
- Update the screenshots list in the ticket if a screen changes (`docs/reviews/ai-panel/` is local material, do not commit it).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/TodaySessionScreen.swift`, `SmackAPad/Sources/Progression/TodayPlan.swift`, `SmackAPad/Sources/Persistence/Persistence.swift` (review fields), `docs/reviews/ai-panel/results/synthesis.md` sections 2 and 3, existing Today/review tests.

## Acceptance criteria

- [x] For a played review that did not count, the step and the summary both say so and give a reason.
- [x] Step marks and summary totals can never disagree (one source of truth, covered by a test).
- [x] A legacy ★3 lesson never shows "0 of 2 passed" as if it had failed.
- [x] Today shows "2 today"; the remaining due reviews appear as a separate calm queue; Home has no orange backlog number.
- [x] Full test suite passes before commit.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Claude Opus 5.5, extended thinking.
- **Reasoning**: the first part is a root-cause trace through scoring and persistence; the rest is UI wording and state, which needs consistency across several screens.

## Root-cause trace

- `PracticeSession.finishCompleted` records every full run in `runResults`, including visible-note warm-ups. `PracticeScreen` previously reported the maximum score and optional `reviewFeedback` to Today.
- `ReviewScheduler.evaluate` deliberately returns no feedback for passes 1–2 when notes fade. An eligible hidden pass then enters `advanceWindow`; it takes two successful hidden passes to produce `.passed` or `.settled`. A perfect warm-up, or just one perfect hidden pass, therefore has a score of 100% without a passed review. Wrong mode or tempo produces `.doesNotCount`; two failed eligible passes produce `.failed`.
- The old stepper showed a green check for every visited step (even an unplayed skipped step), while the summary counted only `.passed`/`.settled`. Persistence advances the schedule only after the review window is decided. The score and the schedule were correct; their presentation used different definitions of completion.
- The historical screenshots do not contain a pass-by-pass trace, so the exact exclusion for those two recorded examples cannot be recovered. The new session regression reproduces the 100%-without-review-credit path through the real session, then verifies that the fourth perfect pass completes the review.

## Implementation decisions

- `TodayPlan.Step.status` is the source for step marks, handoff, summary rows, Training indicators and review totals. Unplayed steps have no success mark. Saved outcomes now retain the pending reason; old saved outcomes show an unfinished-review explanation. A committed review result survives later practice callbacks.
- Imported three-star lessons retain their stars and existing migration schedule (first review tomorrow). Before the first full attempt, Practice says "Review · start from memory" instead of "0 of 2 passed". The same review window starts normally when played; no schedule or award rule changes.
- Today uses the saved plan's review selection, at most two lessons. The remaining due lessons form a separate neutral queue, with no late-day labels or orange row lights. Finishing a selected review does not pull another queue lesson into today's count. Home's Training pad has no backlog number. The forecast explicitly describes cumulative due counts if nothing is played, rather than new arrivals or a daily assignment.
- English and Czech copy is included. Review gaps, `prefix(2)`, scoring and stars are unchanged.

## Screenshots to refresh on iPad

Local review material under `docs/reviews/ai-panel/` stays uncommitted.

- Home: Today says "2 today"; Training pad has no backlog number.
- Training: two selected reviews, a separate remaining queue, and the cumulative forecast caption; also capture the finished summary.
- Today handoff and summary: a perfect warm-up, one eligible hidden pass, a passed review, an ineligible tempo/mode, a failed review, and a skipped step. Check matching labels, reasons and counts in Czech and English, portrait and landscape.
- Practice: imported three-star lesson before the first attempt, without a zero-pass counter.

## Verification

- Tests were added before the shared state implementation; the initial focused invocation failed on the missing state and load APIs.
- Full suite: `xcodebuild test -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'platform=iOS Simulator,id=B325EF98-85F7-4EF5-B6F7-AC939B2CBBC0' -derivedDataPath /tmp/smackapad-ticket150 -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO` — 191 tests passed, zero failures, 2026-11-08.
- Both localization files passed `plutil -lint`. No successful tests were repeated. Visual and hardware checks remain with Jakub on iPad.

## Done rule

Stop when the acceptance criteria are met and the full test suite passes. Commit (AGENTS.md); Jakub pushes.
