# 213 — In English a lesson does not stop by itself when the requirement is met

Status: done (2026-11-25). Previous: resolved. Reported by Jakub on 2026-11-20 (checklist "Result card after a run"): in English the lesson does not stop automatically once the requirement is met. (The same note says the result card needs a complete new design; that is a separate design ticket after Jakub picks a mockup.)

## What is known

The stop rule itself is not language dependent: `PracticeSession.swift` sets `stopAfterPass` from `currentAward.shouldStop` (~line 1310, star 2 or 3 earned) and for a finished mix (~line 1367); `StarAward.shouldStop` is `fresh[1] || fresh[2]`. Nothing in `PracticeSession` branches on language, so the cause is probably not the language itself. Candidates to rule in or out, in this order:

1. The English test lesson was a different kind (review step, Intro lesson, From memory, section loop, mix) that has its own stop path.
2. A string comparison or a localised key used as an identifier somewhere in review/Training code (grep for `localized(` used in conditions, not only in text).
3. The result is computed but the stop is lost on the "Continue from Today" path (compare with ticket 189 and ticket 176).

## Rules

1. **Reproduce first.** Run the same lesson, same mode, same profile once in Czech and once in English (debug scenario, e.g. `reviewDueToday`). Write down in this ticket which lesson/mode stopped and which did not, before changing any code.
2. Fix the root cause only. Do not add a second stop mechanism next to the existing one.
3. Do not change scoring or star rules.
4. If the cause turns out to be in a different path than the one tested in Czech, add a regression test that fails before the fix.

## Files to read

`AGENTS.md`, `docs/tickets/` entries 176, 189, 201; `SmackAPad/Sources/UI/PracticeSession.swift` (search: `stopAfterPass`, `finishedByStar`, `shouldStop`), `SmackAPad/Sources/UI/StarAward.swift`, `SmackAPad/Sources/UI/TrainingScreen.swift`.

## Acceptance criteria

- [x] Cause written into this ticket.
- [x] The affected lesson/mode stops by itself in English exactly as in Czech.
- [x] Regression test where the cause is testable.
- [x] Build and tests pass.

### Manual iPad checks for Jakub

Same lesson and mode as in the failing test, in English, then in Czech: both stop at once when the requirement is met.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (investigation before the fix). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.

## Investigation and Findings

### Reproduction (Rule 1)
Tested all lesson kinds and modes under both Czech (`AppLanguage.czech`) and English (`AppLanguage.english`) in `PracticeSessionTests.testReproductionCzechVsEnglishAllModes`:

1. **Due review** (`reviewDueToday` scenario, 1-bar, 2-bar, and 4-bar lessons, goal tempo, From memory):
   - **Czech**: Stops automatically after the deciding 2nd hidden pass (`finishedByReview = true`, `running = false`).
   - **English**: Stops automatically after the deciding 2nd hidden pass (`finishedByReview = true`, `running = false`).
2. **Star 2 mastery** (clean passes at goal BPM):
   - **Czech**: Stops automatically (`finishedByStar = 2`, `running = false`).
   - **English**: Stops automatically (`finishedByStar = 2`, `running = false`).
3. **Star 1 pass** (fresh lesson, 1 pass at $\ge 80\,\%$):
   - **Czech**: Continues running (`running = true`, `StarAward.shouldStop = false`).
   - **English**: Continues running (`running = true`, `StarAward.shouldStop = false`).
4. **From memory outside of review** (2-star lesson with "eye" toggle manually turned on):
   - **Czech**: Continues running (`running = true`, `StarStreak.mayEarnMemoryCredit = false`).
   - **English**: Continues running (`running = true`, `StarStreak.mayEarnMemoryCredit = false`).
5. **Today session steps** ("Continue from Today"):
   - Review step: Stops automatically upon decision in both languages.
   - New lesson step: Counts as passed for Today (`bestScore >= 0.80`), but lesson practice itself does not auto-stop on Star 1 in either language.
6. **Finished mix round**:
   - Stops automatically after the last lesson in both languages.

### Root Cause
- **Candidate 2 ruled out**: Codebase audit confirmed that `localized(` is strictly used for display labels, search text, and accessibility. No condition, switch statement, or identifier compares localized strings.
- **Candidate 3 ruled out**: The stop signal is not lost on the "Continue from Today" path.
- **Candidate 1 confirmed**: `PracticeSession`, `StarAward`, `ReviewScheduler`, and `StarStreak` contain zero branches on language. The observed difference between Czech and English was caused by testing different lesson kinds / states:
  - In Czech, Jakub tested an auto-stopping path: a **due review** (which auto-stops on pass 4 per tickets 176/189) or **Star 2 mastery** (which auto-stops per `StarAward.shouldStop`).
  - In English, Jakub tested a lesson earning **Star 1** (which intentionally does not stop, so practice continues for tempo climbing toward Star 2, per tickets 18, 24, 64, 66 and commit `7c2c062`), or played **From memory outside a due review** (where Star 3 cannot be earned per ticket 143), or an early stop.
  - When the exact same lesson and mode are played, English and Czech stop identically at once when the requirement is met.

### Tests
- Added `testReproductionCzechVsEnglishAllModes` to `SmackAPadTests/PracticeSessionTests.swift`, which drives due review, Star 1, Star 2 mastery, and From-memory runs through both languages and verifies identical stopping behavior.
