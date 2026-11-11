# 181 — One back arrow across the app; Home pads all the same size with short text

Status: ready-for-agent (can run in parallel with 176/177; touches no practice code except the back target already set in 178). Approved by Jakub on 2026-11-11 (points 3, 4, 13; freed pad: "Continue").

Design reference: `docs/design/2026-11-11-screen-redesign/Home.dc.html` (artboard 8); back button style in every artboard.

## Goal

1. Every screen and sheet uses the same back arrow at the top left instead of "Domů", "Knihovna", "Dnes", "Hotovo" or "Done". It returns to the screen the user came from.
2. The Home pads look identical: same size, title plus at most one short line.

## Rules

### A. Back arrow
- One shared component in `Components.swift`: 56 × 56, radius 14, `Theme.surface` fill, chevron-left, accessibility label "Back" / "Zpět". 
- Use it on: Library, Training (ticket 182), Today/day summary, Badges, Settings (also when opened as a sheet), About, Full version, Controller setup, Calibration, Help, lesson info sheets, Practice (178).
- Behaviour: pop the navigation stack or dismiss the sheet — always back to where the user came from (e.g. Settings opened from the Library returns to the Library). No "jump to Home" buttons remain. Remove the old buttons and their strings.
- Exception: a modal that confirms something (purchase, unlock "Really?", delete) keeps its explicit action buttons.
- iPad hardware keyboard: Esc and ⌘[ trigger back.

### B. Home pads
- All 8 pads exactly the same size and layout: number top left, title (Barlow Condensed, as now), **at most one line** of small text under it, or nothing. No strikethrough, no second line.
- Pads:
  - 01 **Today / Dnes** (orange): opens the merged Training screen (ticket 182) at the top. Line: "2 lessons" / "2 lekce" (number of steps left today) or nothing when done.
  - 02 **Library / Knihovna**: no line (remove "187 / 1722 ★").
  - 03 **Continue / Pokračovat**: opens the last played lesson. Line: its name, truncated to one line. Replaces the old Training pad (Training is now reached through Today).
  - 04 **Intro**: no line.
  - centre: logo, unchanged.
  - 05 **Controller / Ovladač**: line = controller name only (e.g. "JP-Mini"); drop "16 pads · notes 36–51".
  - 06 **Badges / Odznaky**: "14 / 55".
  - 07 **Full version / Plná verze**: "Unlocked" / **"Odemknuto"** (not "Odemčeno") when bought, nothing or the price when not.
  - 08 **Settings / Nastavení**: no line.
- The previous "Continue or Today" switching on pad 01 is removed.
- Empty profile: the Intro pulse from ticket 157 stays; pad 03 shows no line until a lesson was played (tapping it then opens Intro's first lesson).

## Files to read

- `AGENTS.md`, `Home.dc.html`
- `SmackAPad/Sources/UI/HomeScreen.swift`, `AppNavigation.swift`, `Components.swift`, every screen listed in A
- `SmackAPad/Resources/*/Localizable.strings`

## Tests

UI-free unit tests where logic exists: Home pad subtitle builder (one line max, correct strings for each pad state). Full suite.

## Acceptance criteria

- [ ] Same back arrow everywhere listed; each returns to the previous screen.
- [ ] No "Domů/Knihovna/Dnes/Hotovo" navigation buttons left.
- [ ] Home pads same size, max one short line, pad 01 Today, pad 03 Continue, "Odemknuto".
- [ ] Build and full suite pass.

### Manual iPad checks for Jakub

Open Library → Settings → back (Library). Home → Badges → back (Home). Practice from Library → back (Library). Check all Home pads in Czech.

## Agent assignment

Codex GPT-6.1 Sol, **medium** (many files, simple changes). Fallback: Gemini 3.8 Flash, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
