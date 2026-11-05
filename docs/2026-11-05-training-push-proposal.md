# Proposal — Make Training part of the main path, Training badges, new Training page

Status: proposal for Jakub, 2026-11-05. No tickets yet. Builds on tickets 97–101 (memory star next day, Due reviews, fading hints, Mix, Play after me).

## 1. Why players skip Training today

- The hero pad **Continue** always opens the next *new* lesson. Training is a side pad; a player who only taps Continue never meets a review.
- Reviews have no visible reward: stars 1–3 come from Practice; "settled" is only a small mark in Library.
- Mix and Play after me save nothing (Play after me is "practice only"), so they feel optional.
- The Training screen is three plain cards in a list; it does not say "this is today's plan".

## 2. What the legacy tool did (concept 2026-10-06, redesign 2026-10-07, review 2026-10-09)

- **"Today's training" card on Home**, next to "Your next step": four steps (New lesson, Review, Mix, Check game) with Play / Not today / Start, and the sentence "Nothing is locked".
- **Daily session of 10–15 minutes**: recall (1–2 learned lessons from memory) → new lesson → Mix → closing summary with "That's enough for today".
- **Due count** shown on Home and in Library ("Due for review: 1") only when something is due.
- Hard rule: **never lock**. Every suggestion can be declined. No streaks or XP as the motor (research note: chasing points and streaks crowds out learning).
- Lesson learned on 2026-10-09: the player could not find how to start a review, nor tell whether a run counted. Tickets 98–99 already fixed the second part.

Conclusion: legacy pulled players in by **putting Training on the main path** (Home card, daily session), not by locking. We keep "never lock a lesson" but can be firmer than legacy (option B below).

## 3. Pull the player into Training

### 3.1 Continue becomes "Today" when something is due (strongest lever, no lock)

- When reviews are due, the hero pad reads **TODAY / DNES** with the subtitle "2 reviews · then new lesson" and opens a **daily session**: due reviews (max 2 per session), then the next new lesson, then an optional Mix.
- Between steps a short hand-off card: "Review 1 of 2 passed · next in 3 days" → "Next: new lesson <title>" with Start / Skip.
- Nothing due → Continue behaves exactly as today.
- Skipping is always possible ("Not today" moves the review to tomorrow, no penalty).

### 3.2 Decision for Jakub: how firm?

| Option | What it does | Feel |
|---|---|---|
| **A — soft** | Only 3.1 + visible reminders (3.3). New lessons always open. | Legacy-like, friendly. |
| **B — firm (recommended)** | A, plus: the **next stage opens** only when at least half of the current stage's two-star lessons have passed **one review**. Single lessons stay open; only the stage gate changes. Edition and purchase rules unchanged. | Training is needed to move up, but no single lesson is ever blocked. |
| **C — strict** | A, plus: max 3 new lessons per day while reviews are overdue. | Effective, but risks annoying a player in a good flow. |

### 3.3 Reminders where the player already looks

- Home Training pad: **lit LED** (orange fill on the pad edge, hardware metaphor) when reviews are due; count in the subtitle (exists).
- Result card after earning star 2: "Comes back tomorrow for a review" — sets the expectation at the moment of success.
- Library lesson row: small "due" mark next to the settled mark.
- Optional local notification (opt-in in Settings, off by default): "2 lessons due for review", once a day at a time the player picks.

### 3.4 Make Mix and Play after me count

- Mix and Play after me record a small training log per day (rounds played, best Play after me score per lesson). Used for badges and the page's "this week" strip; stars and reviews stay untouched.

## 4. Training badges (new group "Training" / "Trénink")

Rules: cumulative counters only, **never a streak that breaks**, never lost. Earned through the existing badge banner (ticket 78).

| Id | Name EN / CS | Condition |
|---|---|---|
| `review-first` | Comeback / Návrat | Pass your first review. |
| `review-ten` | Regular / Pravidelně | Pass 10 reviews. |
| `review-fifty` | Long memory / Dlouhá paměť | Pass 50 reviews. |
| `settled-first` | Settled / Upevněno | Settle your first lesson (all 4 review steps). |
| `settled-ten` | Solid ground / Pevná půda | Settle 10 lessons. |
| `settled-fifty` | In the hands / V rukou | Settle 50 lessons. |
| `bounce-back` | Bounce back / Zpátky na nohy | Pass a review the day after a failed one. |
| `mix-first` | Shuffle / Zamíchej | Finish a full Mix round (each lesson once). |
| `mix-memory` | Blind mix / Mix naslepo | Finish a Mix round From memory, every run ≥ 80 %. |
| `mix-twenty` | Juggler / Žonglér | Finish 20 Mix rounds. |
| `after-me-first` | Echo / Ozvěna | Score ≥ 80 % in a Play after me response. |
| `after-me-ten` | Good ear / Dobré ucho | Score ≥ 80 % in Play after me on 10 different lessons. |
| `training-days-10` | Ten sessions / Deset tréninků | Train on 10 different days (any review, Mix or Play after me). |
| `training-days-50` | Fifty sessions / Padesát tréninků | Train on 50 different days. |

