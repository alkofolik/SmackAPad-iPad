# 227 — Review: show the "tried, not met yet" state in the app (UI)

Status: done. Requested by Jakub on 2026-11-23.

## Goal

Everywhere a review is shown, Jakub can see what he has met and what is missing, and a failed attempt reads as "tried today, not met yet, you can still do it today", not as finished or postponed.

## Rules

1. **Practice screen, during the run.** While the lesson is a due review (including after a failed attempt) the counter "x of 2" stays visible and starts from 0 again after each failed decision. After a failed decision a short status line appears and the run keeps going. Suggested texts (use `localized`, add English and Czech): "Not met yet · keep playing" / "Zatím nesplněno · hraj dál".
2. **After the review is passed**, the run stops (already true) and the result card says it is met. If Jakub starts the lesson again the same day, the line says "Review met today" / "Opakování dnes splněno" and no counter is shown. It is plain practice.
3. **End-of-run line when Jakub stops with an open failure:** "Review not met yet · you can still pass it today" / "Opakování zatím nesplněno · dnes ho ještě můžeš splnit". Never "unfinished" for a decided review: replace `unfinishedReview` wording where it can follow a decision, and clear `reviewPendingReason` when a decision is made.
4. **Daily practice (Today plan).** A review step with an open failure today has its own status "tried, not met yet" (orange, not green, not "did not count"). It does not block the plan: Jakub can continue to the next step and come back. The summary counts it as tried, not passed and not postponed. `reconcilingReviews` must recognise `lastReviewFailDay == day` without `lastReviewedDay == day`.
5. **Library, Training and Home lists:** a lesson with an open failure today shows "Tried today · not met yet" instead of the waiting-until-tomorrow subtext, and stays in the due list (`TrainingScreen.swift` ~line 1088 and ~1586).
6. **Help texts** in Czech and English mention that a failed review stays open for the day.
7. Reuse the existing review line and step status components. No new screen, no new colour.

## Files to read

`AGENTS.md`, ticket 226, `PracticeSession.swift` (`reviewRunProgress`, `reviewPendingReason`, `reviewFeedback`), `PracticeInstruments.swift` (~line 715–800, 916–960), `PracticeScreen.swift` (~line 968, 1333, 2055–2075), `TodayPlan.swift` (`PracticeStepOutcome`, `reviewSummary`), `TrainingScreen.swift` (~1088, 1586), help texts in the localization inventory (search only).

## Tests

None beyond a small test for the Today step status mapping (open failure becomes "tried, not met yet"). Text and layout: build only. Read the design-taste-frontend rules only.

## Acceptance criteria

- [x] Counter is visible through a failed attempt and a retry.
- [x] Texts match rules 1–3 in Czech and English.
- [x] Today plan, Training and Library show the new state, nothing says "postponed".
- [x] Build and tests of the area pass.

### Manual iPad checks for Jakub

Same flow as ticket 226. Check what the practice screen, the result card, the Today plan and the lesson list say after a failed attempt, after a pass and after stopping with an open failure.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run tests per `AGENTS.md`, commit, stop for Jakub's iPad check.
