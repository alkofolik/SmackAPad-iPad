# 179 — Practice: HUD in fixed places, pass line under the band, new end-of-run card, help legend

Status: ready-for-agent (after 178). Approved by Jakub on 2026-11-11 (points 1, 7, 8, 11, 14, 15 and canvas comments).

Design reference: `docs/design/2026-11-11-screen-redesign/PracticeRunning.dc.html` (artboard 2), `PracticeResult.dc.html` (artboard 3), `HelpLegend.dc.html` (artboard 10). HTML mockups with inline sizes, 1194 × 834 pt.

## Goal

While drumming, every piece of information has one fixed place, so Jakub never has to search. After the run, the result is shown by one modern card instead of the current text strip.

## Rules

### A. HUD positions while running (focus mode from 165/171 stays)
- **Top left**: current BPM, large (171 sizes). Nothing else there.
- **Top right, right edge aligned with the band's right edge**: the lesson-requirements progress (the existing 165 run meter / review progress: warm-ups with the eye symbol, counted passes, current %). Directly **below it and just above the orange band**, also right-aligned: the timing cue (165 B1, "rushing/dragging"). Both keep their 171 sizes.
- Remove the floating result chip that appeared at odd places (screenshots 7 and 14) and the text "Pass 2 · notes fading" / "Průchod 2 · noty mizí" (the eye symbols in the meter carry that).
- The tempo-up banner (171 A) appears in the top-left area next to BPM, never over the band or the meter.

### B. Pass progress line
- The thin "how much of this pass is left" line moves **below the band, with a small gap (about 12 pt), across the full width of the band**, with bar ticks.
- It is not attached to the band any more, so its reset at the end of a pass cannot look like the band jumping. At the pass boundary the fill does not snap back: the old fill fades out (≈150 ms) while the new one starts from 0. Reduce Motion: instant.

### C. End-of-run card (replaces the current summary strip)
- Shown after STOP or after an automatic stop, in the bottom area where the pad grid and BPM tile sit (left of the transport buttons), height ≈ 168 pt, radius 20, filled `Theme.black`, cream text.
- Content left to right: big % (64 pt bold) with "accuracy · 105 BPM" below; three stars 44 pt (a newly earned star gets a soft orange halo, one short pop animation from the motion doc); status line with a check icon ("Review passed" / "Opakování splněno", "Passed", "Not counted", …) plus small chips (e.g. "next in 3 days", "New badge: …" in orange); at the right an icon button (bar-chart icon, 56 pt, outlined) that opens the existing run detail.
- No underlined text links anywhere.
- The orange band stays visible above, dimmed to ~55 %.
- Transport on the right becomes **"Next" / "Další"** (primary, orange) and **"Restart" / "Znovu"** (secondary), both the same size, 12 pt gap. "Next" opens the next lesson (same rule as today's next-lesson button); in Mix it goes to the next lesson's ready screen (ticket 180).
- The card hides when the player presses START or Restart.

### D. Help card "Lesson screen" (point 11)
- Rewrite the "Lesson screen" help topic (ticket 169) as a two-column list: number badge (orange circle) + the real icon + 1–4 words, optional small second line. Items: 1 Mode (Listen · Play · After me), 2 From memory (notes hide after 2 good passes in a row — wording from ticket 177), 3 Scrolling / static view, 4 Bars shown, 5 Section loop (practice, no stars), 6 Lesson info, 7 Pad legend, 8 Help, 9 Settings, 10 Tempo (tap to change), 11 Start · Stop · Restart.
- No paragraph text in this card. English and Czech.

### General
- Three colours, Plex, `Theme.swift` tokens, motion from `docs/design/2026-11-01-motion-proposals.md`. No new UI text beyond the status/chip strings above (reuse existing keys where they exist).
- Check: 1–4 bars, scrolling/static, Listen, From memory, review, Mix, portrait, narrow window, Czech.

## Files to read

- `AGENTS.md`, the three design files above
- `docs/tickets/2026-11-10-165-practice-hud-and-focus.md`, `docs/tickets/2026-11-11-171-practice-hud-followups.md`
- `SmackAPad/Sources/UI/PracticeScreen.swift`, `PracticeInstruments.swift`, `PracticeComponents.swift`, `HelpDeck.swift`, `HelpIllustration.swift`, `Theme.swift`

## Tests

If a layout/priority helper is extracted, one unit test. Full suite.

## Acceptance criteria

- [ ] BPM top left; requirements progress and timing cue top right, right-aligned to the band, just above it.
- [ ] Pass line below the band, full band width, no visual jump at the pass boundary.
- [ ] New end-of-run card as described; "Next" and "Restart" only.
- [ ] Help "Lesson screen" is the numbered icon list.
- [ ] Build and full suite pass.

### Manual iPad checks for Jakub

1. Play a lesson: watch the band at every pass boundary — no jump.
2. Earn a star and stop: card shows %, stars, status, detail icon; "Next" opens the next lesson.
3. Open help → Lesson screen: clear list.

## Agent assignment

Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Flash, high. Part D can go separately to Gemini 3.8 Flash, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
