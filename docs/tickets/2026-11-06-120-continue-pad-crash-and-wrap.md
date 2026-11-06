# 120 — Home "Continue" pad: crash on tap, Czech title wraps in portrait

Status: in-testing. Source: Jakub, 2026-11-06 (iPad, Czech, portrait).

## Problem

1. **Crash**: tapping the top-left Home pad ("Pokračovat" / Continue) crashes the app. This is the most important part of this ticket.
2. **Wrap**: in portrait, in Czech, the pad title "Pokračovat" breaks onto two lines. It must stay on one line.

## Rules

1. Find the real cause of the crash first (read the crash log / run on the simulator in Czech, portrait, with a lesson in progress; check force unwraps, out-of-range indexes and missing lesson/state in the Continue action and the transition from ticket 113). Fix the cause, not the symptom. Describe the cause in the final report.
2. The title "Pokračovat" stays on one line in portrait and landscape on every supported iPad. Ticket 116 allows wrapping, but a single word must never break: give the title one line and let it shrink (`minimumScaleFactor`, floor 75 %) before anything else. Subtitles keep the 116 rules.
3. Do not change pad size, grid or look.

## Files to read

`AGENTS.md`, this ticket, ticket 116, `SmackAPad/Sources/UI/HomeScreen.swift` (`HomePadView`, Continue pad and its action), `SmackAPad/Sources/UI/AppNavigation.swift`.

## Acceptance criteria

- [ ] Tapping Continue opens the lesson, no crash (cause named in the report).
- [ ] "Pokračovat" on one line, Czech, portrait and landscape.
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: Czech, portrait, tap Continue.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: an unknown crash needs real diagnosis; the wrap fix is small.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-06

- Retrieved the actual device crash report `SmackAPad-2026-11-06-143253.ips` from the connected iPad into the ignored `.build/ticket120-diagnostics/` directory. It records `SIGABRT`, a UIKit assertion in `_morphPreviewFromCurrentState:fallbackBackgroundColor:contentScale:`, and SwiftUI `SheetBridge.dismissAndPresentAgain` during dismissal of a zoom presentation.
- Cause: Continue first sets `.continueToLesson` (`pad-continue`), then `openLibrary` echoes the same lesson through the global route. `syncWithNavigationRoute` replaced it with `.library` (`pad-library`), changing the full-screen cover identity during its zoom. The same mismatch affected the Intro pad and Continue's empty-library fallback.
- Added a semantic library target to Home destinations. Route synchronization now preserves the originating pad and cover identity when the requested library target already matches; different targets still navigate normally. No changes to lesson selection, pad geometry or transition styling.
- Home pad titles now use one line with the existing 75% minimum scale. Subtitle fitting and full accessibility labels are unchanged.
- No new tests. Runtime confirmation and portrait/landscape text inspection remain for Jakub on the iPad; simulator UI control was unavailable in this session.
- Validation: `xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/ticket120-build CODE_SIGNING_ALLOWED=NO build` succeeded. Stopped after the build as required.
