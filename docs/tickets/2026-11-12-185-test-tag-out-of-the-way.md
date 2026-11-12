# 185 — The TEST tag must not cover any buttons

Status: done (tested on iPad by Jakub and pushed 2026-11-12). Approved by Jakub on 2026-11-12 (iPad check, scenario reviewDueToday).

## Problem

The debug tag `TEST: <scenario> · ...` (DEBUG only, `DebugTestMenu.swift`, `DebugTestMarker`) sits in the top-right corner as a `safeAreaInset(edge: .top)`. On some screens it covers controls there: in the Library (landscape) a button under it, in portrait the last filter chips (Started, New); the same happens on the practice screen, Home and Training. It is applied in `PracticeScreen`, `HomeScreen` (twice) and `TodaySessionScreen`; the Library is reached from Home, so check each screen.

## Goal

The tag stays visible and tappable (it opens the debug menu) but never covers a control, in landscape and portrait, Czech and English.

## Rules

- Do not remove the tag and do not make it Release code. Keep it inside `#if DEBUG`.
- Make it a small, unobtrusive marker that lives in a place no control uses. Choose one of: a small dot or short label (e.g. `TEST`) in the bottom-left corner above the safe area, or a thin strip that really reserves its own space (so the content moves down instead of being covered). Pick the one that covers nothing on every screen below and say which one you chose and why.
- Tapping it still opens the debug menu.
- Do not cover the orange pattern band, START/STOP or the pad legend.
- Screens to check: Home, Library (landscape and portrait), lesson (before START and during a run), Training, Settings, Badges, About, Full version.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/DebugTestMenu.swift`, `PracticeScreen.swift`, `HomeScreen.swift`, `TodaySessionScreen.swift`, `LibraryScreen.swift`.

## Acceptance criteria

- [ ] On every screen listed above no button, filter chip or toolbar item is covered by the tag.
- [ ] The tag still opens the debug menu.
- [ ] Release build contains no trace of it; build and full test suite pass.

### Manual iPad checks for Jakub

Scenario reviewDueToday: go through Home, Library (landscape and portrait), a lesson, Training, Settings. Everything in the top-right corner is tappable.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
