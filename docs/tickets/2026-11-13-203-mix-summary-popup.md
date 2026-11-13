# 203 — Mix summary as one clean pop-up card

Status: ready-for-agent. Decided by Jakub on 2026-11-13 (iPad review, photo 6). Blocked by: 202 (reuses its reason text).

## Goal

At the end of the last mix lesson the practice screen shows an inline panel under the band with every lesson's name, stars, percentage, "Bars: 4 not measured" and long sentences. It is crowded and looks unfinished. Replace it with one modern, calm pop-up card.

## Rules

1. **When:** after the last lesson of a mix ends (daily mix or extra mix). Not after lessons 1 and 2 (they keep the pause from ticket 180).
2. **The card:** centred over the dimmed practice screen, `Theme` card style, max width about 560 pt.
   - Title: "Mix done" / "Mix hotový", and under it the overall mix score in large type.
   - One row per lesson: number, name, stars, and either the score or the reason text from ticket 202. Same height for every row, a single line each (truncate the name if needed).
   - No "Bars: N not measured" anywhere. Delete that string and its code if nothing else uses it.
   - The bar-chart button moves into the card as a small "Details" link that opens the existing per-bar view, only if that view exists today; otherwise drop it.
   - Buttons at the bottom: primary "Next" (same target as today's Next), secondary "Restart mix".
3. **Delete the inline panel** and its layout code from the practice screen. No dead code.
4. Opening animation: a short fade and scale (≤ 0.25 s); respects Reduce Motion (fade only).
5. Accessibility: the card is a modal; VoiceOver focus starts on the title; each row reads "Lesson name, 2 stars, 97 percent".
6. Portrait and landscape: the card fits without scrolling for up to 5 lessons.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (end-of-mix panel, Next / Restart), `PracticeInstruments.swift` (`EndOfRunStatus`), `PracticeSession.swift` (mix results), `Components.swift`, `Theme.swift`, the reason builder from ticket 202.

## Tests

None beyond the full suite (UI only).

## Acceptance criteria

- [ ] After the last mix lesson a single centred card shows the results; the old inline panel is gone.
- [ ] No "Bars: … not measured" text in the app.
- [ ] Next and Restart mix work from the card.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Finish a daily mix and an extra mix, in landscape and portrait. Does the card feel clean and clear?

## Agent assignment

Gemini 3.8 Flash, thinking **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
