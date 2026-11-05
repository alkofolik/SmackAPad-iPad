# 103 — "Today": the hero pad starts a daily session when reviews are due

Status: ready-for-human (implemented; iPad acceptance pending). Depends on: 98 (reviews), 100 (Mix). Source: Jakub, 2026-11-05, option A of `docs/2026-11-05-training-push-proposal.md` §3.1 (Training on the main path, never a lock). Mockup: `docs/design/2026-11-05-training-page/training-page.html` (frames 2 and 3).

## Goal

A player who only taps the big Home pad must still meet their reviews. When reviews are due, the hero pad becomes **TODAY / DNES** and runs a short daily session: reviews first, then the next new lesson, then an optional Mix. Every step can be skipped. Nothing is locked.

## Rules

1. **Today plan** (pure function): input = due lessons (oldest due day first), the next new lesson (same source as Continue today: `progression.nextLesson`), Mix lessons of the day (ticket 100). Output = ordered steps:
   - up to **2** reviews (the rest stay in the Due list on the Training screen),
   - 1 new lesson (left out if there is none),
   - Mix (optional; left out when Mix has fewer than 2 lessons).
2. **Hero pad (Home pad 1)**:
   - At least one review is due and today's plan is not finished → title **"TODAY"** / **"DNES"**, subtitle "%lld reviews · then new lesson" / "%lld opakování · pak nová lekce" (Czech plural forms; with no new lesson: "%lld reviews" / "%lld opakování").
   - Otherwise → exactly today's Continue / Start behaviour.
3. **Running the session**: the hero pad opens step 1 in Practice. A review step opens like the Due row (From memory on, goal tempo, review status line from ticket 98). The new lesson step opens like Continue. The Mix step opens Mix like the Mix card.
4. **Hand-off card**: when the player leaves the Practice screen of a step (back), a card shows:
   - the step's outcome: for a review the ticket 98 result sentence ("Review passed · next in 3 days", "Review not passed · again tomorrow", "Does not count · …"); for a new lesson its best score of the step; for a step left without a full run "Not played" / "Nezahráno",
   - the next step ("Next: Funk 1 · Shuffle (review 2 of 2)" / "Další: Funk 1 · Shuffle (opakování 2 ze 2)"),
   - buttons **Continue** / **Pokračovat**, **Skip** / **Přeskočit** (skips the next step), **Done for today** / **Konec na dnes**.
   - Same card style as the result card (Theme tokens, ticket 94 square corners). Mockup frame 3.
5. **Not today**: a review step skipped with Skip or never started when the player taps Done for today is **postponed**: due day becomes tomorrow, review step unchanged. No penalty, no star change. A pure function in `ReviewScheduler` (`postpone(schedule, today) -> schedule`). A review already played today is not postponed.
6. **End of session**: after the last step the card says "That's enough for today" / "Dnes stačí" with the day's numbers: reviews passed n of m, new lesson best score. Only **Home** / **Domů** button. The hero pad shows Continue again for the rest of the day.
7. **Plan state** is stored per calendar day (`AppCalendar.today()`), e.g. `@AppStorage("smackapad.training.today")` as JSON: day, step list, index, finished flag. A new day starts a new plan. Reopening the app mid-session resumes at the current step.
8. Ticket 107 will add a START button on the Training page that runs this same session; build the session as one reusable piece (not inside `HomeScreen`).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/HomeScreen.swift` (hero pad, `gridContent`), `SmackAPad/Sources/UI/ContentView.swift` (navigation), `SmackAPad/Sources/UI/TrainingScreen.swift` (how Due, Mix and Practice are opened), `SmackAPad/Sources/UI/PracticeScreen.swift` (initial modes, result card style only), `SmackAPad/Sources/Progression/ReviewScheduler.swift`, `SmackAPad/Sources/Progression/TrainingMix.swift`, `SmackAPad/Sources/Progression/Progression.swift` (`nextLesson`), `SmackAPad/Sources/Persistence/Persistence.swift` (`dueLessonIds`), `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Tasks

1. Pure Today-plan function and `ReviewScheduler.postpone`.
2. Session coordinator (reusable), hand-off card, end card, per-day plan storage.
3. Hero pad title and subtitle; texts in `en` and `cs`.
4. Unit tests (only these): plan with 3 due reviews takes the 2 oldest + new lesson + Mix; no new lesson / Mix < 2 drops those steps; no due review → no Today plan; postpone moves the due day to tomorrow and keeps the step; postpone ignores a review played today.

## Acceptance criteria

- [ ] With reviews due, Home pad 1 reads TODAY with the right subtitle; without, it is Continue as before.
- [ ] The session runs reviews → new lesson → Mix with hand-off cards; Skip and Done for today work.
- [ ] Skipped reviews come back tomorrow at the same step; stars untouched.
- [ ] After the last step "That's enough for today" and Home shows Continue for the rest of the day.
- [x] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: with two due lessons, run the whole session once with the MIDI controller; next day skip one review and check it is back.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: a flow across Home, Practice and Mix with stored state; the review rule change must be exact.

## Done rule

Stop after successful build and tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-05

- Added the pure `TodayPlan.make` selection and a reusable `TodaySessionCoordinator` / `TodaySessionScreen`. The daily JSON stores the selected steps, position, hand-off phase, completion and accumulated full-run outcomes; Home resumes that state and returns to Continue after completion.
- Home launches reviews in From memory at goal tempo, followed by the next new lesson and the shared daily Mix. Hand-off and end cards use Theme tokens and square corners, with English and Czech text. Practice's Continue action returns to the hand-off rather than opening an unrelated lesson.
- Added `ReviewScheduler.postpone` and persisted `lastReviewedDay`. Skipped or unplayed reviews move to tomorrow at the same review step; a full review attempt already played today is preserved. Postponement only updates the review schedule, leaving stars and scores intact.
- Validation: `xcodebuild test -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'platform=iOS Simulator,id=BCAE2B5C-6C6F-4607-98FE-A62E2A96F473' -derivedDataPath build/ticket103 -resultBundlePath build/ticket103-results.xcresult -only-testing:SmackAPadTests/TodayPlanTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO` succeeded: **5 tests, 0 failures**, including the app and test-target build. No additional tests were run.
- Remaining: Jakub's iPad acceptance above, including controller playback, hand-offs, relaunch/resume and next-day postponement. Existing unrelated compiler warnings were left unchanged.
