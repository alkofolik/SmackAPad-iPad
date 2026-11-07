# 142 — A review is decided by 2 of 3 hidden passes and stops only on success

Status: ready-for-human. Source: Jakub, 2026-11-07. Proposal: `docs/2026-11-07-training-stop-star-list-badges-proposal.md` §1.

## Problem

Today a due review is decided by a single hidden pass (`ReviewScheduler.evaluate`, `PracticeSession.swift` ~899–925), and the player sees the verdict only after pressing STOP, because Practice stops by itself only for a fresh star 2 or 3 (`stopAfterStar`). One pass is too fragile (one slip = failed review), and a stop after every verdict would break the playing flow.

## Rules

1. **Review window.** A review is decided over the first **3 counted passes** of the day: full runs (no section loop), From memory, at ≥ goal tempo, hidden (with fading notes on: pass ≥ 3, as today). Passes that do not count (`doesNotCount`) are skipped and do not use up the window.
2. **Pass = 2 of 3** with score ≥ 80 %. The outcome is decided as soon as it is certain:
   - 2 successes → **passed** (or **settled** on the last step). Stop at the end of that pass through the existing `stopAfterStar` path (one shared stop path; a flag like `stopAfterVerdict` checked at the same places is fine).
   - 2 failures → **failed** (one step back, due tomorrow). **No stop.** Playing continues as ordinary practice; the status line quietly switches to "Review not passed · again tomorrow · practice goes on" / "Opakování nesplněno · znovu zítra · hraješ dál".
3. While the window is open, the status line shows progress: "Review · 1 of 2 passed" / "Opakování · splněno 1 ze 2" (and a fail count only if useful: keep one short line).
4. STOP before the outcome is certain → nothing is recorded, schedule unchanged (the window starts again next time today). Overdue reviews carry no penalty, so this is acceptable.
5. Still one review per lesson per day: after a decided outcome, further runs that day are ordinary practice.
6. Result card after the success stop: review sentence first and larger than the score ("Review passed · next in %lld days" / "Lesson settled"), buttons "Play on" / "Hrát dál" (practice only) and the existing back control. A fresh star in the same pass plays its animation; one stop only.
7. Today session: the success stop leads to the existing hand-off. A failed review does not stop; the hand-off button stays available as today.
8. Mix: each appearance of a due lesson in a Mix is one counted pass of that lesson's window (the window lives across rounds that day). Mix never stops for a review; its round result shows the review line per lesson. After me unchanged (never a review).
9. No changes to scoring, timing, review gaps or star thresholds.

## Implementation notes

- Keep the window state per lesson per day in the session (lesson id → successes, failures); for Mix keep it across rounds in the same session. No persistence needed (rule 4).
- `ReviewScheduler` gets a pure function: window state + one pass result → new window state + optional final outcome. **Use the tdd skill** (it decides a review).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Progression/ReviewScheduler.swift`, `SmackAPad/Sources/UI/PracticeSession.swift` (~160–170, ~230–270, ~555–665, ~785–800, ~895–1025), `SmackAPad/Sources/UI/StarAward.swift`, `SmackAPad/Sources/UI/PracticeScreen.swift` (status line, result card ~120–140), `SmackAPad/Sources/UI/TodaySessionScreen.swift` (hand-off only), both `Localizable.strings`.

## Tests (only these)

Pure window function: S S → passed after 2 passes; F F → failed after 2; S F S → passed after 3; F S F → failed after 3; `doesNotCount` does not advance the window; last step + 2 successes → settled.

## Acceptance criteria

- [ ] Due review: two good hidden passes → lesson stops, card says passed (or settled).
- [ ] Two bad hidden passes → no stop, line says not passed, playing goes on; review is due tomorrow.
- [ ] Below goal tempo / From memory off / section loop: window does not move.
- [ ] STOP mid-window records nothing.
- [ ] Mix records the window per lesson and never stops for it.
- [x] Czech and English texts. Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: one passed and one failed review with the MIDI controller; is the flow uninterrupted enough?

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: changes how a review is decided and the stop timing inside the practice session, including Mix.

## Done rule

Run before ticket 143. Stop after successful build and tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-07

- Added the pure `ReviewScheduler.advanceWindow` reducer, with in-session windows keyed by lesson and day. Only a decided majority updates the persisted schedule and review log. STOP discards an undecided attempt on the next start; Mix retains its windows across live rounds.
- Successful reviews use the shared automatic stop path, including simultaneous star awards. Failed reviews continue playing with a quiet status line. The success result card leads with the review verdict and offers Play on; Today retains its existing Continue hand-off.
- Mix results include each lesson's review progress or verdict. Removed the screen's premature last-reviewed write, so incomplete attempts leave the review schedule unchanged. Added English and Czech copy.
- Validation: the first requested test failed before the reducer existed, then passed. The remaining five requested tests passed separately, with zero failures; the already-passing test was excluded. Final iPad simulator build and selected tests succeeded. Logs: `.build/ticket142-green-ss.log`, `.build/ticket142-final.log`.
- Physical iPad/MIDI acceptance remains for Jakub. No additional tests were run.
