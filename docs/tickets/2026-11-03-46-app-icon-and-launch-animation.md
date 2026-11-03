# 46 — App icon and launch animation from the existing Smack-a-Pad logo

Status: implemented; build OK; awaiting iPad verification. Source: Jakub, 2026-11-03. He rejected the three concepts of ticket 45 and chose his **existing logo** (three black pads, the top-right pad orange and rotated = the "smack") with the **cream background**. Ticket 45 is superseded; its `docs/design/2026-11-03-icon-and-launch/` folder is not used.

## Source files (already in the repo)

`docs/design/2026-11-03-logo-source/` — see its README. `smack-a-pad-icon.svg` (viewBox 100×100: background `#F2F0EA`, pads `#111111` at (14,18), (14,58), (54,58) each 32×32 with radius 3, orange `#FF5B1F` pad at (57,11) rotated 12° about (73,27)), `smack-a-pad-logo-horizontal.svg` (the same four pads plus the wordmark "Smack-a-Pad" as outlined paths), `legacy-icon-512.png` (old raster icon, for comparison). Use the logo colours exactly; do not recolour to `Theme.orange`.

## Goal

1. The app has its real icon.
2. On a cold start the user sees a short, tasteful launch animation of the logo and the name **Smack-a-Pad**, then the library.

## Part 1 — App icon

**Moved to ticket 57 (2026-11-03).** Skip this part here if 57 is done.

- Fill the 1024×1024 slot of `SmackAPad/Assets.xcassets/AppIcon.appiconset` (single universal iOS icon, as the existing `Contents.json` is set up).
- Build the PNG from `smack-a-pad-icon.svg`, but **full-bleed and square**: remove the rounded corners of the background (the `rx="22.5"` rect) — iPadOS applies the mask itself. Opaque, no transparency, no alpha channel (App Store requirement), sRGB.
- Keep the pad proportions of the SVG. Commit the PNG and the square SVG source next to each other under `docs/design/2026-11-03-logo-source/` (e.g. `app-icon-1024.png`, `app-icon-square.svg`). Do not add dark/tinted icon variants now.

## Part 2 — Static launch screen

- Replace the blank auto-generated launch screen with a static one: **solid cream `#F2F0EA`** in both light and dark appearance, nothing else drawn (the animation starts from this empty frame, so there is no flash and no jump). Use the plist `UILaunchScreen` dictionary with a colour from the asset catalog (`UIColorName`), not a storyboard.

## Part 3 — Launch animation (SwiftUI, cold start only)

- A `LaunchAnimationView` shown full screen over `ContentView` when the app process starts; it is **not** shown when the app returns from background. Total about **1.6 s**, then fades out (0.25 s) revealing the library. Tap anywhere skips it.
- Sequence on the cream background, logo drawn from SwiftUI shapes (rounded rectangles as in the SVG), centred and sized by the shorter screen side (about 28 % of it), so it works in portrait, landscape and Split View:
  1. 0.00–0.45 s: the three black pads appear one after another (top-left, bottom-left, bottom-right), each with a quick scale/opacity pop, 0.12 s apart.
  2. 0.55 s: the orange pad "smacks" in from slightly above and larger, lands at its place with a rotation settling at 12° (one small overshoot), and the three black pads give a tiny 2 pt "bounce" at the moment of impact. No sound, no glow, no particles.
  3. 0.95–1.25 s: the wordmark "Smack-a-Pad" fades and rises a little in below the logo. Use the outlined wordmark paths of the horizontal logo SVG, added to an asset catalog image set that **preserves vector data** (do not retype the name in a font; do not use IBM Plex here — the wordmark is the logo).
  4. Hold until 1.6 s, then fade out.
- **Reduce Motion** (`UIAccessibility.isReduceMotionEnabled` / SwiftUI `accessibilityReduceMotion`): no movement; the complete logo with wordmark fades in (0.25 s), holds 0.6 s, fades out.
- Wordmark/logo colours as in the source; on screen the background is cream also in dark appearance (Jakub's decision).
- Native SwiftUI only (shapes, `withAnimation`, `TimelineView` if needed); no Lottie, no video, no new packages.
- The animation must not delay or block `store.start()`/`midi.start()`/data loading: the app keeps loading underneath.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/App/SmackAPadApp.swift`, `SmackAPad/Sources/UI/ContentView.swift`, `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Assets.xcassets/`, `SmackAPad.xcodeproj/project.pbxproj` (launch-screen keys: `INFOPLIST_KEY_UILaunchScreen_Generation`), `SmackAPad-Info.plist`, `docs/design/2026-11-03-logo-source/`.

## Acceptance criteria

- [ ] `AppIcon.appiconset` contains a 1024×1024 opaque PNG; Xcode shows no "missing icon" warning; the app has its icon on the iPad home screen.
- [ ] Cold start: cream launch screen → logo animation → library, with no white flash and no visible jump between launch screen and animation.
- [ ] Returning from background does not replay it. Tap skips it.
- [ ] Reduce Motion variant works.
- [ ] Looks right in portrait and landscape on iPad 11" and 13".
- [ ] Build passes; do not run tests (see AGENTS.md).
- [ ] **iPad test (Jakub)**: icon on the home screen, cold start twice, with and without Reduce Motion (Settings → Accessibility → Motion).

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app), **medium** reasoning. The logo and sequence are fully specified; the work is asset-catalog and launch-screen configuration plus one SwiftUI view. Use **high** if the first build shows a launch-screen flash that is hard to remove.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
