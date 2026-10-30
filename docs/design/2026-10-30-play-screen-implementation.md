# Ticket 11 implementation

Source of truth: [practice screen specification](2026-10-30-practice-screen-spec.md).

## Delivered

- Native SwiftUI theme, with an orange pattern field and achromatic light/dark appearances. Dark is the default. Avenir Next Heavy and Menlo are used from iPadOS; no font files are copied or redistributed.
- Shared transport buttons, hand blocks, bar headers, three-star summary, layout diagram and a custom drawn icon set.
- Static 1/2/all-bar pages, continuous scrolling with an overview, legend, Listen/Play, From memory, count-in, continuous passes, stopped-only tempo controls and section loops.
- Native audio/MIDI/scoring integration. Display refreshes read host time; they do not trigger sound. Completed full passes update progress. Interrupted passes and section loops do not earn lesson stars.
- Backward-compatible `memory` progress flag: missing fields decode as false. A manually lowered current tempo is saved without clearing any earned stars or best score.
- A minimal lesson picker makes the new screen reachable; the previous MIDI setup/monitor remains available from the tools. Home/Library design remains a separate ticket.

## Integration boundaries

The scoring engine currently has no bar-summary output. `PracticeSession.receiveBarSummary(bar:pass:verdict:)` is the receiving interface for the separate scoring ticket. `BarVerdict` and `BarHeader` render its four words. Until that output exists, headers deliberately have no invented verdict. The scoring formula and thresholds are unchanged.

The session accepts early/late matches across pass boundaries. A tempo increase applies at the next unscheduled pass boundary, keeping queued audio and the preceding pass's full timing window intact. No intermediate count-in or stop is inserted.

The summary reports the last completed pass's score and the stars earned across the run. Detail opens a small explanation in place; it does not navigate to a results screen. Section loops show the selected pattern with bar numbering relative to that selection.

## Verification

Per Jakub's instruction: build only, with no tests or simulator. Use:

```
xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath build/PlayScreenDerivedData CODE_SIGNING_ALLOWED=NO build
```

Layout, audio/MIDI behaviour, tempo transitions and readability in both iPad orientations require Jakub's device check. Bar-verdict acceptance remains dependent on the separate scoring ticket.
