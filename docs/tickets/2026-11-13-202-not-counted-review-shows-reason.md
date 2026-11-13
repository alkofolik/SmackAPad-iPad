# 202 — A review that did not count shows the reason, not "100 %"

Status: ready-for-agent. Reported by Jakub on 2026-11-13 (iPad review, photos 4 and 9).

## Goal

A review only counts after two passes from memory (notes hidden) at 80 % or more. When that fails, the app still shows the score from the run with visible notes, for example "100 %", next to "Did not count" / "again tomorrow". Jakub reads this as "I passed, so why not?". The score shown must be the one that decided, or no score at all.

## Rules

1. **Where a review did not count**, show no percentage. Show one short reason line instead, built from the real outcome, for example:
   - EN: "From memory: 2× below 80 % · again tomorrow"
   - CS: "Z paměti: 2× pod 80 % · zítra znovu"
   If the review was skipped or left early, say that instead ("Skipped · again tomorrow" / "Přeskočeno · zítra znovu").
2. Applies to every place that lists the day's steps: the Today step cards (photo 4), the day summary list (photo 9), and the mix summary rows (ticket 203 will reuse the same text).
3. **One text builder.** Put the reason text in one pure function (next to the existing outcome model), used by all those screens. Delete the old per-screen strings such as "Two hidden passes below 80% · try again tomorrow" once unused.
4. The Reviews stat tile ("1 / 2") stays as it is.
5. Localized in both languages; sentence case.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/TodaySessionScreen.swift` (`TodayStepperView`, `stepStatus`), the day summary view (search "Done for today"), `SmackAPad/Sources/Progression/LearningRules.swift`, `TodayPlan.swift`, `Resources/en.lproj/Localizable.strings`, `Resources/cs.lproj/Localizable.strings`.

## Tests

Unit test for the reason builder: counted review → no reason; two hidden passes below 80 % → the "from memory" reason; skipped → the skipped reason. Both languages.

## Acceptance criteria

- [ ] A review that did not count shows the reason line and no percentage on the Today cards and the day summary.
- [ ] Counted reviews still show their score.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Play a review with notes visible only, fail the hidden passes: no "100 %", a clear reason instead. Check in Czech.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
