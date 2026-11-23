# 219 — Result card: symmetric layout, no icon beside the buttons, detail via a summary row

Status: open. Jakub on 2026-11-22: result card variant **E** of the mockup (design canvas "Smack-a-Pad – návrhy (kolo 22. 11.)", artboard Result) is fine in look, but without the icon next to "Next lesson" and "Again" next to the overall results, and the card must be placed **symmetrically**. Also from the earlier checklist: the result card needs a complete new design (Jakub: "udělej to nějak pěkně").

## Goal

Redo the layout of `ResultCard` (`SmackAPad/Sources/UI/PracticeInstruments.swift`) as three symmetric zones: result on the left, stars and verdict in the middle, buttons on the right. Content and behaviour stay as they are (`EndOfRunCardModel`, star animation, announcements, `openRules`, `openSessionResults`); only the layout and the look of the rows change.

## Rules

1. **Frame.** Dark rounded card as now. Equal inner padding on the left and on the right (about 28 pt), and equal gaps around the two vertical dividers. Three zones separated by thin vertical lines (cream, about 12 % opacity): left (score), middle (stars and verdict), right (buttons).
2. **Left zone.** Score in large condensed bold digits with "%"; under it the "accuracy · BPM" subtitle (as now).
3. **Middle zone** (centred horizontally in its zone): the three stars on top (existing star row and animation), under them the verdict from `model.status.title` (one line, centred), under that a **summary row**: the existing `runsLine` (bars for the bars of the pattern as drawn in the mockup, plus text like "takty 1–4 · 1 průchod · nejlepší 92 %" and a `›`). The whole summary row is the button that calls `openSessionResults` (tap target at least 44 pt tall); it keeps the existing accessibility label and hint ("Shows all runs"). No separate icon button for the overall results.
4. **Right zone.** A column with the primary button ("Next lesson" / "Další lekce", orange, dark text) and below it the secondary button ("Again" / "Znovu", cream outline). **No icon** next to or inside either button. Both buttons have the same width, centred in the zone with the same distance from the card's right edge as the score has from the left edge. Find where these two buttons are currently built (search for "Next lesson" in `PracticeScreen.swift` and the result container) and move them into the right zone of the card layout if they are outside the card now; keep their actions and their conditions (for example "Next lesson" only when it exists).
5. **Not counted variant** (reason from `reviewPendingReason`, including the future `.peeked` from ticket 216): in the middle zone show an eye (or the existing status icon) in place of the stars, the title "Not counted" and one line with the reason; right zone shows a single primary "Again" button. Same symmetric frame.
6. **Compact width** (`cardWidth < 620`, as `isCompactWidth` now): keep the existing stacked fallback but with the same symmetric padding and no icon beside the buttons.
7. The pop-up version for a lesson that stopped itself on a star (variant B in the mockup) uses the same content: large stars, score, verdict, bars, two buttons; build it from the same views, no second copy of the logic.
8. Czech and English; light and dark mode; portrait and landscape. Do not change timing, scoring, star rules or the model.
9. Ticket 209 rule: this view reads only its inputs; do not add per-hit state.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeInstruments.swift` (`ResultCard`, `EndOfRunCardModel`, `EndOfRunLine`), `PracticeScreen.swift` (where the card and its buttons are placed), `docs/tickets/2026-11-22-216-memory-peek.md` (the `.peeked` reason), the tests of `EndOfRunCardModel`.

## Acceptance criteria

- [ ] Left and right padding are equal; the three zones are separated by dividers and look symmetric.
- [ ] No icon beside "Next lesson" / "Again" or the overall-results row.
- [ ] Tapping the summary row opens the overall results exactly as before.
- [ ] Counted and not-counted variants, compact width and the pop-up version all use the new layout.
- [ ] Build and tests pass (existing `EndOfRunCardModel` tests unchanged).

### Manual iPad checks for Jakub

Finish a lesson with a normal result, with a new star, in From memory with a peek (not counted), in portrait and landscape; open the overall results from the summary row.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (layout with several variants). Fallback: Codex GPT-6.1 Sol, high. Run after tickets 212, 215, 216 and 218 (same files), not in parallel with them.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
