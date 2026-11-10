# 162 — Implement “How it works” help and first-launch tutorial

Status: ready-for-agent. The Phase 1 design was approved by Jakub on 2026-11-10. [T159](2026-11-09-159-help-and-first-launch-tutorial.md) is complete. T157 and T158 passed their iPad checks.

## Goal

Let a new player learn the essentials before their first lesson, skip at any point and reopen the same visual guidance whenever they need it. Use the [approved design and three previews](../design/2026-11-09-help-and-tutorial.md) for the card order, copy, examples and layout.

## Rules

1. Use option A. Put a `questionmark.circle` button after Legend in the Practice toolbar, and a **How it works** row under the Home controller plate and in the Settings form. Keep the existing Home pad positions, Lesson info, Intro Rules and Legend. Keep a 48 pt target in the toolbar. Wrap the group when needed. The new entry controls are the only additions outside the help and tutorial presentations.
2. Open the same eight-card deck from each entry, starting at card 1. Use an anchored popover where it fits and a dismissible sheet in a narrow window. Opening help from Practice replaces another toolbar popover and keeps the current transport and MIDI input state. Examples are silent and use read-only rendering with demo data. They neither open lessons nor write lesson progress.
3. Show the four-card tutorial after Home's initial reveal only if progress loaded successfully, the Home route is idle, `hasAnyLessonProgress(progress.records)` is false and `smackapad.tutorial.seen` is false. Set the `@AppStorage` flag once the automatic tutorial is visible. Skip stays available on every card. Skip, Done and system dismissal return to Home. Reopening from **Watch tutorial** starts the same four cards at the beginning and closes back to help. Resetting progress does not clear the tutorial flag.
4. Keep the first-run order from the design. Tutorial first, then the Intro light on Home for an empty profile, then the existing one-time Legend on the first eligible stopped lesson. Help or Lesson info takes priority over an automatic Legend for that visit. Set `smackapad.legend.shownOnce` only when Legend appears under the existing conditions.
5. Use the 26 new keys in both English and Czech and reuse the existing app language path and labels listed in the design. Use IBM Plex Sans and the existing orange, black and white palette. With Reduce Motion or VoiceOver on, show the still examples from the design. Keep navigation and dismissal available at large text sizes and restore focus to the opener or Intro as specified.
6. Explain the shipped rules. The review card shows two eligible passes for a single review. The stars card shows two successful reviews on separate days for star 3. Show the first two passes as warm-ups only when note fade is enabled. The approved design reconciles the wording in T159 with the current app. Preserve scoring, tempo progression, review schedules, star requirements and unlocks.

## Files to read

- `AGENTS.md`, this ticket, [approved design and previews](../design/2026-11-09-help-and-tutorial.md), [T157](2026-11-09-157-first-run-and-legibility.md) and [T158](2026-11-09-158-review-from-library-and-uncounted-mark.md).
- `SmackAPad/Sources/UI/ContentView.swift`, `HomeScreen.swift`, `AppNavigation.swift`, `PracticeScreen.swift`, `SettingsView.swift` and `IntroScreen.swift` for progress loading, navigation and existing help surfaces.
- `SmackAPad/Sources/UI/Theme.swift`, `Components.swift`, `PracticeComponents.swift`, `PracticeInstruments.swift`, `PatternField.swift`, `StarRequirement.swift` and `TempoUpBanner.swift` for the existing visual components.
- `SmackAPad/Sources/UI/PracticeSession.swift`, `SmackAPad/Sources/Progression/ReviewScheduler.swift`, `TodayPlan.swift` and `SmackAPad/Sources/Persistence/Persistence.swift` for current behavior, loaded progress and localization.
- `SmackAPad/Resources/en.lproj/Localizable.strings`, `SmackAPad/Resources/cs.lproj/Localizable.strings`, `SmackAPadTests/FirstRunAndLegibilityTests.swift`, `SmackAPadTests/ProgressLoadFailureTests.swift` and `SmackAPad.xctestplan`.

## Tests

1. Check that every new help key listed in the approved design has a nonempty value in the English and Czech bundles. Verify each bundle directly so fallback cannot hide a missing key.
2. Cover the automatic tutorial policy. A successfully loaded empty profile with the flag unset is eligible once. A started lesson, an earned star, a set flag or a failed or pending load suppresses the prompt. Saved tempo alone keeps the profile eligible. Leaving Home before the prompt appears does not consume the flag.

## Acceptance criteria

- [ ] The question mark beside Legend and both **How it works** rows open the same eight-card help. Lesson info and Intro Rules still open their own content.
- [ ] A fresh profile sees four skippable tutorial cards, then the Intro light, then the one-time Legend when opening the first eligible stopped lesson. The tutorial stays dismissed after relaunch.
- [ ] **Watch tutorial** reopens the four cards at card 1 and returns to help. From Practice, help leaves the controller input and playback state as they were.
- [ ] The From memory and Reviews cards reflect the current fade setting. The stars and review diagrams distinguish successful passes within one review from successful reviews across days.
- [ ] All new text appears in English and Czech. Reduce Motion and VoiceOver show readable stills and controls stay reachable at large text sizes.

### Manual iPad checks for Jakub

- Use a fresh profile. Skip on each tutorial card, then check the Intro light and one-time Legend. Relaunch after skipping and after closing mid-tutorial. Compare with an existing profile.
- Open help from Home, Settings and Practice, both while stopped and during Play with the MIDI controller. Reopen the tutorial from help. Check portrait, landscape and a narrow window.
- Switch English and Czech, turn on Reduce Motion and VoiceOver, and enlarge text. Compare the review card with note fade on and off. Check whether the two-pass diagram and the two-day star requirement are easy to tell apart.

## Agent assignment

Codex GPT-6.1 Sol, high. Preserve the existing audio and practice state while coordinating the new presentation with first-run guidance.

## Done rule

Run a successful build and the full `SmackAPad` test plan, following `AGENTS.md` for failures or log finalization stalls. Commit the implementation and stop for Jakub's iPad check.
