# 178 — Practice screen: grouped icon toolbar, back arrow, title on two lines, full drum names in the band

Status: ready-for-agent (after Jakub has checked ticket 171 on the iPad and ticket 172 is committed — same files). Approved by Jakub on 2026-11-11 (points 1, 6, 13 and canvas comments).

Design reference: `docs/design/2026-11-11-screen-redesign/Main.dc.html` (artboard 1) and `MixNext.dc.html` (artboard 5). These are HTML mockups with inline sizes; open them in a text editor, they are not runnable on their own. Sizes are for an 11" iPad in landscape (1194 × 834 pt).

## Goal

1. The top bar of the practice screen becomes four visually distinct groups of icon-only buttons, so related controls belong together and unrelated ones no longer blend into each other.
2. One back arrow replaces "Dnes / Knihovna / Domů" (the app-wide part is ticket 181; here only the practice screen).
3. The lesson title is never cut off.
4. The left column of the orange band shows the drum's full English name (in Czech as well); the abbreviation stays only in the pattern cells.

## Rules

### A. Toolbar (left to right, 20 pt gap between groups, 4–8 pt inside a group)
1. **Back** (56 × 56, chevron-left, `Theme.surface` fill, radius 14). Goes back to the screen the lesson was opened from (Home, Library, Training/Today, Mix line-up). VoiceOver label "Back" / "Zpět".
2. **Title block** (flex): lesson title, `Theme.rowTitle`-ish 22 pt semibold, **up to 2 lines**, then truncation. Second line: stars (16 pt) + "1 bar"/"1 takt". Nothing else.
3. **Mode group** — segmented capsule (`Theme.surface`, radius 16, 4 pt padding), 48 × 48 buttons, selected = orange fill: Listen (ear), Play (crossed sticks), After me (two speech bubbles); thin divider; From memory (brain) as a toggle in the same capsule. Hidden in Mix where After me does not apply (keep Listen/Play/From memory).
4. **Pattern group** — capsule with 1.5 pt ink outline, no fill: scrolling/static view (arrows), bars shown (bar icon + number), section loop (loop arrows).
5. **Info group** — three separate outline buttons (1.5 pt, 28 % ink), no fill: lesson info (i), pad legend (grid with lines), help (?).
6. **Settings** — 56 × 56, filled `Theme.black` with cream icon.
- Icons: SF Symbols that match the mockup shapes (e.g. `ear`, `chevron.left`, `bubble.left.and.bubble.right`, `brain.head.profile`, `arrow.right.to.line` → use what reads best), stroke style, no text labels. Every button gets an accessibility label and a tooltip/long-press hint with its name; the help card (ticket 179 part D) explains them.
- Disabled states (e.g. while running) dim to 40 %; focus mode from 165 may still hide the whole bar while drumming.

### B. Full drum names in the band
- The left label column of every band row shows the full English name from one place (`PracticeComponents.swift:527 names` or a new `PadVoice.displayName`), bold, about 26 pt, left-aligned, vertically centred. **No abbreviation under it.** The pattern cells keep the abbreviation (`PadVoice.abbreviation`).
- **English names in all languages** (Kick, Snare, Hi-hat, Open hi-hat, Ride, Crash, High tom, Low tom, Rim, Clap, Shaker, Wood, Cowbell). Remove Czech drum-name translations (e.g. "Kick" = "Kopák", "Virbl", "Hluboký tom") from `cs.lproj`, everywhere in the app: band, pad legend, Settings volume rows, Mix line-up, help. Keep a test that drum names are identical in both languages.
- Width: the label column takes the longest name of the lesson's rows; with 4+ rows or a narrow window shrink the font down to 18 pt before truncating. Must not push the pattern grid.
- The existing switch that drops the left pad chips (round 7) now drops the name column.

### C. Transport labels
- The secondary transport button stays "Restart" / "Znovu" (already so in Czech). Equal width with START/STOP, 12 pt gap (ticket 167 tokens).

### General
- Three colours, IBM Plex Sans, `Theme.swift` tokens only. No new UI text except accessibility labels.
- Works in landscape, portrait, narrow window, Czech, 1–4 bars, scrolling and static, Mix.

## Files to read

- `AGENTS.md`, `docs/design/2026-11-11-screen-redesign/Main.dc.html`, `MixNext.dc.html`
- `SmackAPad/Sources/UI/PracticeScreen.swift` (`topZone`, `titleAndSubtitle`, tools rows)
- `SmackAPad/Sources/UI/PatternField.swift` (~line 255, row labels)
- `SmackAPad/Sources/UI/PracticeComponents.swift` (~527, pad names), `Theme.swift`
- `SmackAPad/Resources/cs.lproj/Localizable.strings`

## Tests

Unit test: every pad's display name is the same in English and Czech. Full suite.

## Acceptance criteria

- [ ] Four toolbar groups as described, icon-only, clearly separated; back arrow on the left.
- [ ] Long titles wrap to two lines, never overlap the toolbar.
- [ ] Band shows full English drum names without abbreviation; cells keep abbreviations.
- [ ] No Czech drum names left anywhere.
- [ ] Build and full suite pass.

### Manual iPad checks for Jakub

1. Open a lesson with a long title in Czech: title on two lines, toolbar intact.
2. Tap each toolbar button: right action, long-press shows its name.
3. Lesson with 4+ pads: names readable, pattern not squeezed.

## Agent assignment

Codex GPT-6.1 Sol, **high** (layout across sizes). Fallback: Gemini 3.8 Flash, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
