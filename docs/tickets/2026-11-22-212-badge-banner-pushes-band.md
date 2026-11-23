# 212 — Orange band jumps down while the badge banner is shown

Status: open. Reported by Jakub on 2026-11-14 (checklist "Tempo increase mid-run"): when a badge is earned, the orange band drops down for as long as the badge notice is visible and jumps back when it disappears. Only the band moves; it must stay in place.

## Cause found in the code

`PracticeScreen.body` places `BadgeBanner` inside the main `VStack` between `topZone` and `middleZone` (`PracticeScreen.swift`, ~line 116, `if let event = session.badgeBannerEvent { BadgeBanner(...) }`). While the banner exists it takes layout height, so `middleZone` (the band) is pushed down; when it is removed the band moves back.

## Goal

The banner appears without moving anything. The band, pattern, playhead and bottom zone stay pixel-exact.

## Rules

1. Draw the banner as an overlay (top centre, below the toolbar row, above the band's top edge region or over the empty gap), not as a layout sibling. Remove it from the `VStack`.
2. Keep: ~2.5 s duration, fade in/out, `allowsHitTesting(false)`, the existing text and icon.
3. Check the other transient notices in the same file with the same problem (tempo-up banner, star award, hint texts): any that is inserted into the `VStack` and shifts the layout gets the same fix. List what you found in the ticket.
4. It must not cover the pattern rows or the HUD at top right; if there is no free spot, place it over the toolbar gap and keep it short.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (`body`, `topZone`, `middleZone`), `SmackAPad/Sources/UI/BadgeBanner.swift`, `SmackAPad/Sources/UI/TempoUpBanner.swift`, `SmackAPad/Sources/UI/StarBurst.swift`.

## Transient notices check (Rule 3)

1. `BadgeBanner`: Was inserted directly into main `VStack` between `topZone` and `middleZone`, causing the band pushdown. Fixed: moved to `.overlay(alignment: .top)` on `middleZone`.
2. `TempoUpBanner` (`tempoUpBanner`): Rendered inside a `ZStack` within `practiceHUD` alongside `hudTempo` and `runMeter`. Not in a `VStack`, and fits within the HUD row height (36 pt ≤ 48 pt), so it does not shift layout.
3. Star award (`StarBurst` / `starEvent`): Mid-run star 1 triggers `midLessonStarMomentActive` (beam on band and effect on meter), not adding views to `VStack`. Stars 2 & 3 stop the run and render in `ResultCard` in `bottomZone`. No mid-run layout shift.
4. Hint texts: Toolbar hints use `.overlay(alignment: .bottom)` (`PracticeToolbarHintModifier`). The "Your turn" / "Listen…" hint in `middleZone` is persistent throughout AfterMe mode, not transient mid-run.

## Acceptance criteria

- [x] Earning a badge during a run does not move the band by a single point (portrait and landscape).
- [x] Same check for the tempo-up banner and the star award.
- [x] Build and tests pass.

### Manual iPad checks for Jakub

Debug scenario that awards a badge (or play a lesson until a badge is earned): watch the orange band while the notice shows and when it fades.

## Agent assignment

Gemini 3.8 Flash, thinking **medium** (cause already located). Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
