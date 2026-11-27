# 234 — Smart coach on ResultCard: one-tap weak-bar drill and tempo step-down

Status: ready-for-agent

## Goal

When a scored full run ends below the 80% pass mark, offer one smart, one-tap coaching action on `ResultCard`—either isolating the weakest bar in a slightly slower loop (`"Drill bar X"`) with a one-tap return to the full lesson once mastered, or stepping down the tempo (`"Slow to Y BPM"`).

## Rules

1. **Pure coach recommendation (`SmackAPad/Sources/Scoring/PracticeCoach.swift`, registered in `SmackAPad.xcodeproj`).**
   - Define `enum CoachSuggestion: Equatable, Sendable { case drillBar(barIndex: Int, drillBpm: Int); case slowDown(targetBpm: Int) }` (`barIndex` is 0-based).
   - Pure evaluator `PracticeCoach.recommend(score: Double, totalBars: Int, errorsByBar: [Int: Int], currentBpm: Int, startBpm: Int, bpmStep: Int, isAfterMe: Bool, isMix: Bool, isSectionLoop: Bool) -> CoachSuggestion?`:
     - Return `nil` if `score >= LearningRules.passMark`, `isAfterMe`, `isMix`, or `isSectionLoop` (or `passes == 0`).
     - If `totalBars >= 2`, let `totalBarErrors = errorsByBar.values.reduce(0, +)`. If the worst bar has `>= 2` errors and accounts for `>= 50%` of `totalBarErrors` (`worstErrors * 2 >= totalBarErrors`), return `.drillBar(barIndex: worstBar, drillBpm: max(40, min(currentBpm, max(startBpm, currentBpm - 5))))`.
     - Otherwise, if `currentBpm > startBpm` (or `currentBpm > 50` when `currentBpm == startBpm` and `totalBarErrors >= 2`), return `.slowDown(targetBpm: max(40, currentBpm - max(5, bpmStep)))`.
     - Otherwise return `nil`.
2. **Guided bar-drill lifecycle (`PracticeSession.swift`).**
   - Add `activeCoachDrill: (savedBpm: Int, targetBar: Int, cleanPasses: Int)?` on `PracticeSession`.
   - `startCoachSuggestion(_ suggestion: CoachSuggestion)`:
     - For `.drillBar(let bar, let drillBpm)`: save current `bpm` in `activeCoachDrill`, set `loopStartBar = bar`, `loopEndBar = bar`, set `bpm = drillBpm`, and `restart()`.
     - For `.slowDown(let targetBpm)`: set `bpm = targetBpm` and `restart()`.
   - While `activeCoachDrill != nil`, track consecutive clean passes of that looped bar (`score >= LearningRules.passMark` and 0 errors in that bar). Once `cleanPasses >= 2`, auto-stop the drill and show on `ResultCard` the celebratory status `"Takt %lld zvládnutý!"` / `"Bar %lld nailed!"` with primary button `"Zpět na celou lekci"` / `"Play full lesson"` calling `finishCoachDrillAndRestart()` (restores `loopStartBar = 0`, `loopEndBar = lesson.bars - 1`, `bpm = savedBpm`, clears `activeCoachDrill`, and restarts/prepares the full lesson).
   - Also provide a compact `"Celá lekce"` / `"Full lesson"` exit button in the top bar whenever `activeCoachDrill != nil`, and ensure `close()` or manual loop changes clear `activeCoachDrill` cleanly so the user is never trapped in loop mode.
3. **`ResultCard` integration (`PracticeInstruments.swift`, `PracticeScreen.swift`).**
   - When `coachSuggestion != nil` and `!showNext`, render the coach button (`"Procvičit takt %lld"` / `"Drill bar %lld"` or `"Zpomalit na %lld BPM"` / `"Slow to %lld BPM"`) using `PadPrimaryButtonStyle()` above `"Restart"` (`PadSecondaryButtonStyle(onDark: true)`).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Practice/PracticeSession.swift`, `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift` (`ResultCard`), `SmackAPad/Sources/UI/Practice/PracticeScreen.swift` (`bottomZoneRow`), `SmackAPad/Sources/Progression/LearningRules.swift`.

## Tests

Use `tdd` discipline for `PracticeCoach`: add `SmackAPadTests/PracticeCoachTests.swift` testing `.drillBar` threshold (≥50% errors in one bar & ≥2 errors), `.slowDown` fallback, `nil` on passing/mix/afterMe runs, and `PracticeSession` drill entry + full-lesson restoration after 2 clean passes. Run `-only-testing:SmackAPadTests/PracticeCoachTests` and `-only-testing:SmackAPadTests/PracticeSessionTests`.

## Acceptance criteria

- [ ] Failing a multi-bar lesson mostly in one bar offers `"Drill bar X"` on `ResultCard`; tapping it loops bar X slightly slower.
- [ ] Completing 2 clean passes of the drilled bar stops and offers one-tap `"Play full lesson"`, restoring full bars and prior BPM.
- [ ] Failing with spread-out errors offers `"Slow to Y BPM"`, restarting immediately at the lower tempo.
- [ ] Leaving the lesson or cancelling restores normal state cleanly.
- [ ] Build and tests pass.

### Manual iPad checks for Jakub

Open a 2-bar or 4-bar lesson, intentionally miss notes in bar 2 (tap `"Drill bar 2"`, play 2 clean passes, tap `"Play full lesson"`), then raise BPM high and miss across all bars (verify `"Slow to Y BPM"`).

## Agent assignment

Gemini 4 Neon, thinking **high** (pure `PracticeCoach` formula is fully specified; `high` thinking gives Neon enough care for saving/restoring loop state in `PracticeSession` without spending Carbon quota). Fallback: Claude Sonnet 5.5, medium. Run after 233 (same files).

## Done rule

Build, run tests per `AGENTS.md`, commit on `release-polish`, stop for Jakub's iPad check.
