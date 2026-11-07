# 140 — Home pad titles: Barlow Condensed ExtraBold

Status: implemented; build OK; ready for iPad test. Depends on: 119 (controller body), 135 (font proposal). Source: Jakub, 2026-11-07: selected Barlow Condensed ExtraBold from ticket 135 preview ("líbí se mi 3 - barlow").

Spec = preview `docs/previews/135-pad-title-fonts.html` (candidate 3: Barlow Condensed ExtraBold).

## What to build

1. **Font asset**:
   - Bundle `BarlowCondensed-ExtraBold.ttf` (SIL Open Font License 1.1) in `SmackAPad/Resources/Fonts/`, plus its licence text as `barlowcondensed-OFL.txt` next to it (like `ibmplexsans-OFL.txt`).
   - **Where to get the file (no download needed):** the TTF is embedded as base64 in `docs/previews/135-pad-title-fonts.html`, in the `@font-face` block for `'Barlow Condensed'` (weight 800, ~line 35). Decode it into the `.ttf`. Confirm the PostScript name is exactly `BarlowCondensed-ExtraBold` (e.g. `fc-scan` or `fontTools`); if it differs, use the real name in code and tell Jakub. If the embedded file is not a usable static ExtraBold, stop and report; do not substitute another font.
   - Register the font in `SmackAPad-Info.plist` under `UIAppFonts` (file name, like the IBM Plex entry).
   - Verify font loading in `SmackAPad/Sources/UI/Theme.swift` alongside IBM Plex Sans (`UIFont(name: "BarlowCondensed-ExtraBold", size: ...)`).
2. **Typography theme token**:
   - Add a dedicated token in `Theme.swift`, e.g. `Theme.padTitle(size: CGFloat)` using `"BarlowCondensed-ExtraBold"`, and canvas variant if needed.
3. **HomePadView pad titles**:
   - Apply Barlow Condensed ExtraBold to the pad titles only (`DNES`, `KNIHOVNA`, `TRÉNINK`, `INTRO`, `OVLADAČ`, `ODZNAKY`, `PLNÁ VERZE`, `NASTAVENÍ`).
   - Sizing: Proportional to pad cell size matching ticket 135 preview (~16 pt for normal action pads, ~19 pt for the hero pad `DNES` at standard 146 pt pad dimension).
   - Letter-spacing: +0.03 em tracking for clear tactile readability.
   - Text transform: Uppercase.
4. **Subtitles and numbers**:
   - Subtitles (`2 cvičení · pak nová lekce`, `42 / 216 ★`, `3 na řadě`, etc.) stay IBM Plex Sans.
   - Engraved pad numbers (`01`–`08`) stay IBM Plex Sans monospace.
5. **Text fitting & layout (Ticket 116 preservation)**:
   - Preserves ticket 116 rule: no "…" truncation on any pad.
   - All titles fit cleanly with generous margins as verified in ticket 135 measurements (longest title "PLNÁ VERZE" takes ~71 pt inside ~140 pt pad width).

## Rules

- Home screen action pads only. Do not change titles on Library, Practice, Training or Settings screens.
- **Add** a Barlow Condensed entry (SIL OFL 1.1) to the Licences section in `AboutScreen.swift`, in the same form as the existing IBM Plex Sans entry (see ticket 80). Small change, only this entry.
- Build must succeed with zero new warnings.

## Files to read

`AGENTS.md`, this ticket, ticket 119, ticket 135, `SmackAPad-Info.plist`, `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Sources/UI/HomeScreen.swift` (`HomePadView`, line ~331), `SmackAPad/Sources/UI/AboutScreen.swift` (licences only).

## Acceptance criteria

- [x] `BarlowCondensed-ExtraBold.ttf` bundled and registered in `UIAppFonts`.
- [x] Home pad titles render in Barlow Condensed ExtraBold in both Light and Dark appearances.
- [x] Subtitles and pad numbers remain in IBM Plex Sans.
- [x] No "…" on any pad title in Czech or English, landscape and portrait.
- [x] Barlow Condensed licence listed in About/Licences.
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: Check visual contrast and pad title appearance on iPad.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: Straightforward font asset integration and styling update. Run **after ticket 141 is committed** or before it, never at the same time: both may edit `Theme.swift`.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-07

- Extracted and verified `BarlowCondensed-ExtraBold.ttf` from `docs/previews/135-pad-title-fonts.html` (PostScript name confirmed as `BarlowCondensed-ExtraBold`, SIL OFL 1.1).
- Added `barlowcondensed-OFL.txt` and bundled font registered under `UIAppFonts` in `SmackAPad-Info.plist`.
- Added `Theme.padTitle(size:)` and `Theme.canvasPadTitle(size:)` tokens and verified font loading alongside IBM Plex Sans in `Theme.swift`.
- Updated `HomePadView` pad titles to use Barlow Condensed ExtraBold with +0.03 em tracking and proportional sizing (~16 pt action pads, ~19 pt hero pad at 146 pt pad dimension), retaining IBM Plex Sans for subtitles and engraved numbers.
- Added Barlow Condensed licence note in `AboutScreen.swift` and updated `Localizable.strings` (EN & CS).
- Build succeeded with zero errors. No new tests added.
