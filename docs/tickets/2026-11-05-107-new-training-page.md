# 107 — New Training page

Status: ready-for-test. Depends on: 103 (daily session), 105 (`ReviewForecast`), 106 (Training badges). Source: Jakub, 2026-11-05, `docs/2026-11-05-training-push-proposal.md` §5. **Mockup (approved direction): `docs/design/2026-11-05-training-page/training-page.html`, frame 1** (open it in a browser; example data only).

## Goal

Replace today's list of three plain cards with a page that says "this is today's plan" and shows what reviews build up. Same visual language as Practice: the orange band is the dominant element, hardware feel, `Theme` tokens only, ticket 94 square corners for chrome (step blocks may use the pad radius, as pads do).

## Layout (landscape, top to bottom)

1. **Today band** (orange, full width): title "TODAY" / "DNES", date and "%lld reviews due" / "%lld opakování na řadě".
   - Three **step blocks** drawn like pads, from the ticket 103 Today plan: Review (count, "from memory at goal tempo"), New lesson (title), Mix ("optional", lesson count). Each has an LED: orange = to do, ink = done today, off = nothing to do.
   - Below: the sentence "Nothing is locked. You can skip any step." / "Nic se nezamyká. Každý krok můžeš přeskočit.", buttons **Not today** / **Dnes ne** (postpones today's reviews, ticket 103) and **START TODAY'S TRAINING** / **START DNEŠNÍHO TRÉNINKU** (runs the ticket 103 session; resumes at the current step).
   - Plan finished: the band says "That's enough for today" / "Dnes stačí" with the day's numbers; START is gone.
   - Nothing due and no lesson with star 2: one block "Learn your first lesson" / "Nauč se první lekci" that opens Continue.
2. **Memory** (left) and **Next 7 days** (right), side by side.
   - Memory: 5 columns — "Learned ★★" (star 2, review step 0 not yet passed), "Step 1", "Step 2", "Step 3", "Settled". Each column: a vertical segment meter of 8 segments, the number, a **one-line** label. All columns top-aligned and equal (Jakub, 2026-11-05). Lit segments = round(count / largest count × 8), at least 1 when count > 0. Settled column lit in orange, the others in ink.
   - Next 7 days: 7 day cells (weekday short name, count from `ReviewForecast`), today outlined, zero counts in the off colour. Caption "Lessons coming back for a review that day." / "Počet lekcí, které se ten den vrátí k opakování."
3. **Due now**: rows with title, stars, chip "STEP 2 OF 4" / "KROK 2 ZE 4", lateness "today" / "dnes" or "%lld days late" / "o %lld dny později" (plural forms). Tap opens as in ticket 98. Empty: the ticket 98 sentences.
4. **Mix** and **Play after me** side by side, equal height: existing logic and buttons from tickets 100 and 101, moved, not changed.
5. **Training badges**: the next three unearned Training badges (ticket 106) with name, condition, "7 / 10" and a progress bar; "All badges ›" / "Všechny odznaky ›" opens the Badges screen. All earned: the three most recent.

## Portrait and accessibility

- Portrait: the same blocks stacked in one column; the three step blocks stay in one row.
- VoiceOver: each step block reads its name, state and detail; the meter reads "Step 2: 3 lessons"; day cells read the full weekday and count.
- Dynamic Type at the app's supported sizes; light and dark; `en` and `cs`.

## Files to read

`AGENTS.md`, this ticket, the mockup file, `SmackAPad/Sources/UI/TrainingScreen.swift`, `SmackAPad/Sources/UI/HomeScreen.swift` (`HomePadView` look for step blocks and LED from ticket 104), the ticket 103 session coordinator, `ReviewForecast` (ticket 105), `SmackAPad/Sources/Progression/BadgeEvaluator.swift` (progress values), `SmackAPad/Sources/UI/BadgesScreen.swift` (navigation only), `SmackAPad/Sources/UI/Components.swift`, `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Tasks

1. Split `TrainingScreen` into section views; keep Mix and Play after me behaviour unchanged.
2. Today band, Memory meter, Next 7 days, Due now rows, Training badges.
3. Portrait layout, accessibility texts, `en` and `cs`.
4. No new tests (counts come from tested functions); build only.

## Acceptance criteria

- [x] The page matches the mockup's structure in landscape and portrait, light and dark.
- [x] START runs the daily session; Not today postpones; the finished state shows "That's enough for today".
- [x] Memory meter columns are aligned with one-line labels; counts match the progress data.
- [x] Next 7 days matches the forecast; Due rows show lateness.
- [x] Mix and Play after me work as before.
- [x] Build succeeds.
- [ ] **iPad test (Jakub)**: compare the page with the mockup; run START once; check portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: mostly layout work against a mockup, reusing logic from 103, 105 and 106.

## Done rule

Stop after successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
