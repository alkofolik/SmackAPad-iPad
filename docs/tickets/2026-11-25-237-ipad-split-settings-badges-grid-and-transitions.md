# 237 — iPad wide layouts & unified transitions: two-column Settings, full-width Badges grid, and calm chassis everywhere

Status: ready-for-agent

## Goal

Use the iPad canvas properly on `SettingsView` (two-column split on wide viewports with capped readable panel width and uniform row typography) and `BadgesView` (adaptive multi-column grid instead of clipped horizontal carousels), apply `calmChassisBackground()` and `8 pt` panels consistently to `BadgesView`, `PurchasesView`, `AboutScreen`, and `HelpDeck`, and replace remaining bottom-slide `.fullScreenCover` presentations in `TrainingScreen` and `MixLineupScreen` with unified zoom/fade transitions.

## Rules

1. **Two-column iPad `SettingsView` (`SettingsView.swift`, `ControllerSetupView.swift`, `CalibrationView.swift`, `ContentView.swift`).**
   - Define `enum SettingsArea: String, CaseIterable, Identifiable { case sound, practice, controller, purchasesAndBackup, about }` (plus `#if DEBUG case developer #endif`).
   - On wide width (`>= 740 pt`), render `SettingsView` as a two-column layout: left area list (`250 pt` wide, flat `Theme.surface` active pill + `3 pt` `Theme.orange` edge, Back/Done button in header) and right scrollable detail pane with content capped to `maxWidth: 700` so labels and controls sit comfortably close together instead of spanning `1000+ pt`. On compact/narrow width (`< 740 pt`), collapse cleanly to a single `NavigationStack` list of areas or stacked sections.
   - Include a quick `"Help"` button in the Settings header/sidebar opening `HelpDeck`.
   - Unify row typography across `SettingsView`, `ControllerSetupView`, `CalibrationView`, and `MIDILearnView`: every setting label uses `Theme.control` (`16 pt` Regular), every value/description uses `Theme.meta` (`14 pt` secondary), and every section header uses `SectionHeader` (`19 pt` SemiBold)—removing mixed `display(16)` / `strong(16)` / `rowTitle` mismatches on sibling rows.
2. **Full-width `BadgesView` grid (`BadgesScreen.swift`).**
   - Replace `ScrollView(.horizontal)` inside `badgeGroupPanel` with `LazyVGrid(columns: [GridItem(.adaptive(minimum: 124, maximum: 156), spacing: 16)], alignment: .leading, spacing: 18)` so all medals in each category are visible across the iPad width without horizontal scrolling.
   - Replace `.background(Theme.background)` and `cornerRadius: 20` with `.calmChassisBackground()`, `Theme.Radius.panel` (`8 pt`), and `1 pt` `Theme.hairline` border.
3. **Consistent chassis & `8 pt` geometry on `PurchasesView.swift`, `AboutScreen.swift`, `HelpDeck.swift`.**
   - Apply `.calmChassisBackground()` to `PurchaseSheet`, `AboutDetailView`, and `HelpDeck`.
   - Update `AboutDetailView` grouped list and `PurchaseSheet` hero panel from `16–30 pt` rounded corners to `Theme.Radius.panel` (`8 pt`), keeping the `SMACK-A-PAD` wordmark on `AboutDetailView` in `BarlowCondensed-ExtraBold` and setting `paywall.title` in `IBM Plex Sans` (`Theme.boldDisplay(32)`).
4. **Unified calm transitions (`TrainingScreen.swift`, `MixLineupScreen.swift`, `Theme.swift`).**
   - Replace raw `.fullScreenCover` bottom-slide presentations for `todayPractice`, `mixPresentation`, `selectedAfterMeLesson`, `daySummary` (`TrainingScreen.swift`), and `tryLesson` (`MixLineupScreen.swift`) with `padPresentation` (when matched to a source card/button ID in `@Namespace`) or a calm fade/scale cover presentation modifier matching `PadPresentation` (`Theme.Motion.padZoom` / `padDismiss`, pure opacity under Reduce Motion) so screens never jarringly slide up from the bottom edge like generic iOS sheets.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Settings/SettingsView.swift`, `SmackAPad/Sources/UI/Settings/ControllerSetupView.swift`, `SmackAPad/Sources/UI/Settings/CalibrationView.swift`, `SmackAPad/Sources/UI/Settings/PurchasesView.swift`, `SmackAPad/Sources/UI/Settings/AboutScreen.swift`, `SmackAPad/Sources/UI/Shared/BadgesScreen.swift`, `SmackAPad/Sources/UI/Shared/HelpDeck.swift`, `SmackAPad/Sources/UI/Shared/ContentView.swift`, `SmackAPad/Sources/UI/Shared/Theme.swift` (lines 455–570), `SmackAPad/Sources/UI/Practice/TrainingScreen.swift` (lines 235–315).

## Tests

Run full test suite before the final commit of this release-polish series (`xcodebuild test` on the iPad simulator target) to verify zero regressions across all 8 tickets.

## Acceptance criteria

- [ ] `SettingsView` displays a clean two-column layout in iPad landscape (and compact fallback in narrow split/portrait) with capped `700 pt` detail width and uniform row typography.
- [ ] `BadgesView` displays medals in a multi-column grid with no horizontal scrolling.
- [ ] `BadgesView`, `PurchaseSheet`, `AboutDetailView`, and `HelpDeck` all use `calmChassisBackground()` and `8 pt` panels.
- [ ] Opening lessons, Mix, After me, and Day summary from `TrainingScreen` uses smooth zoom/fade transitions rather than bottom-up modal slides.
- [ ] Full app build and full test suite pass.

### Manual iPad checks for Jakub

Walk through every screen from Home (Today → Practice → Day Summary, Library → Intro, Controller, Badges, Full version, Settings, About, Help) in both landscape and portrait, light and dark mode, and with Reduce Motion on/off.

## Agent assignment

Gemini 4 Carbon (or Codex GPT-6.1 Sol), thinking **medium**.

## Done rule

Build, run the **full test suite** per `AGENTS.md`, commit on `release-polish`, stop for Jakub's final iPad check before merging `release-polish` into `main`.
