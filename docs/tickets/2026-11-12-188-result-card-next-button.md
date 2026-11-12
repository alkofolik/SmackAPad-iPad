# 188 — Result card: the empty black "Next" box after a finished review

Status: ready-for-agent. Reported by Jakub on 2026-11-12 (screenshot of the result card after a passed review, landscape, black rectangle above Restart).

## Problem

After a review run finishes (for example "Kick and hat together", 100 %, "Review passed · next in 3 days") the bottom-right corner shows two buttons: an empty black box and "Restart". The black box is the **Next** button (`TransportControls.resultBody`, `PracticeComponents.swift`). It is disabled because `transportSquare` in `PracticeScreen.swift` sets `eligibleForNext = false` when `session.finishedByReview` is true and the lesson was not started from a Today step. A disabled `PadPrimaryButtonStyle` button is black on black, so the label is invisible and it looks like a bug. It is not a useful control in that state.

## Rules

1. A disabled button must never look like an empty box. Two cases:
   - **Nothing sensible to go to** → do not show Next at all; Restart takes the full result area height (same size logic as the single Start/Stop button).
   - **Something sensible to go to** → show an enabled Next (see 2).
2. After a review that was opened from the Library, Home pad or the review queue and finished (passed): Next opens the **next lesson due for review today** if there is one, otherwise the next lesson on the path (existing `nextLesson` logic), otherwise Next is hidden (rule 1). It must launch exactly like the other launch places (review ⇒ From memory + goal tempo, ticket 158) and respect the lock/purchase check already used by `openNextLesson`.
3. A failed or non-counting review: no Next (hidden), Restart stays.
4. Inside a Today/Mix step the behaviour stays as it is now (Next reports the step result).
5. Keep three colours only, no new visible text; reuse the existing "Next" label and icon.
6. Czech and English, landscape and portrait (portrait uses the stacked result card from the last fix, do not undo it).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (`transportSquare`, `nextLesson`, `openNextLesson`), `PracticeComponents.swift` (`TransportControls`), `Progression/ReviewQueue` / `ProgressStore.dueLessonIds`, `docs/tickets/2026-11-09-158-*.md`.

## Tests

Unit test for the "which next target" decision (extract it into a small pure function): passed review with other due reviews → next due; none due → path lesson; nothing → hidden; failed review → hidden.

## Acceptance criteria

- [x] No empty black box on any result card.
- [x] After a passed review from Library/Home/queue, Next goes to the next due review, else the next path lesson, else it is hidden.
- [x] Build, full test suite and localisation validation pass.

### Manual iPad checks for Jakub

`reviewDueToday` scenario: pass a review from the Library (landscape + portrait, Czech) and read the result card; a passed ordinary lesson still shows Next; a failed run shows only Restart.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
