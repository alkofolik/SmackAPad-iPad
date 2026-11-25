# 236 — Library, Intro, and MixLineup: remove nested boxes and align with 8/6 pt instrument panels

Status: ready-for-agent

## Goal

Eliminate "boxes inside boxes" across `LibraryScreen`, `IntroScreen`, and `MixLineupScreen`, grouping rows cleanly with `1 pt` hairline dividers inside flat `8 pt` instrument panels and highlighting the active `"Up next"` lesson and stage-unlock milestone clearly on iPad.

## Rules

1. **`LibraryScreen` sidebar (`LibraryScreen.swift`).**
   - Remove `.satinPlate()` wrappers around `introSectionRow`, collapsed `levelView`, and `categoriesFramedBox`.
   - Render sidebar items cleanly on the sidebar ground with `1 pt` `Theme.hairline` dividers between groups; mark the selected item with flat `Theme.surface` fill (`cornerRadius: Theme.Radius.button` = `6`) and a `3 pt` `Theme.orange` leading bar (no bevels, no drop shadows).
2. **`LibraryScreen` detail & `LibraryLessonRow` (`LibraryScreen.swift`).**
   - Remove `.structuralPlate()` per-row boxing on `LibraryLessonRow` so every lesson is no longer a separate bordered card. Instead, render lessons of a section inside one clean `8 pt` `Theme.surface` panel separated by `1 pt` `Theme.hairline` row rules (`1 pt` `Theme.hairline` outer border).
   - Emphasize the `isNext` (`"Up next"`) row with `Theme.activeFill.opacity(0.45)` subtle tint and a `3 pt` `Theme.orange` leading edge so the player immediately spots where their guided path continues, and display the next lesson's title beside the top `"Play next"` button (`"Hrát další · <název>"` when space fits via `ViewThatFits`).
   - Upgrade `stageBanner` (`InfoBanner` / locked stage header) to an `8 pt` `Theme.surface` bar (`1 pt` `Theme.hairline` border) clearly stating unlock progress (`"%lld / %lld lekcí se 2★ v předchozí etapě"`) alongside the soft-unlock secondary button.
3. **`IntroScreen.swift` & `MixLineupScreen.swift`.**
   - Group each `IntroStage`'s exercises into one `8 pt` `Theme.surface` section container with `1 pt` `Theme.hairline` dividers between exercises instead of floating ungrouped rows.
   - Update `MixLineupScreen` cards and bottom action bar to use `Theme.Radius.panel` (`8 pt`), `Theme.screenTitle` (`IBM Plex Sans` 26 pt), and `PadPrimaryButtonStyle` / `PadSecondaryButtonStyle` instead of bespoke rounded outlines.
4. Keep all filtering, search, hide/unhide category behaviour, VoiceOver labels, and `lessonSource` zoom anchors intact.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Library/LibraryScreen.swift`, `SmackAPad/Sources/UI/Library/IntroScreen.swift`, `SmackAPad/Sources/UI/Library/MixLineupScreen.swift`, `SmackAPad/Sources/UI/Shared/ScreenChrome.swift`.

## Tests

Build and run `-only-testing:SmackAPadTests/LibraryCatalogTests` and `-only-testing:SmackAPadTests/StageCompletionTests` (layout/styling changes; no new logic tests needed per `AGENTS.md`).

## Acceptance criteria

- [ ] No `.satinPlate()` nested boxes in the Library sidebar and no individual `.structuralPlate()` boxes around every lesson row; rows sit in clean `8 pt` panels divided by `1 pt` hairlines.
- [ ] The `"Up next"` lesson row is visually distinct and `"Play next"` connects clearly to it.
- [ ] `IntroScreen` stages and `MixLineupScreen` cards use the same `8 pt / 6 pt` instrument geometry and button styles.
- [ ] Portrait and landscape, light and dark mode, Dynamic Type, search, and filters all work cleanly.

### Manual iPad checks for Jakub

Browse Library in Path, Genres, and Techniques views (landscape and portrait), open Intro exercises, and open Daily mix lineup; verify calm flat panels without double borders and clear highlighting of the next lesson.

## Agent assignment

Gemini 4 Carbon (or Codex GPT-6.1 Sol), thinking **medium**.

## Done rule

Build, run area tests per `AGENTS.md`, commit on `release-polish`, stop for Jakub's iPad check.
