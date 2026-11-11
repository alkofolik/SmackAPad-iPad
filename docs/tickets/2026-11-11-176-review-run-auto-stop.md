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

## Acceptance criteria

- [ ] Cause found and described in the ticket's notes.
- [ ] A due review stops by itself once met, from Library, Home pad and Today/Training.
- [ ] New test passes; the full suite passes.

### Manual iPad check for Jakub

Debug scenario `reviewDueToday` → open "Kick na každou dobu" from the Library → play From memory at goal tempo → the run stops by itself and shows the result.

## Agent assignment

Codex GPT-6.1 Sol, **high** (logic across session, scheduler and launch paths). Fallback: Gemini 3.8 Pro, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
