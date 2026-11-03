# 42 — UI defects found in the iPad screenshot review (2026-11-03)

Status: implemented; build passed; iPad verification pending. Source: Claude's review of 40 iPad screenshots (Czech/English, light/dark) after tickets 38/39 and the type-scale reduction. Approved by Jakub on 2026-11-03.

## Goal

Fix five concrete display defects. Nothing else changes: colours, band design, type scale and layout stay as they are.

## Defects

1. **Many-row lessons overflow the band.** In "Jazz fusion přechod 1" (7+ pad rows, e.g. HH, HH, CR, SN, SN, TH, KD) the last row (KD) is cut off at the bottom of the orange band, and the playhead line crosses the "CR" label. Every pad row used by a lesson must stay visible with its own strip (a hard rule from the band design). Let the row height shrink to a sensible floor and, only below that floor, give the band its own vertical scroll; the footer must never move. Check 1, 3, 5, 7 and 9 rows, static and scrolling view, portrait and landscape.
2. **Clipped texts in the library.**
   - The "Cesta | Žánry | Techniky" segmented control in the left column is cut off ("Technik…") — it must fit the column in Czech and English (shorter labels, two-line-free layout, or a control that scales to the column width; never clipping).
   - The "Vymazat / Clear" button is clipped at the right edge in some widths.
   - The search placeholder is truncated ("Název, žánr…"); shorten the placeholder or let the field take more width.
3. **Playhead line strikes through the beat numbers.** In the top beat ruler the vertical playhead line runs through the digit "1" (and other beats it passes). Draw the digits above the line, or stop the line below the ruler, so the numbers stay readable.
4. **Count-in numeral is too small.** `CountInNumeral(number:size: 56 * notationScale)` in `PatternField.swift` renders a digit of roughly 40 px in a huge band. The count-in must be a large numeral again (about 40–50 % of the band height), centred over the dimmed pattern, Plex Bold with tabular digits.
5. **English texts in the Czech UI.** Find the source of each and localise it:
   - lesson subtitle under the title shows "eighth · Úroveň 1" / "intro · Úroveň 1" (raw category/group ids),
   - "Jak hrát" text of lessons is English in the lesson data ("First bar is a steady groove, then the fill…") — add or use the Czech text from the i18n tables if it exists; if the Czech text does not exist, report which lessons lack it instead of inventing translations,
   - Settings: "Learn a new profile (MIDI learn)" (see `SettingsView.swift:152`),
   - Intro rules: "Splnění (Pass)" in `cs.lproj/Localizable.strings` (key "Passing") — use "Splnění".
   Do not change English strings.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PatternField.swift`, `PracticeScreen.swift`, `PracticeInstruments.swift`, `PracticeComponents.swift`, `LibraryScreen.swift`, `Components.swift` (`PlexSegmentedPicker`), `Theme.swift`, `SettingsView.swift`, `Resources/cs.lproj/Localizable.strings`, `Resources/i18n/cs.tsv`. Note: `Theme.swift.bak-2026-11-02` is a leftover backup — do not use or edit it.

## Acceptance criteria

- [ ] Defect 1: all pad rows visible with 1–9 rows, both views and orientations; footer fixed.
- [ ] Defect 2: nothing clipped in the library header, sidebar or filter bar, Czech and English.
- [ ] Defect 3: beat numbers fully readable while the playhead passes.
- [ ] Defect 4: count-in numeral large and centred.
- [ ] Defect 5: no raw English in the Czech UI for the listed items; list of lessons without Czech "How to play" text reported in the ticket.
- [x] Build passes; tests not run (see AGENTS.md).
- [ ] **iPad test (Jakub)**: "Jazz fusion přechod 1", library in Czech and English (light and dark), count-in, lesson info panel.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app), **medium** reasoning; defect 1 (band layout) is the only non-trivial part. Use **high** if you prefer it to do all five in one pass.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.

## Implementation — 2026-11-03

- The practice viewport no longer inherits the full minimum height of every lane. Within the band, lane height shrinks to 44 points (scaled with notation); below that floor, only the pattern scrolls vertically. Static bar pagination uses the same floor as scrolling notation. The transport footer remains outside the scrolling region.
- The sidebar segmented control fits its column by measuring Plex Bold titles and scaling both font states together. Search uses the shorter existing “Search” key; Clear stays outside the horizontally scrolling filters.
- The playhead starts below the beat ruler and is drawn behind pad labels. Count-in uses a fixed Plex Bold size proportional to the visible band, with tabular digits; its glyph height is approximately 45% of band height.
- Lesson subtitles resolve category display titles instead of IDs. Czech profile learning and Passing labels are localized without editing English resources.

### Czech How to play content audit

Sources inspected: `lessons-core.json` (539 definitions), `intro.json` (24), `electronic-path.json` (12), `genre-extensions.json` (12), `cs.tsv`, and Czech `Localizable.strings`.

**Lessons missing Czech instructional content: none in the bundled sources.** The 48 Intro/electronic/extension definitions have whole-text translations. The 539 core definitions compose existing Left hand / Right hand labels and instrument names; these are now localized separately using the existing tables. Other core sentences, including “First bar is a steady groove, then the fill.”, already have Czech translations and are resolved individually. No new instructional translations were invented. English instructions are returned unchanged.

### Verification

- Automated tests: not run, as requested.
- Build: passed — `xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath .build-ticket42 CODE_SIGNING_ALLOWED=NO build` (`BUILD SUCCEEDED`).
- iPad review remains with Jakub: 1, 3, 5, 7 and 9 rows in static/scrolling mode and both orientations; Jazz fusion fill 1; Czech/English library in light/dark; count-in; lesson info.
- No commit, per Jakub's explicit instruction in this chat.
