# 50 — Polish: lighter heading weights, one size scale

Status: ready-for-agent. Source: unslop audit, approved by Jakub 2026-11-03.
Blocked by: 47.

## Why

Every title, row title, BPM figure and button uses IBM Plex Sans **Bold** (700). In the Library, the lesson name and "112 BPM" have the same weight and compete. Hierarchy should come from size and colour, with weight 500, and 600 only for the one key figure and the primary action.

The bundled variable font `IBMPlexSans[wdth,wght].ttf` already contains the named instances `IBMPlexSans-Medium` (500) and `IBMPlexSans-SemiBold` (600). No new font file is needed.

## Changes (`SmackAPad/Sources/UI/Theme.swift`)

1. `display(_:)`: use `"IBMPlexSans-Medium"` instead of `"IBMPlexSans-Bold"`.
2. Add a new function next to it:
   ```swift
   /// The one key figure and the primary action label.
   static func strong(_ size: CGFloat) -> Font {
       _ = verifiedFonts
       return .custom("IBMPlexSans-SemiBold", size: size, relativeTo: .headline)
   }
   ```
3. Tokens:
   - `mainValue = strong(44)`
   - `action = strong(22)` (was `display(24)`)
   - `screenTitle`, `sectionTitle`, `rowTitle` stay `display(...)` with the same sizes (they become Medium through step 1).
4. `canvasDisplay(_:)` stays **Bold**. The pad labels inside the orange band (HH, SN, KD) are the printed labels of the instrument and keep their weight.
5. `verifiedFonts`: check `["IBMPlexSans-Regular", "IBMPlexSans-Medium", "IBMPlexSans-SemiBold", "IBMPlexSans-Bold"]`.

## Changes in other files

| File | Find | Replace with |
|---|---|---|
| `LibraryScreen.swift` | `sidebarLabel`: `(selected ? Theme.display(22) : Theme.navigation)` | `Theme.navigation` — the selected row is already shown by its background; growing the text on selection makes the row jump |
| `TempoUpBanner.swift` | `Theme.display(28)` | `Theme.strong(28)` (the banner is a key moment) |

Leave `Theme.display(28)` and `Theme.display(32)` in `PracticeComponents.swift` as they are (they become Medium; that is intended).

Resulting scale on screens: 44 · 28 · 22 · 18 · 16 (plus 32 for pad labels in the band and 12 for keyboard keycaps).

## Files to read

`AGENTS.md`, this ticket, `Theme.swift`, `LibraryScreen.swift` (function `sidebarLabel` only), `TempoUpBanner.swift`.

## Acceptance criteria

- [ ] The app starts (the `precondition` in `verifiedFonts` passes, so all four faces load).
- [ ] Titles are Medium, the big BPM and primary buttons SemiBold, band pad labels still Bold.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: Library, Practice, Settings, result, in Czech (diacritics) and English, light and dark. Check that nothing now truncates.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), low thinking.

## Done rule

Stop after a successful build; do not commit.
