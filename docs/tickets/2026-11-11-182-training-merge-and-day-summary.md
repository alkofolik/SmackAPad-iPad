# 182 — One Training screen (Today + Training merged) and a new day summary

Status: ready-for-agent (after 181; before or after 180, but not in parallel — both touch TrainingScreen). Approved by Jakub on 2026-11-11 (points 10, 12, 18 and canvas comment).

Design reference: `docs/design/2026-11-11-screen-redesign/Training.dc.html` (artboard 7) and `DaySummary.dc.html` (artboard 6).

## Goal

Today and Training already share the same plan and mix (`TodayPlan`, `smackapad.training.dailyMixes`), so everything counts together, but the app shows it twice and the player does not understand the difference. Make it one screen. Also replace the plain-text day summary with a clear one.

## Rules

### A. Training screen (single place)
- Header: back arrow, "Training" / "Trénink", date on the right.
- **Today panel** (orange, radius 24, top): "DNES / TODAY" (Barlow), then one row: three step cards + the **Continue** button as a fourth column. **The button has exactly the same height as the step cards and sits in their row** (canvas comment). Step cards: 1 Reviews (cream, check when done, "1 passed · 1 tomorrow"), 2 New lesson (current step = cream with 3 pt black inner border and "now"), 3 Mix (optional, dashed outline). Continue (black, cream text, 200 pt wide) starts the current step; sub-line = what it starts.
- Below, two equal cards side by side: **Extra mix** (From memory toggle top right, the three lessons, "Another mix" + "Start mix" — this opens the mix line-up from ticket 180) and **After me** (lesson + stars, one-line description, "Another lesson" + "Start"). Buttons in both cards are the same size (secondary left, primary right).
- Then three collapsible rows (60 pt, chevron): Review queue (count, opens the queue), Memory and next 7 days (expands in place: the current Memory and 7-day forecast panels), Training badges (count, opens Badges filtered).
- The old separate Today session screen header ("To je pro dnešek vše" orange box) is removed; the Today flow (step after step) still runs from Continue, using `TodaySessionScreen`'s logic.
- Doing a review or the mix from either card counts exactly once (as today, ticket 158 A6 reconciliation stays).

### B. Day summary (end of the Today plan)
- Left: black panel (radius 24): orange check tile, "HOTOVO NA DNEŠEK / DONE FOR TODAY" (Barlow, two lines), date, three tiles: Reviews "1 / 2", New lesson "100 %" (orange), Mix "100 %".
- Right: vertical timeline of the steps, each with a circle (orange with check = done, outlined with "!" = not counted), kind ("1 · REVIEW"), lesson name, % on the right; a not-counted step gets one small chip "again tomorrow" / "znovu zítra". No sentences like "Výsledky najdeš níže".
- Bottom right: "Extra mix" (secondary) and "End training" / "Konec tréninku" (primary), same size.

### General
- Three colours, Plex/Barlow, tokens, motion doc, English drum names. Portrait: Today panel stacks (steps 2 × 2 with Continue full width), cards stack.

## Files to read

- `AGENTS.md`, the two design files
- `SmackAPad/Sources/UI/TrainingScreen.swift`, `TodaySessionScreen.swift`, `HomeScreen.swift`, `Progression/TodayPlan.swift`, `TrainingMix.swift`
- `docs/tickets/2026-11-09-158-*.md` (A6)

## Tests

Existing TodayPlan / mix tests must pass unchanged. Add a test that starting a review from the Today panel and from the review queue on the same day counts once. Full suite.

## Acceptance criteria

- [ ] One Training screen as described; no separate Today screen header.
- [ ] Continue button aligned with the step cards and of their height.
- [ ] New day summary with timeline and tiles.
- [ ] Counting unchanged; build and full suite pass.

### Manual iPad checks for Jakub

Home pad Today → Training → Continue through the steps → day summary. Then start a review from the queue: it does not count twice.

## Agent assignment

Codex GPT-6.1 Sol, **high** (merging two screens without breaking counting). Fallback: Gemini 3.8 Pro, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
