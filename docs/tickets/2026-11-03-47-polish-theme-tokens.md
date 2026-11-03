# 47 — Polish: new Theme tokens (lines, active fill, radii, control heights, motion)

Status: ready-for-agent. Source: unslop audit by Claude, direction approved by Jakub on 2026-11-03.
Blocked by: the uncommitted work of tickets 38, 39 and 42 must be committed first (Jakub decides).

## Why

The UI is mostly well designed, but small values drift: four different line opacities, three different orange fills for "active", radii 2/3/6/7/12, control heights 48/50/54/60 and one bouncy spring. This ticket only **adds tokens and changes Theme.swift**. Tickets 48 and 49 apply them across the screens.

## Direction (for every polish ticket 47–53)

- Product: a trainer for finger drummers who play patterns on a MIDI pad controller and get timing feedback per bar.
- Character: hardware-like, exact, a bit raw.
- World: the front panel of a drum machine: black chassis, rubber pads, printed labels, sequencer step lights.
- Keep: orange / black / white, IBM Plex Sans, all screens, layouts and features. Polish only.

## Changes (only `SmackAPad/Sources/UI/Theme.swift`)

1. Add colour tokens inside `enum Theme`, next to `surface`:
   ```swift
   /// One hairline for every divider and outline in the chrome.
   static let hairline = ink.opacity(0.15)
   /// One fill for an active or selected control.
   static let activeFill = orange.opacity(0.24)
   ```
2. Star colours: in `starColor(for:)` return `orange` for 1, 2 and 3 stars (delete the light-orange and medium-orange branches). 0 stars keeps the grey. The number of filled stars already says how many; three orange shades make none of them lead.
3. Add a radius enum inside `enum Theme`:
   ```swift
   enum Radius {
       /// Buttons, fields, chips, banners.
       static let control: CGFloat = 4
       /// Pads and cells: touch pads, calibration pad, learn slots.
       static let pad: CGFloat = 8
   }
   ```
   Keep `Size.blockRadius` for now but set it to `Radius.control` (`static let blockRadius: CGFloat = 4`). Do not change `PracticeBandStyle.radius`.
4. Add control heights to `enum Size`:
   ```swift
   /// Compact row or button.
   static let row: CGFloat = 48     // same as touch
   /// Large row or primary button.
   static let rowLarge: CGFloat = 56
   /// Two-line list row (lesson rows).
   static let listRow: CGFloat = 60
   ```
5. Motion: replace `static let emphasis = Animation.spring(response: 0.4, dampingFraction: 0.8)` with `static let emphasis = Animation.easeOut(duration: 0.4)`. Do not change any caller.
6. Leave the backup file `Theme.swift.bak-2026-11-02` alone; Jakub decides about it separately.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/Theme.swift`.

## Do not

- Do not edit any other file. Do not rename existing tokens. Do not change fonts (ticket 50).

## Acceptance criteria

- [ ] The tokens above exist with exactly these values.
- [ ] Stars with 1, 2 or 3 earned use the same orange; 0 is grey.
- [ ] No `.spring(` left in Theme.swift.
- [ ] Build passes; do not run tests (see AGENTS.md).

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), low thinking. Alternative: Codex GPT-6.1 Sol, low.

## Done rule

Stop after a successful build; do not commit. Claude commits afterwards.
