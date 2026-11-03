# 59 — A scored run lasts about four bars, as in the original tool

Status: done, verified on iPad (2026-11-03). Source: Jakub, 2026-11-03, after comparing with the original tool.
Agent: Gemini 3.8 Pro, high thinking (fallback: Codex GPT-6.1 Sol, high).
Run after ticket 58 (both touch the practice screen).

## Why

Short lessons feel rushed: a run ends before the player has settled in, the tempo jumps every few seconds, and the lesson stops almost at once. You hardly learn the groove before the next lesson starts.

The original tool scored a run of **`max(1, round(4 / bars)) * bars` bars**: the lesson was repeated so that one run lasted about four bars (legacy `app/v21/src/engine/transport.js`, the `bars:` of the whole-lesson engine):

| Lesson length | Repeats per run | Run length |
|---|---|---|
| 1 bar | 4× | 4 bars |
| 2 bars | 2× | 4 bars |
| 3 bars | 1× | 3 bars |

This app scores one pass of `lesson.bars`, so a one-bar lesson is judged, and raises the tempo, after every single bar: four times shorter.

Example: "A complete backbeat" (1 bar, 50 → 80 BPM, step 5) now reaches two stars in roughly 40 seconds; with four-bar runs it takes about 2½ minutes.

## Rules

1. One pass (the unit that is scored, raises the tempo and earns star credit) covers `repeats = max(1, round(4 / lesson.bars))` consecutive repetitions of the lesson, with no gap between them. The metronome keeps running across them.
2. Implement it like the section loop: derive the scored lesson from the real one (hits repeated with `step + k * lesson.bars * 16`, `bars = repeats * lesson.bars`), next to `PracticeSession.practiceLesson`. A section loop keeps its current behaviour (one repetition of the selected bars) unless that is trivially covered by the same rule.
3. **The notation still shows the lesson's own bars**, not four copies. The playhead returns to bar 1 on each repetition. Show a small, quiet counter of the repetition within the run (e.g. "2/4") where the pass number or bar info is shown today. Hit judgments and colours from an earlier repetition must not stay on the notation once the next repetition starts (the same rule as between passes today).
4. Star thresholds then follow the longer run automatically: `StarStreak.requiredRuns` (16-hit minimum) gives 1 run for most lessons and keeps 3 for intro lessons, as in the original tool. Check that the clean-run error allowance in `ScoringEngine.finish()` (based on the expected hit count) still makes sense with the longer runs, and state your conclusion in the report. Do not change thresholds unless something is clearly broken.
5. Tempo still rises at most once per pass. Listen mode plays one repetition, as now.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeSession.swift`, `SmackAPad/Sources/UI/PatternField.swift`, `SmackAPad/Sources/UI/PracticeScreen.swift` (only where the pass, bar or position is shown), `SmackAPad/Sources/UI/StarStreak.swift`, `SmackAPad/Sources/Scoring/ScoringEngine.swift` (`finish()` only). Do not read the legacy folder; the rule above is all you need from it.

## Tests

Scoring and timing code: the tdd skill is allowed. One test: a one-bar lesson played perfectly over one pass yields `repeats × hits` expected and matched hits, and exactly one tempo step.

## Do not

- Do not change scoring windows, star rules (beyond rule 4) or the lesson data files.
- If something fails twice, stop and report.

## Acceptance criteria

- [ ] A one-bar lesson plays four bars per scored run; a two-bar lesson plays two repetitions; a three-bar lesson one.
- [ ] The notation shows the lesson's bars with a repetition counter; old marks clear between repetitions.
- [ ] The tempo rises only after a whole run.
- [ ] Build passes. Commit, stop. Final report max 5 lines.
