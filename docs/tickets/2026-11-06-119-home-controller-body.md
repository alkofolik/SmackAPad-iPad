# 119 — Home: the controller body (ribbed body, smooth plate with screws, faders)

Status: implemented; build OK; ready for iPad test. Depends on: 112, 113, 115, 116 (all done). Source: Jakub, 2026-11-06: approved the preview of ticket 118 ("I like it like this") **except the title**.

Spec = the preview `docs/design/2026-11-06-home-controller-body/index.html` (open it in a browser; keys G = guides, O = orientation, L = light/dark) and `README.md` in the same folder (layout numbers, build recipe, contrast table). Build exactly that, in SwiftUI, for the Home screen only.

## What to build

1. **Body**: the whole Home background is a ribbed plastic surface (fine parallel grooves, 4 pt pitch, light edge on top, shadow below; strong variant = the preview's "Výrazné", which is what Jakub looked at) with a soft vignette. Light = cream family, dark = soft warm black (ticket 92 palette, tints only). It fills the whole screen including safe areas. Optional faint speckle only if it costs nothing.
2. **Plate**: smooth plate under the pad grid (satin finish; the brushed-metal variant of the preview, very fine hairlines, is what Jakub saw: use that), radius 16 pt, bevelled edge, soft shadow, **padding around the grid = 36/146 of one pad cell on all four sides**.
3. **Screws**: 4 metal screws in the plate corners (diameter 18/146 of a cell, centre 18/146 from the edges), slotted, with highlight and tiny shadow, rotated by -24°, +51°, +108°, -63° (TL, TR, BL, BR). Never covered by pads.
4. **Faders**: decorative, static, not interactive, hidden from accessibility. Landscape: two on the left and two on the right, mirrored, vertically centred on the plate. Portrait: one row of four **below** the plate, horizontally centred, fully inside the screen. Engraved look, labels CH 01–CH 04 and scale +6 / 0 / -6 / -12 / -24 / -∞, orange accent on one cap as in the preview.
5. **Pad numbers**: small engraved 01–08 in the top-left of the eight action pads as in the preview (the logo tile has none). Check they do not collide with the text fitting of ticket 116.
6. **Title (the one thing Jakub did not like)**: in the preview the CSS text is clipped ("SMACK-A-PA|") and badly spaced. **Do not copy it.** Use the app's real wordmark (`HomeWordmarkView`, asset `LaunchWordmark`) in its own band above the plate with clear space on all sides, never touching or overlapping the plate. Same size rule as the preview (about 292/540 of plate width in landscape, 332/540 in portrait). The launch animation (tickets 46/61) must still end with the wordmark exactly in this place.
7. **Leave out** the preview's engraved service label ("SMACK-A-PAD // CONTROLLER BODY V2 // …") on the plate: it is preview text and would need localisation.
8. **Scaling**: the preview gives pt numbers for an iPad Pro 11″ (1194×834). Do **not** hard-code them. Derive everything from the current cell size (ticket 61/112 grid computation) and the screen size so the same proportions hold on every iPad and in both orientations; check iPad mini and the largest iPad. If a portrait screen is too short for faders, make them shorter, then fewer, never overlap pads.
9. **Pads and logo tile**: pads keep the ticket 112 look, the logo tile keeps ticket 115 behaviour. If a pad edge or the lit Training rim looks wrong on the plate, adjust the plate, not the pad; list it in the report.
10. **Cost**: all layers drawn once and rasterised (`drawingGroup()` or a cached `Canvas`), no per-frame work, no animation of the surface. Prefer code drawing (Canvas, shapes, gradients); a noise or ribbing tile image only if needed, small (≤ 12 KB), in `Assets.xcassets`. Scrolling or rotating must stay smooth.
11. **Reduce Motion**: the surface is static, nothing to change. After the launch animation the body may fade in over 0.2 s; with Reduce Motion it just appears.
12. **Contrast**: text on pads must still pass AA in light and dark (README table); the wordmark on the ribbed body too.

## Rules

- Home only. Library, Practice, Settings, About keep their plain background.
- No new user-facing text; the CH/scale labels are not words and are not localised.
- Do not touch Practice drawing, timing, audio, scoring.
- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).

## Files to read

`AGENTS.md`, this ticket, tickets 92, 94, 112, 115, 116, the preview `index.html` and `README.md` above, `SmackAPad/Sources/UI/HomeScreen.swift` (background, grid, `HomeWordmarkView`, launch sequence), `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [ ] Light and dark, landscape and portrait: ribbed body, smooth plate with four visible screws, faders as specified, everything centred, nothing overlapping or cut off.
- [x] Title is the real wordmark in its own band; launch animation still ends in the right place.
- [ ] No hard-coded 1194×834 numbers; proportions hold on iPad mini and the largest iPad.
- [x] Only Home has the new background.
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: cold start and return to Home, both orientations and appearances, rotate while on Home, check scrolling/rotation smoothness.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: proportional layout in two orientations, Canvas drawing of several materials and interplay with the launch animation. Harder than the earlier pad tickets, so Sol first instead of Flash.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-06

- Added a shared proportional Home layout: the plate and pad grid share the screen centre; the plate occupies about 65% of the shorter screen axis, subject to the existing grid ceiling. Gap, plate padding, hardware and wordmark sizes derive from the computed cell size. The real `LaunchWordmark` occupies the centre of the upper band, and the launch animation uses the same final coordinates.
- Added two isolated, equatable, rasterised Canvas views: the strong 4 pt ribbed body with vignette, and the brushed plate with bevel, shadow, four slotted screws and decorative faders. No images, service label, surface animation, new localisation or accessibility elements were added.
- Landscape has mirrored pairs of faders, centred beside the plate. Portrait has four faders centred in the lower band; travel shortens with available height, then channels are omitted in unusually short windows. Channel 03 has the orange indicator.
- Added engraved numbers 01–08 inside the action pads, reserving a separate top band before the existing text fitting. Hero subtitles and secondary subtitles now use full-opacity palette text to preserve AA contrast. Pad edges, Training rim/light bar and the logo tile's About behaviour were retained; no compensating plate adjustment was needed.
- Reduce Motion shows the body and hardware immediately; the grid retains its 0.2 s opacity-only entrance. Normal launch settlement fades in the static hardware over 0.2 s after the logo lands.
- Validation: Debug build for generic iOS Simulator succeeded with `CODE_SIGNING_ALLOWED=NO`. The initial sandboxed build could not launch compiler macros; the build succeeded with the required system access. No tests were added or run. Existing warnings remain in `ReviewReminderScheduler`, `PatternField` and `HomePadDestination`.
- Pending human verification: light/dark, both orientations on iPad mini and the largest iPad, long pad text, cold start, return to Home, rotation and smoothness. Visual/device acceptance boxes remain open until Jakub checks them.
