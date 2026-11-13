# 199 — Star 2 meter: show the tempo climb first, the clean runs only at goal tempo

Status: ready-for-agent. Design approved by Jakub on 2026-11-13 (mockups "A" and "B" in that conversation). Do after 198 (same HUD area).

## Goal

After star 1, the top-right meter shows "★2" with three run blocks ("3 clean runs at goal tempo"). While the tempo is still below the goal, every clean run raises the tempo instead of counting: the current block fills during the run and then empties again. To the player it looks like the progress is being reset after every success. Until the goal tempo is reached the run blocks mean nothing and confuse.

Split star 2 into two visible phases:

- **Climb** (current BPM below goal): the meter shows how far the tempo still has to go.
- **Hold** (current BPM at goal): the meter shows the clean runs at goal tempo, as today.

The scoring rule itself does not change: only runs at goal tempo count toward star 2.

## Rules

1. **Climb phase** (star 2 is the current star and the current BPM < goal BPM): next to the "★2" capsule show a **tempo ladder** instead of run blocks: small start BPM on the left, small goal BPM on the right, and between them one short segment per auto tempo step (`(goal − start) / step`, rounded up). Segments up to the current BPM are filled. With more than 8 steps, or with auto step off, draw one continuous bar filled to `(current − start) / (goal − start)`. No run blocks and no in-run fill in this phase.
2. **Hold phase** (current BPM ≥ goal): the ladder is replaced by today's run blocks (`RunMeterView`) with the required count. The switch happens at the pass where the goal tempo starts, together with the goal sign from ticket 198, with a short cross-fade (none with Reduce Motion).
3. Star 1 ("Passed") and the review meter are unchanged; they count at any tempo.
4. If the player lowers the tempo below the goal by hand, the meter goes back to the climb phase; runs already counted at goal tempo stay counted (as the scoring already does).
5. VoiceOver: climb phase reads "Star 2: tempo 65 of 80 BPM"; hold phase keeps "Consecutive passes … 1 of 3". New strings in English and Czech.
6. Same look in every place `PracticeProgressMeter` is shown (normal lessons, training mix). Colours only from `Theme`; check light and dark, English and Czech.
7. Delete any code that only existed to fill or drain the star 2 run block below the goal tempo.

## Files to read

`AGENTS.md`, `PracticeInstruments.swift` (`PracticeProgressMeter`, `RunMeterView`), `PracticeSession.swift` (`starRunProgress`, `runMeterFraction`, where the auto tempo step and `tempoUpEvent` are set), `PracticeScreen.swift` (`runMeter`), `StarStreak.swift`, settings for the tempo auto-step value, `Theme.swift`, both `Localizable.strings`.

## Tests

Use the tdd skill (this decides what the scoring meter shows). Unit tests for a small pure model of the meter phase:
- BPM below goal with star 2 current → climb, with the correct number of filled segments (e.g. start 60, goal 80, step 5, current 65 → 1 of 4).
- More than 8 steps or step 0 → continuous fraction.
- BPM at goal → hold with today's count/required.
- Star 1 current → unchanged run meter at any tempo.

## Acceptance criteria

- [ ] Below the goal tempo, after star 1, the meter shows the tempo ladder and no run blocks.
- [ ] At the goal tempo the ladder turns into the run blocks and they count as today.
- [ ] Lowering the tempo by hand goes back to the ladder.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

Take a lesson with star 1, start at a low tempo with auto step on: the ladder fills step by step, then at the goal it turns into three blocks that fill with clean runs. Check in Czech and light appearance.

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
