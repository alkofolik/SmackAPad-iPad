# Proposal — Review auto-stop, third star through Training, Training list order, badge images

Status: proposal for Jakub, 2026-11-07. Tickets 142 and 143 written; §3 and §4 wait for decisions (§6).

## 1. Review runs stop by themselves (ticket 142)

**Problem.** Practice stops automatically only when star 2 or 3 is freshly earned (`StarAward.shouldStop`). A review (ticket 98) earns no star in most cases, so the run loops forever. The verdict (`reviewFeedback`) is already decided after the first hidden pass, but the player only sees it after pressing STOP.

**Rule.** In a due review, the moment `ReviewScheduler` returns `passed`, `settled` or `failed`, the session stops at the end of that pass (same path as `stopAfterStar`) and the result card shows the review sentence big and first:
- passed: "Review passed · next in 3 days" + "Play on" / "Hrát dál" (ordinary practice, does not count) and "Back to Training".
- failed: "Review not passed · again tomorrow" + same buttons.
- settled: "Lesson settled" + the existing star/badge banner if earned.
- `doesNotCount` (below goal tempo, section loop, From memory off) does **not** stop; the status line already says why.

Inside the Today session the stop hands over to the next step (existing hand-off card). Mix keeps its own flow (one run per lesson, its round result).

## 2. Third star through Training

**Today:** star 3 = From memory ≥ 80 % at goal tempo, on a later day than star 2 (ticket 97). The first review (day + 1, From memory, ≥ 80 %, goal tempo) is almost the same test. Two systems ask for the same thing; ticket 132 had to explain the "from tomorrow" rule.

**Idea (Jakub):** star 3 = lesson settled, From memory is part of it.

| Option | Star 3 comes when | Earliest | Pros | Cons |
|---|---|---|---|---|
| **A — first review** | review step 1 passed | day + 1 | almost today's timing; one system | star 3 says little about lasting memory |
| **B — two reviews (recommended)** | review steps 1 and 2 passed (after 1 and 3 more days) | day + 4 | proves the pattern survived several days; still reachable within a week; clear story "star 3 = it holds" | slower than today |
| **C — settled** | all 4 steps (1 + 3 + 7 + 21 days) | day + 32 | strongest meaning | a month per star; a failed review steps back; with hundreds of lessons star 3 becomes very rare |

Recommended B, plus a **settled mark** (small seal next to the three stars, same symbol style as ticket 52) for the full schedule, so C is still rewarded visibly and through the Settled badges.

What changes with B:
- Practice no longer awards star 3. From memory stays in Practice as a practice tool. The star 3 requirement line says "Star 3: two reviews in Training" / "Třetí hvězda: dvě opakování v Tréninku", with progress "1 of 2".
- Earning star 3 is a fresh star in a review run → star animation, auto-stop (§1), badge banner as today.
- Already earned stars 3 stay. Lessons with star 3 but no schedule keep their schedule logic unchanged.
- Stage unlock (star 2) unchanged. Memory badges (`metric memory`) still count stars 3.
- Ticket 97's same-day rule and ticket 132's text become unnecessary and are removed.

## 3. Training lesson list: order, filters, "waiting" lessons

With hundreds of learned lessons the Due list and the review pool grow without limit. Principles: offer only what can count today; hide the rest behind one tap; never lock.

**Due now** (only lessons whose review counts today, playable in the current 8/16 pad mode):
1. Order by risk of forgetting: lowest step first (step 1 is the most fragile), then most days late. Ties: oldest star 2.
2. Show the first 5 rows; "Show all (12)" / "Zobrazit vše (12)" expands.
3. Filter chips above the list (one row, remembered like Library filters): All · Step 1 · Step 2 · Step 3 · Step 4, and a category/style chip if needed later.
4. The daily session (ticket 103) takes the first two of this order.

**Waiting** (reviews not yet due) — not in the main list. Grouped by days to wait, each group a collapsed, tappable box:
- Tomorrow (3) · In 2–3 days (5) · This week (8) · Later (20).
- Reuse the "Next 7 days" strip: tapping a day opens that day's lessons; a "Later" cell is added at the end.
- Opening a waiting lesson is allowed (never lock) but plays as practice; the row says "Review in 3 days · practice only".

**Settled** — one collapsed box "Settled (14)" at the bottom, for voluntary play.

## 4. Badge images

Today a badge is a name, a condition and tier marks. 55 badges in 9 groups.

Proposal: one engraved icon per **group** (9 icons), tier stays as LED dots. Badge tile drawn like a small pad: earned = icon and edge lit in the accent colour, unearned = dim outline, progress bar as today. Three colours only, hardware look.

| Group | Icon idea |
|---|---|
| passed | single drumstick hit / pad with a dot |
| mastered | metronome |
| memory | closed eye / brain outline |
| levels | stairs |
| courses | path / flag |
| genres | vinyl record |
| techniques | two hands |
| training | calendar with check |
| (training sub-icons optional) | mix = shuffle arrows, after me = ear |

Source: SF Symbols (free, sharp, consistent, no licence work) as the default; custom vector icons only where no symbol fits. Before code: an HTML mockup with 2 tile styles, like tickets 135 and 137.

## 5. Suggested tickets

- **142** Review auto-stop (§1) — written.
- 143 Star 3 through reviews (§2), after decision.
- 144 Training list order, filters, waiting boxes (§3), after decision; mockup optional.
- 145 Proposal: badge images, HTML mockup (§4); implementation after Jakub picks.

## 6. Decisions for Jakub

1. Star 3: A, B (recommended) or C?
2. List: is "first 5 + show all" enough, or more/less? Step chips yes/no?
3. Badges: mockup first (recommended) — yes/no?

## 7. Decided (Jakub, 2026-11-07)

- Star 3: **option B** (two passed reviews) → ticket 143.
- Auto-stop rethought to keep the flow: a review is decided by **2 of 3** counted hidden passes. Success stops the lesson (a natural end, like star 2); a failed review does **not** stop, playing simply goes on as practice. Stop before the outcome records nothing. → ticket 142 rewritten.
- Still open: §3 list details, §4 badge mockup.
