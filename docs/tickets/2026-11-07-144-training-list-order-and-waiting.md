# 144 — Training: order the Due list, step filter, waiting lessons behind tappable boxes

Status: ready-for-agent. Source: Jakub, 2026-11-07, approved `docs/2026-11-07-training-stop-star-list-badges-proposal.md` §3 ("first 5 + show all" and step chips: yes).

## Goal

With hundreds of learned lessons the Training page must stay short. The main list offers only reviews that can count **today**; lessons that must still wait are grouped by days behind tappable boxes; settled lessons sit in one box at the bottom. Nothing is ever locked.

## Due now

1. Candidates: `progress.dueLessonIds(today:)` (as today), **plus** two filters it lacks now: playable in the current pad mode (16 pads, or `EightPadLayout.slots(for:) != nil` in 8-pad mode) and open in the player's edition/stage (same `openIDs` test as Mix, `TrainingScreen.swift` ~1088).
2. Order (one pure function next to `ReviewForecast`, e.g. `ReviewQueue.order`): lowest `reviewStep` first (step 1 is the most fragile), then most days late, then the earlier `masteryDay`, then lesson id.
3. Show the first **5** rows; below them "Show all (%lld)" / "Zobrazit vše (%lld)"; expanded, the button reads "Show fewer" / "Zobrazit méně". Not remembered.
4. **Step chips** in one row above the list: All · Step 1 · Step 2 · Step 3 · Step 4 ("Vše · Krok 1 …"), single choice, look like the Library filter chips (ticket 138). Remembered across launches like the Library filters. A chip with zero lessons is shown disabled. The chip filters only this list.
5. The daily session (ticket 103, `TodayPlan.make`) and the Today band take their due lessons in this same order (first two), unaffected by the chip.

## Waiting (reviews not yet due)

1. New panel "Waiting" / "Čeká" under Due now, collapsed boxes in one row (wrap in portrait): **Tomorrow (3)** · **In 2–3 days (5)** · **In 4–7 days (8)** · **Later (20)** / "Zítra · Za 2–3 dny · Za 4–7 dní · Později". Boxes with zero lessons are hidden; the panel is hidden when all are zero.
2. Tapping a box expands it in place (one open at a time) and lists its lessons: title, stars, "Step 2 of 4", "Review in 3 days · practice only" / "Opakování za 3 dny · jen cvičení". Order: soonest first, then the Due-now order.
3. Same pad-mode and open filters as Due now.
4. **Next 7 days strip**: each day with a count becomes tappable and opens the box that contains that day; days with zero stay plain. No new cells in the strip.
5. Tapping a waiting lesson opens Practice normally (no review mode, nothing pre-set). Practice already treats it as not due.

## Settled

One collapsed box at the bottom of the page: "Settled (14)" / "Upevněné (14)". Expanded: settled lessons by title, tap opens Practice normally. Hidden when zero.

## Unchanged

Review rules and schedule, Mix, Play after me, the Memory meter, badges, the page's look (`Theme` tokens, ticket 133 buttons).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/TrainingScreen.swift` (data build ~1080–1125, Next 7 days ~605–660, Due now ~686–790), `SmackAPad/Sources/Progression/ReviewForecast.swift`, `SmackAPad/Sources/Persistence/Persistence.swift` (`dueLessonIds`, `LessonProgress` review fields), `SmackAPad/Sources/UI/TodaySessionScreen.swift` and the `TodayPlan` file (order only), `SmackAPad/Sources/UI/LibraryScreen.swift` (filter chip look and how filters are remembered), both `Localizable.strings`.

## Acceptance criteria

- [ ] Due now: only lessons playable today in the current pad mode, step 1 first; 5 rows, then "Show all".
- [ ] Step chips filter the list and are remembered; empty chips are disabled.
- [ ] Waiting boxes show the right counts; tapping opens the lessons; strip days open their box.
- [ ] Settled box lists settled lessons.
- [ ] Daily session uses the new order.
- [ ] Czech and English; landscape and portrait. Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: with several learned lessons, check the order, the chips and the boxes.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: list logic and layout on one screen; no timing or scoring.

## Done rule

Run after 142 (same screen area may change) or any time if 142 is done. Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
