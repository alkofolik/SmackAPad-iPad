# 204 — One training place: the Today session screen goes into Training

Status: ready-for-agent. Decided by Jakub on 2026-11-13 (iPad review, photos 3 and 4). Blocked by: 201, 202.

## Goal

Today there are two places for the same day: the Training screen (photo 3, orange TODAY band with tiles) and a separate Today session screen (photo 4, a row of step cards plus the last result and "Continue to …"). After each lesson the app jumps to the second one, which feels like a different menu, and its step cards have uneven heights. Keep only Training; show the result after each lesson as a pop-up card over it.

## Rules

1. **Training is the only day screen.** After any day step (review, new lesson, mix) ends, the app returns to Training, and a result card pops up over it.
2. **The result card** (same visual family as ticket 203's card): score and stars (or the 202 reason), lesson name, a short success or retry line, then the next step: primary "Continue to <next step>", secondary "Skip" and "Done for today". If nothing is left: primary "Summary". Tapping outside does nothing; the card has a close (×) that just leaves you on Training.
3. **The TODAY band is the step strip.** Its tiles show done / current / upcoming exactly as the old step cards did. All tiles have the same height; extra text truncates or moves into the result card, never adds a row to one tile.
4. **Delete `TodaySessionScreen`** (`TodaySessionScreen`, `TodayStepperView`, `masterConsole`, and their routes in `AppNavigation`) once its logic lives in Training. Move the session model at the top of that file (`record`, `skip`, `finish`, `advance`, …) to its own file if Training needs it; do not duplicate it. Delete tests that only exercise the deleted screen's layout; keep and adapt tests of the session logic.
5. Extra mix and "Play after me" keep working from Training as now.
6. Navigation: back from practice still goes to Training (no extra screen in between). Continue on Home still works (ticket 190 must not regress).
7. Portrait and landscape.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/TrainingScreen.swift`, `TodaySessionScreen.swift`, `AppNavigation.swift`, `PracticeScreen.swift` (how it returns), `SmackAPad/Sources/Progression/TodayPlan.swift`, `docs/tickets/2026-11-11-182-training-merge-and-day-summary.md`, `docs/tickets/2026-11-13-203-mix-summary-popup.md` (card style).

## Tests

Adapt existing session-logic tests to the moved model. Add one: after a step is recorded, the next action offered is the next unplayed step, or Summary when none is left.

## Acceptance criteria

- [ ] After every day step you land on Training with a result card; the old Today session screen never appears.
- [ ] TODAY band tiles are equal height and show done / current / upcoming.
- [ ] Continue to next step, Skip, Done for today and Summary all work.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Play a whole day from Training; you never see the old screen with the row of cards.
- Home → Continue in the middle of a day still works.

## Agent assignment

Codex GPT-6.1 Sol, thinking **high** (navigation and state move across screens). Fallback: Gemini 3.8 Flash, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
