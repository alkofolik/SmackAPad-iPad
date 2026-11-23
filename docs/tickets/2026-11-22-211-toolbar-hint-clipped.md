# 211 — Long-press hint on the top toolbar is cut off at the right edge

Status: resolved. Reported by Jakub on 2026-11-14 (checklist "Top bar and back arrow after the fix"): the label shown on long press of "How it works" is cut off on the right and hidden under the Settings icon, in portrait and landscape.

## Cause confirmed

Buttons in `topZone` previously drew the pill as a local `.overlay(alignment: .bottom)` of the individual button.
1. "How it works" ("Jak to funguje"): Inside `infoGroup`, positioned directly to the left of `settingsButton`. The wide pill extended under the sibling `settingsButton` (which rendered on top because it appeared later in the layout without an elevated zIndex).
2. "Settings" ("Nastavení"): Rightmost icon; the pill centered under the button extended past the screen edge in landscape and portrait.
3. "Back" ("Zpět"): Leftmost icon; centered pill extended into negative coordinates beyond the left margin.

Fixed via `PracticeToolbarHintCoordinator`, `PracticeToolbarHintContainerModifier`, and `PracticeToolbarHintRowLayout`:
- Anchored to the entire toolbar container row (`topZone`) with `zIndex(100)` so the hint renders above all sibling controls and middleZone.
- `PracticeToolbarHintRowLayout` clamps the horizontal placement `clampedX` to `[bounds.minX, bounds.maxX - pillWidth]`, keeping the pill inside the screen with page padding on both left and right edges across orientations and languages.
- Gesture remains unchanged at 0.45 s duration. Short taps still trigger button actions normally.

## Goal

The hint pill is always fully readable, never clipped by the screen edge and never covered by another toolbar control.

## Rules

1. Keep the long-press gesture exactly as it is (0.45 s, short tap still triggers the button; this was broken once, see ticket history around 2026-11-12).
2. Keep the look of the pill (black, orange outline, `Theme.strong(15)`).
3. Position the pill so it stays inside the screen: shift it horizontally when needed (clamp to the screen with the page padding), or anchor it to the toolbar row instead of the single button. It must be drawn above every sibling.
4. No new text, no new settings.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeComponents.swift` (`PracticeToolbarHintModifier`, `practiceToolbarHint`), `SmackAPad/Sources/UI/PracticeScreen.swift` (`topZone`, every `.practiceToolbarHint(` call).

## Acceptance criteria

- [x] Long press on any toolbar button in portrait and landscape, Czech and English: the pill is complete and on top.
- [x] A short tap still triggers the button; a long press does not trigger it.
- [x] Build and tests pass.

### Manual iPad checks for Jakub

Long-press each of the toolbar icons in both orientations and both languages; the rightmost ones are the important ones.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
