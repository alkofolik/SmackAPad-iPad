# 88 — Appearance change (Light / Dark / System) applies at once

Status: ready. Source: Jakub, 2026-11-05 (photo 5): "Sometimes I change the appearance, but it doesn't change even after closing the settings. It switches only when I tap another category."

## Problem

The appearance is applied only with `.preferredColorScheme(settings.appearance.colorScheme)` on `ContentView` (`SmackAPadApp.swift`). Known SwiftUI limits:
- popovers and sheets that are already open (the practice tools popover, where Jakub changed it) do not follow;
- going back to **System** sets `nil`, which often does not reset an already forced Light/Dark until some other view redraws;
- `Theme` colours are `UIColor` dynamic providers (`Theme.adaptive`), which follow the UIKit trait of the window, not only the SwiftUI environment.

## Rule

- When `settings.appearance` changes (and once at launch), set `overrideUserInterfaceStyle` on every window of every connected `UIWindowScene` (`.light`, `.dark`, `.unspecified` for System). Keep `.preferredColorScheme` as well, or remove it if the window override alone works everywhere — test both popovers and sheets.
- The change is visible immediately: on the practice screen behind the open tools popover, in the popover itself, in Settings, Library and Home.
- No view rebuild via `.id(...)` for this (it would reset the practice session).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/App/SmackAPadApp.swift`, `SmackAPad/Sources/UI/Theme.swift` (`adaptive`, `AppAppearance.colorScheme`), `SmackAPad/Sources/Persistence/Persistence.swift` (`appearance` only).

## Acceptance criteria

- [ ] Light → Dark → System → Light from the practice tools popover: each step changes the whole screen at once, popover included.
- [ ] Same from Settings.
- [ ] System follows the iPad setting (Control Centre dark mode toggle) while the app is open.
- [ ] A running practice session is not interrupted.
- [ ] Build passes; do not run tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
