# 183 — Redesign Badges, About and Full version; collapse instrument volumes; Library "Play next" alignment

Status: ready-for-agent (after 181 — uses its back arrow). Approved by Jakub on 2026-11-11 (points 2, 16, 17, 19, 20).

Design reference: `docs/design/2026-11-11-screen-redesign/Badges.dc.html` (9), `SettingsSound.dc.html` (11), `About.dc.html` (12), `Paywall.dc.html` (13; its "purchased" prop shows the bought state).

## Rules

### A. Badges
- Header: back arrow, "Badges" / "Odznaky", overall progress bar (220 pt, orange fill) and "14 / 55".
- One panel per category (surface fill, radius 20): title + "3 / 7", then one row of round medals (84 pt ring, 72 pt inner circle). Earned: black ring, orange inner circle, black category icon, name (max 2 lines, centred) and the date. Not earned: ring shows progress as a black arc on grey (conic), inner circle surface colour with a grey icon, name, and "37 %".
- Tap a medal: existing badge detail (what it needs, progress).
- The square tile grid and the dark glowing tiles go away.

### B. Settings → Sound
- Rows: Sound set (value + chevron), Metronome, Pads, Pattern (label left, slider, dB value right, one line each).
- **"Instrument volume" / "Hlasitost nástrojů"** collapsed by default (disclosure row with a black chip "changed 2" when any value ≠ 0 dB). Expanded: a 2-column grid of compact cells (abbreviation bold + English name, value, slider), and "Reset all to 0 dB".
- Sample loudness itself was evened out in ticket 166; if Jakub's iPad check of 166 shows crash/ride/hi-hat still too loud, report it in this ticket's notes (measured values), do not tweak gains silently.

### C. About
- Back arrow. Centred column: logo tile (132 pt, four pads, top-right orange and rotated), "SMACK-A-PAD" (Barlow 56), "Version 1.0 (build N)" from the bundle.
- One grouped list: Support (mail icon, opens the support page/mail from ticket 81 when published; hidden until then), Privacy (shield icon, same rule), Font licences (disclosure: IBM Plex Sans · SIL OFL 1.1, Barlow Condensed · SIL OFL 1.1).
- Footer "© 2026 [AUTHOR]" — leave the name as a placeholder constant; Jakub fills it in later.

### D. Full version (paywall and bought state)
- Left: black panel (500 pt wide, radius 24) with back arrow, logo, "PLNÁ VERZE / FULL VERSION" (Barlow 76, two lines), big orange number of extra lessons from the purchase data (not hard-coded).
- Right: three benefits, each an icon tile (52 pt) + bold line + small second line: whole library (all Path stages and the genre lessons, numbers from data), one-time payment / no subscription, stages unlock by stars.
- Bottom right: "Unlock for <price>" (orange, 80 pt, price from StoreKit) and "Restore purchase" (secondary). Bought: one black bar with orange check "Purchased" / "Zakoupeno", no buy button.

### E. Library
- "Play next" / "Hrát další" button: same height as the filter chips and aligned to the right edge of the content, on the header line of the stage title (no offset, screenshot 16).

### General
- Three colours, Plex/Barlow, tokens, English drum names, Czech, portrait.

## Files to read

- `AGENTS.md`, the four design files
- `SmackAPad/Sources/UI/BadgesScreen.swift`, `BadgeTile.swift`, `SettingsView.swift`, `AboutScreen.swift`, `PurchasesView.swift`, `LibraryScreen.swift`, `Store/*`

## Tests

Unit test for the "changed N" count of instrument volumes. Existing purchase/badge tests pass. Full suite.

## Acceptance criteria

- [ ] Badges, About and Full version match the design; bought state correct.
- [ ] Instrument volumes collapsed by default, compact when open.
- [ ] Library "Play next" aligned.
- [ ] Build and full suite pass.

### Manual iPad checks for Jakub

Open Badges, About, Full version (debug purchase override on/off), Settings → Sound (expand volumes), Library header.

## Agent assignment

Codex GPT-6.1 Sol, **medium**. Fallback: Gemini 3.8 Flash, medium (good fit: four independent screens).

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
