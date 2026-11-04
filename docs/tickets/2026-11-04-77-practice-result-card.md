# 77 — Practice: one clear result card, last run only while playing, run log on tap

Status: ready. Blocked by: 76. Source: Jakub, 2026-11-04 (photos 5, 10): "I can't see the run results at that place while playing. Don't show them all one by one, only the last run, and then a result I can tap open with everything listed. Put the stars and the detail elsewhere with a better, modern icon. Remove the gap. Make the overall result modern instead of hidden at the side." Replaces the run log row of ticket 68 (keep its data).

## Rule

### While playing
- Show **only the last finished run**: one chip ("84 %", "96 BPM", pass mark, same palette as ticket 68) at the top right of the middle zone, next to the vault flag, inside the band's width, where the eyes already are. It cross-fades to the new run when the next result is known. Reserved size, so nothing moves. Hidden in listen mode.
- Remove `RunLogRow` from under the band.

### After STOP / run end — result card
- The result card takes the **left two thirds of the bottom zone** (left square + gap + tempo square from ticket 76) as one box with exactly that width and height `s`, so its edges line up with the squares. The right square keeps the transport (Again, and below it Next lesson / "From memory for ★3" as the second button in the same square). No other free space in the bottom row.
- Card content, left to right:
  - **Score**: big bold percent of the last run (same size class as the tempo number), "Last run" / "Poslední běh" under it.
  - **Stars**: the three stars in a row, filled/outlined as today, star-rule popover on tap (as `showingStarRules`).
  - **Run log summary**: "8 runs · best 100 %" / "8 běhů · nejlepší 100 %" in meta font, with a chevron.
- Tapping the card (or the chevron) opens a sheet/popover **"Session results" / "Výsledky sezení"**: all runs of the session as a vertical list (run number, score, BPM, pass mark), newest first, then the existing detail content (`runDetails`: passes, best score, explanation, `HitTimingPlot`). This replaces the old detail button (the underlined check-mark icon) — remove that icon.
- Keep the badge text and the star animation from ticket 66 inside the card.
- The middle zone stays clean after STOP (band + timing bar only, or band alone if the timing bar is hidden after a run as today; the empty space must stay symmetric).

### Data
- Use the per-session `runResults` array from ticket 68. Best = max score in it.

### VoiceOver
- Card: one element, "Result 100 percent, 2 of 3 stars, 8 runs, best 100 percent", hint "Shows all runs". Last-run chip: "Last run 84 percent, 96 BPM, passed".

## Files to read

`AGENTS.md`, this ticket, ticket 76, `SmackAPad/Sources/UI/PracticeScreen.swift` (`result`, `resultActions`, `runDetails`, `starRules`, `nextLessonControl`, `memoryChallengeControl`), `SmackAPad/Sources/UI/PracticeComponents.swift` (`RunSummary`, `SummaryStrip`, `RunLogRow`, `TransportControls`), the file defining `ResultCard`, `SmackAPad/Sources/UI/PracticeSession.swift` (`runResults` only), `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] While playing only the last run is visible, near the band; nothing moves when it updates.
- [ ] After STOP: card aligned with the squares, big score, stars, run summary; no empty gap in the bottom row.
- [ ] Tap opens all runs plus the old detail content; old detail icon gone.
- [ ] Next lesson and "From memory for ★3" still reachable, inside the transport square.
- [ ] Landscape and portrait; cs and en; light and dark; Reduce Motion.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: several runs with one bad, then STOP and open the results.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking. Fallback: **Codex GPT-6.1 Sol, high** if the card does not line up with the squares after one fix.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
