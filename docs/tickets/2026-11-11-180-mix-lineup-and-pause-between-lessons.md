# 180 — Mix: line-up before the start and a pause before every next lesson

Status: ready-for-agent (after 178 and 179; builds on ticket 168). Approved by Jakub on 2026-11-11 (points 1, 8, 9 and canvas comments).

Design reference: `docs/design/2026-11-11-screen-redesign/MixLineup.dc.html` (artboard 4) and `MixNext.dc.html` (artboard 5).

## Goal

Today a mix starts the next lesson straight after the previous one, so Jakub has no time to look at the next pattern, its pads or tempo, or to try it. New flow: see all lessons first, try any of them, then play them one by one with a stop in between.

## Rules

### A. Line-up screen (before the mix)
- Opens when a mix is started from Training (and from the Today mix step). Back arrow returns there.
- Header: "Daily mix" / "Denní mix", second line "3 lessons · 4 bars each".
- One card per lesson, in a row (3 per row in landscape, scroll horizontally or wrap for more; 1 column in portrait). **All cards the same height; title at the top, tags and buttons aligned at the bottom across all cards; only the mini pattern moves, centred in the space between** (canvas comment).
- Card content: number circle, lesson name (max 2 lines), small kind ("Review"), mini pattern (orange, one row per pad with the English pad name and 16 small cells per bar, cream = hit), tags: BPM (black) and pad names, two equal buttons: **Listen** (plays the lesson once, unscored) and **Try** (opens the lesson in normal unscored practice; back returns to the line-up).
- Bottom bar (black, radius 20): From memory toggle on the left, "Another mix" (outline) and **"Start mix"** (orange, wide) on the right.
- Trying or listening does not count for the mix or reviews.

### B. Pause before each next lesson
- After a lesson in the mix ends, the mix does **not** start the next lesson. The practice screen opens the next lesson in its normal stopped state: pattern visible, tempo can be changed, Listen/Play/From memory set as the mix requires.
- Above the band on the left: a small chip with the previous lesson's result ("✓ 1 · Groove, přechod a zpět · 92 %").
- Above the band on the **right** (canvas comment): mix progress chip, black, "MIX 2 / 3" + three segments (done = cream, current = orange, waiting = grey). The title shows only the lesson name.
- Transport: **"Start"** (orange) and **"Skip"** / **"Přeskočit"** (secondary), same size. Start begins the count-in.
- After the last lesson the mix finishes by itself as in ticket 168 and shows the day summary (ticket 182) or the mix result.
- Keep 168's round results, counting and saving exactly as they are; only the hand-over between lessons changes.

### General
- Three colours, Plex, tokens, motion doc. English drum names (ticket 178). Portrait, narrow window, Czech.

## Files to read

- `AGENTS.md`, the two design files
- `docs/tickets/2026-11-10-168-mix-auto-finish.md`
- `SmackAPad/Sources/UI/TrainingScreen.swift`, `TodaySessionScreen.swift`, `PracticeSession.swift` (`isMix`, `mixNeedsAdvance`, `mixIndex`), `PracticeScreen.swift`, `LessonPatternStrip.swift`, `Progression/TrainingMix.swift`

## Tests

Session test: after lesson 1 of a mix ends, the session is stopped with lesson 2 loaded and does not start until `start()` is called; Skip moves on without a result. Full suite.

## Acceptance criteria

- [ ] Line-up screen with equal cards, aligned titles/buttons, Listen and Try.
- [ ] No automatic start of the next lesson; pattern and tempo available before Start.
- [ ] Mix progress chip on the right, previous result chip on the left.
- [ ] Mix results, reviews and saving unchanged (168 tests still pass).
- [ ] Build and full suite pass.

### Manual iPad checks for Jakub

Start a mix → look at all cards, try one → Start mix → after lesson 1 the next one waits with its pattern visible → change tempo → Start → finish → result.

## Agent assignment

Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