Needs: new metrics in `BadgeEvaluator` (reviews passed, settled count, bounce-back, Mix rounds, Play after me lessons ≥ 80 %, training days) and the small training log from 3.4. Old progress files: settled and review counts can be derived from existing fields where possible; the rest starts at zero.

## 5. New Training page

Same visual language as Practice: the orange band is the dominant element, hardware feel, three colours, ticket 94 shapes. Landscape first.

```
┌──────────────────────────────────────────────────────────────────────┐
│ ‹ Home                     TRAINING                        Settings  │
├──────────────────────────────────────────────────────────────────────┤
│ ORANGE BAND — "Today"                                                │
│  [1 REVIEW  2 due ●●]  [2 NEW LESSON  Funk 3]  [3 MIX  3 lessons]    │
│        ✓ / to do / nothing — pad-like blocks, LED = state            │
│                                         [ START TODAY'S TRAINING ]   │
├───────────────────────────────┬──────────────────────────────────────┤
│ MEMORY                        │ NEXT 7 DAYS                          │
│ ★★ learned  step1 step2 step3 │  Mo Tu We Th Fr Sa Su                │
│ ▮▮▮▮▮▮      ▮▮▮   ▮▮   ▮      │  2  ·  1  ·  ·  3  ·   (reviews)     │
│ settled 4                     │                                      │
├───────────────────────────────┴──────────────────────────────────────┤
│ DUE NOW   (rows: title · stars · step 2 of 4 · 3 days late · Play)   │
├──────────────────────────────────────────────────────────────────────┤
│ MORE PRACTICE   [ Mix  · New mix · From memory ]  [ Play after me ]  │
├──────────────────────────────────────────────────────────────────────┤
│ TRAINING BADGES  next 3 with progress bars  · "All badges ›"         │
└──────────────────────────────────────────────────────────────────────┘
```

- **Today band**: three step blocks drawn like pads (label, count, LED dot for done / to do / nothing). One START runs the daily session from 3.1. After the last step the band shows "That's enough for today" / "Dnes stačí" with today's numbers.
- **Memory meter**: segmented bar (hardware LED meter) of lessons per review step, ending in "settled". This is the visible progress that reviews create.
- **Next 7 days**: small strip with review counts per day; tells the player when to come back.
- **Due now**: today's list (exists in ticket 98), plus "days late" and a Play button per row.
- **More practice**: Mix and Play after me as two equal blocks (exist), less prominent than Today.
- **Training badges**: the next three unearned Training badges with progress, link to the Badges screen.
- Empty states: no star-2 lesson yet → the band shows one block "Learn your first lesson" that opens Continue.
- Portrait: the same blocks stacked; the band's three steps stay in one row.

Recommendation: a visual mockup (HTML in the scratchpad or images) before the ticket, so Jakub can judge the page on screen.

## 6. Suggested tickets (after Jakub's decisions)

1. Daily session: Continue → Today, hand-off cards, "Not today" (3.1).
2. Stage gate by reviews, if option B (3.2).
3. Reminders: lit Training pad, result-card line, Library due mark (3.3). Notification as a separate optional ticket.
4. Training log + Training badges (3.4, 4).
5. New Training page (5), after the mockup is approved.

## 7. Decisions and open questions

Decided by Jakub, 2026-11-05:
- Badge list (4): enough for now, keep as is.
- Local notification: **yes** (opt-in, off by default).
- Mockup: Claude's choice, must be easy to view → HTML mockup published as a private page (`docs/design/2026-11-05-training-page/training-page.html`).

- Firmness (3.2): **option A** (soft, no stage gate). The mockup was updated to match.
- Memory meter: one-line labels, columns aligned.

Tickets: 103 (daily session), 104 (in-app reminders), 105 (notification), 106 (Training log and badges), 107 (new Training page). Order: 103 → 104 → 105 → 106 → 107.
