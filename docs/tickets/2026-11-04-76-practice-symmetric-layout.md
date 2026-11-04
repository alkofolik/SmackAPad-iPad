# 76 — Practice: symmetric three-zone layout (landscape and portrait)

Status: ready. Source: Jakub, 2026-11-04 (photos 5–9): "Tidy the practice page up so it is symmetric: the band dominant in the middle, empty space above and below it, everything else either fully at the top or fully at the bottom, fields aligned, nothing sticking out." Run before ticket 77 (both touch `PracticeScreen.swift`). Read the rules of `design-taste-frontend` only; do not run its scripts.

## Target layout

Three zones, all sharing the same left and right edge (the band's outer edge, `Theme.Space.page` from the screen edge). Every box in a zone lines up with these edges; boxes in one row have equal height.

```
┌ TOP ───────────────────────────────────────────────────────┐
│ [Library]  Title                      [Listen|Play] tools… │
│            ●●○○○ · 1 bar                                   │
├ MIDDLE (flexible, band vertically centred) ────────────────┤
│                    (empty)                                 │
│ ████████████████ band ███████████████████████████████████  │
│ Early ────────── timing bar ────────────────────── Late    │
│                    (empty)                                 │
├ BOTTOM ────────────────────────────────────────────────────┤
│ ┌────────┐            ┌────────┐            ┌────────┐     │
│ │ pads   │            │  80    │            │ STOP   │     │
│ │ layout │            │  BPM   │            │────────│     │
│ │ 4×4    │            │ → 94   │            │Restart │     │
│ └────────┘            └────────┘            └────────┘     │
└────────────────────────────────────────────────────────────┘
```

### Top zone
- Row 1: Library button, title, then on the right Listen/Play and the tool icons (as today).
- Subtitle under the title: replace "Eighth-note grooves · Level 1" with the difficulty dots used in the library rows (same component as `LibraryScreen.difficulty`), then " · ", then the bar count of the lesson ("1 bar" / "2 bars", cs "1 takt" / "2 takty" / "5 taktů", plural rules in `Localizable.stringsdict` if present, otherwise as the library rows do it). VoiceOver: "Difficulty 1 of 5, 1 bar".
- The tempo box moves out of the top zone (see bottom).
- The small vault flag / star moment indicator (ticket 66) stays at the top right edge of the middle zone, above the band, inside the band's width.

### Middle zone
- Band, then the timing bar directly under it. The band keeps its current size rules. The leftover height is split equally above and below this pair (band + timing bar are vertically centred in the zone).
- Nothing else lives here: no result card, no run chips, no status text. (Ticket 77 places results in the bottom zone.)
- Remove the "From memory · notes hide once you start" text (`sessionStatus` memory case). The other `sessionStatus` texts ("Preparing sound…", "This lesson requires 16 pads.") show centred inside the tempo square instead of the number until ready.

### Bottom zone — three equal squares
- One row, three squares of the same side length `s`, left square aligned to the left edge, right square to the right edge, middle square exactly centred. `s` = the Stop+Restart stack height (two transport buttons of the current height plus `Theme.Space.small` between them), so the transport pair forms a square.
- **Left square: pad layout** (`PadLayoutGrid`), scaled to fill `s × s`. When the pad layout is turned off (tool button), the square stays empty but keeps its size, so nothing moves.
- **Middle square: tempo.** Bordered like the other instrument boxes. Big, bold, monospaced current BPM (at least 2× today's tempo number, `Theme` display font, `.contentTransition(.numericText)`), "BPM" under it, "→ 94" (goal) under that in meta font. Tapping opens the existing tempo popover (`tempoControls`); disabled while running exactly as today, with the same dimmed look. VoiceOver: "Tempo 80 BPM, goal 94, button".
- **Right square: transport.** Stop (or Start) on top, Restart below, each full square width, `Theme.Space.small` gap, together exactly `s` high. After a run, the single "Again" button keeps the same square footprint (ticket 77 fills the result area).
- No empty filler boxes, no buttons hanging outside the squares.

### Portrait
- Top zone wraps to two rows: row 1 Library + title; row 2 Listen/Play and the tool icons, starting at the left edge and ending at the right edge (spread, not squeezed left). Nothing scrolls horizontally.
- Middle zone as in landscape.
- Bottom zone: same three squares, `s` computed from the available width if it would otherwise not fit (`3s + 2·gap ≤ width`).
- **With the big touch pads on** (`touchPadsInPortrait`, the pad-layout tool): the three-square row stays (left square shows the mini layout or is empty), and the big `PracticeTouchPadGrid` goes under it, aligned to the same left/right edges. The band then uses what is left; it must never be pushed off screen. Toggling the pads (photo 9) must not change the top zone or the square row.
- Today's portrait break (tools row starting mid-screen, tempo box squeezed, Again button not aligned with the grid) must not happen.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeScreen.swift` (`body`, `practiceContent`, `header`, `tools`, `tempoControls`, `footer`, `footerContent`, `sessionStatus`, `transport`), `SmackAPad/Sources/UI/PracticeComponents.swift` (`TransportControls`, `PadLayoutGrid`, `PracticeTouchPadGrid`, `InstrumentButtonStyle`), `SmackAPad/Sources/UI/LibraryScreen.swift` (`difficulty` only), `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] Landscape: band centred with equal empty space above and below; three equal squares at the bottom aligned to the band edges.
- [ ] Subtitle shows difficulty dots and bar count; "Level 1" text gone.
- [ ] Tempo number big, bold, readable; tempo popover still works; locked while running.
- [ ] "From memory · notes hide…" text gone.
- [ ] Portrait with and without big touch pads: no horizontal overflow, tools row spans full width, squares aligned.
- [ ] Nothing jumps when a run starts or stops.
- [ ] Cs and en; light and dark; Dynamic Type up to the size the screen supported before.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: landscape and portrait, pads on and off, a full run to the result.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking: the most important screen, layout shared with portrait and the touch grid. If the layout still breaks in portrait after one fix, hand over to **Codex GPT-6.1 Sol, high**.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
