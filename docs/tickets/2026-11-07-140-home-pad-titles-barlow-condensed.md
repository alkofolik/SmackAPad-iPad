# 140 — Home pad titles: Barlow Condensed ExtraBold

Status: ready-for-agent. Depends on: 119 (controller body), 135 (font proposal). Source: Jakub, 2026-11-07: selected Barlow Condensed ExtraBold from ticket 135 preview ("líbí se mi 3 - barlow").

Spec = preview `docs/previews/135-pad-title-fonts.html` (candidate 3: Barlow Condensed ExtraBold).

## What to build

1. **Font asset**:
   - Bundle `BarlowCondensed-ExtraBold.ttf` (SIL Open Font License 1.1) in `SmackAPad/Resources/Fonts/`.
   - Register the font in `SmackAPad-Info.plist` under `UIAppFonts`.
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
- Keep SIL OFL license notice in About/Licences view (`docs/tickets/2026-11-04-80-about-and-licences.md` / `AboutScreen.swift`).
- Build must succeed with zero new warnings.

## Files to read

`AGENTS.md`, this ticket, ticket 119, ticket 135, `SmackAPad-Info.plist`, `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Sources/UI/HomeScreen.swift` (`HomePadView`).

## Acceptance criteria

- [ ] `BarlowCondensed-ExtraBold.ttf` bundled and registered in `UIAppFonts`.
- [ ] Home pad titles render in Barlow Condensed ExtraBold in both Light and Dark appearances.
- [ ] Subtitles and pad numbers remain in IBM Plex Sans.
- [ ] No "…" on any pad title in Czech or English, landscape and portrait.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: Check visual contrast and pad title appearance on iPad.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: Straightforward font asset integration and styling update in `Theme.swift` and `HomeScreen.swift`.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
