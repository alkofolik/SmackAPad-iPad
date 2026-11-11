# 176 — Bug: a review run does not stop after the review is met

Status: ready-for-agent. Approved by Jakub on 2026-11-11 (feedback round of 20 screenshots, point 15).

## Goal

When a lesson is played as a review (From memory, goal tempo) and the review requirements are met, the run stops by itself, exactly like it does after earning the 2nd or 3rd star. Today the lesson keeps looping and Jakub cannot tell that he is done.

## What Jakub saw

- Lesson "Kick na každou dobu" (Intro, 1 bar, 80 BPM, only Kick), opened from the **Library** with the subtitle "Opakování · začni zpaměti" (review due, ticket 158 path).
- He played From memory at 80 BPM (= goal tempo), several passes, the HUD showed 94 % and then 100 %.
- The run never stopped by itself; it kept repeating until he pressed STOP.

## Rules

1. Reproduce first, in the simulator, with the `reviewDueToday` debug scenario (ticket 160): a short 1-bar Intro lesson, opened (a) from the Library, (b) from the Home pad, (c) from Today/Training. Write down which of the three fails.
2. Find the cause. Places to check (`PracticeSession.swift`):
   - the review branch around line 1100–1135 sets `stopAfterPass = true` only when `decision.outcome?.feedback` is `.passed`/`.settled`. Check whether short lessons (minimum ~16 hits, several runs) ever produce an outcome, or whether `ReviewScheduler.advanceWindow` keeps waiting;
   - whether the warm-up rule (`LearningRules.firstHiddenMemoryPass`) is counted per run or per lesson start, and whether `pass.number` resets for every loop of a 1-bar lesson;
   - whether the lesson launched from the Library really has `fromMemory == true` and the goal tempo when the run starts (ticket 158).
3. Fix it so that the run stops after the pass in which the review is met, from all three launch places. Use the same end-of-run handling as the 2nd/3rd star stop (result card, no abrupt cut, `finishedByReview`).
4. Do not change the review rules themselves (warm-ups, minimum runs, 80 % pass mark), except where ticket 177 changes them.

## Files to read

- `AGENTS.md`
- `SmackAPad/Sources/UI/PracticeSession.swift`
- `SmackAPad/Sources/Progression/ReviewScheduler.swift`, `LearningRules.swift`, `StarStreak.swift`
- `docs/tickets/2026-11-09-158-*.md`, `docs/tickets/2026-11-09-160-*.md`

## Tests

Add a unit test that drives a short (1-bar) due review through enough qualifying hidden passes and asserts that the session asks to stop (`stopAfterPass`/`finishedByReview`). Run the full test suite.

## Notes

- **Reproduction (`reviewDueToday`, `iPad (A16)` simulator & code trace)**:
  - Tested all three launch places for 1-bar Intro lesson `10001` ("Kick on every beat", `targetBpm: 80`):
    1. **Library** (`LibraryScreen.open` via `LessonLaunch.library`)
    2. **Home pad** (`HomeScreen` pad 1 `TODAY` -> `TodaySessionScreen`, pad 2 `LIBRARY` / pad 4 `INTRO` / pad 1 `CONTINUE` -> `LibraryScreen`)
    3. **Today / Training** (`TodaySessionScreen`, `TrainingScreen.dueLessonRow`)
  - All three launch paths reliably start `PracticeSession` with `fromMemory == true` and `bpm == 80`, and all three do set `stopAfterPass = true`, `finishedByReview = true`, and present `ResultCard` after `pass.number == 4` (Bar 16).
- **Root cause**:
  - On 1-bar lessons (`repeatsPerRun = 4`), `PracticeSession` combines 4 bars into each scored pass (`pass.number`). With `fadeMemoryNotes == true` (`LearningRules.firstHiddenMemoryPass = 3`, `LearningRules.reviewDecisionPasses = 2`, left untouched per ticket rules), Passes 1–2 (Bars 1–8) are treated as visible-note warm-ups and Passes 3–4 (Bars 9–16) are the deciding hidden passes.
  - However, `PracticeScreen` passed 1-bar `frame.pass` to `PracticeSession.noteVisibility(pass:)`, and `ScrollingPattern` in `PatternField.swift` passed 1-bar `recordedPass` to `NoteVisibility.derive(...)`. Consequently, on `10001`, Bar 1 was `.shown`, Bar 2 was `.faded`, and Bars 3–4 of Pass 1 plus all 4 bars (Bars 5–8) of Pass 2 were already `.hidden`, while the HUD still labeled them as Pass 1 shown / Pass 2 fading and `ReviewScheduler` discarded Pass 1 (`94 %`) and blind Pass 2 (`100 %`) as warm-ups—forcing the loop through 8 more hidden bars before stopping after Pass 4.
- **Fix**:
  - `PracticeSession.swift`: added `runNumber(for:)` and `noteVisibility(at:)`, and reused `runNumber(for:)` in `runMeterFraction(at:)`.
  - `PracticeScreen.swift`: switched to `session.noteVisibility(at: frame)`.
  - `PatternField.swift`: passed `runBars` into `ScrollingPattern` and derived `visibilityPass` from `runTotal` (`runBars * 16`) so note fading aligns with scored 4-bar runs (Bars 1–4 `.shown`, Bars 5–8 `.faded`, Bars 9–16 `.hidden`).

## Acceptance criteria

- [x] Cause found and described in the ticket's notes.
- [x] A due review stops by itself once met, from Library, Home pad and Today/Training.
- [x] New test passes; the full suite passes.

### Manual iPad check for Jakub

Debug scenario `reviewDueToday` → open "Kick na každou dobu" from the Library → play From memory at goal tempo → the run stops by itself and shows the result.

## Agent assignment

Codex GPT-6.1 Sol, **high** (logic across session, scheduler and launch paths). Fallback: Gemini 3.8 Pro, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
