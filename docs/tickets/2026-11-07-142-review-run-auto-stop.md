# 142 — A review run stops by itself and shows its verdict

Status: ready-for-agent. Source: Jakub, 2026-11-07. Proposal: `docs/2026-11-07-training-stop-star-list-badges-proposal.md` §1.

## Problem

Practice stops automatically only when star 2 or 3 is freshly earned (`stopAfterStar`, `StarAward.shouldStop`). A due review usually earns no star, so the lesson keeps looping. The review verdict (`reviewFeedback`, `PracticeSession.swift` ~899–925) is decided after the first hidden pass, but the player sees it only after pressing STOP.

## Rules

1. When a due review gets the outcome `passed`, `settled` or `failed`, stop at the end of that pass through the existing `stopAfterStar` path (do not invent a second stop path; a shared flag such as `stopAfterVerdict` checked at the same places is fine).
2. `doesNotCount` never stops.
3. Not in Mix (Mix keeps its own flow) and not in After me.
4. The result card shows the review sentence first and larger than the score (existing texts: "Review passed · next in %lld days", "Lesson settled", "Review not passed · again tomorrow"). Buttons: "Play on" / "Hrát dál" (starts again as ordinary practice; the review for today is already used) and the existing back control to Training.
5. If the same pass also earns a fresh star, the star animation plays as today; one stop only.
6. In the Today session the stop leads to the existing hand-off to the next step.
7. No changes to scoring, timing, `ReviewScheduler`, stars or the schedule.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeSession.swift` (~160–170, ~555–630, ~640–665, ~785–800, ~895–1025), `SmackAPad/Sources/UI/StarAward.swift`, `SmackAPad/Sources/UI/PracticeScreen.swift` (result card, ~120–140), `SmackAPad/Sources/UI/TodaySessionScreen.swift` (hand-off only), both `Localizable.strings`.

## Acceptance criteria

- [ ] Due review, From memory at goal tempo: after the counted pass the lesson stops and the card says passed / failed / settled.
- [ ] Below goal tempo or From memory off: no stop, status line unchanged.
- [ ] "Play on" restarts as practice; no second review is recorded that day.
- [ ] Today session continues to the next step after the stop.
- [ ] Czech and English texts. Build succeeds; existing tests still pass, no new tests.
- [ ] **iPad test (Jakub)**: one passed and one failed review with the MIDI controller.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: small, but it touches the stop timing inside the practice session.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
