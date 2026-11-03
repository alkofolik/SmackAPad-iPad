# 45 — App icon and launch animation: design proposals (no app code)

Status: ready. Source: Jakub, 2026-11-03 (approved). The product name for display is **Smack-a-Pad**.

## Problem

1. The app has no icon: `SmackAPad/Assets.xcassets/AppIcon.appiconset` has an empty 1024×1024 slot, so the app is hard to find on the iPad (release review R04, HIGH).
2. On launch the library appears at once and the app's name is shown nowhere. The launch screen is auto-generated and blank.

## Goal

Design proposals only. Jakub chooses, then a separate implementation ticket follows. **Do not change app code, assets catalogs or project settings in this ticket.**

## Deliverables (in `docs/design/2026-11-03-icon-and-launch/`)

1. **Three app-icon concepts**, each as a 1024×1024 px opaque PNG (no transparency, no rounded corners, no text smaller than it can be read at 60 px) plus the SVG source. Also a single overview image showing each concept at 1024, 180, 120 and 60 px, on a light and a dark iPad home-screen background.
2. **One launch-animation concept per icon concept (three in total)**, built as a self-contained HTML preview (open in a browser, loops on a "replay" button, has a switch that emulates "Reduce Motion"), plus a short written storyboard with timings.
3. A short `README.md` with your recommendation (one concept) and the reasons.

## Rules for the design

- Palette: only orange (the band's orange, `Theme.orange`), black and white. Plex typography for the wordmark: IBM Plex Sans Bold (font files are in `SmackAPad/Resources/Fonts/`; the OFL licence applies). The wordmark is written exactly **Smack-a-Pad**.
- Identity comes from the app's real notation: the orange pattern band with pad-abbreviation cells (HH, SN, KD) and the playhead. No generic drum-stick or headphone clip-art, no gradients-and-glow "AI look".
- Launch animation: 1.5–2.0 s, played only on a cold start (not on return from background), tap to skip, ends by moving smoothly into the library. With Reduce Motion on: static wordmark for about 0.8 s, then a simple cross-fade. No sound.
- The very first frame of the animation must match a static launch screen (so the app does not flash white); describe that frame and its colours for light and dark appearance.
- Keep it honest to what SwiftUI can do without extra libraries (shapes, opacity, offset, scale, `Canvas`/`TimelineView`); no Lottie or video.

## Files to read

`AGENTS.md`, `docs/design/DIRECTIONS.md`, `docs/design/2026-11-02-typography-proposals.md`, `docs/design/2026-11-02-band-proposals-v2.md`, `SmackAPad/Sources/UI/Theme.swift` (colours), `SmackAPad/Sources/UI/PatternField.swift` (band look).

## Acceptance criteria

- [ ] Three icon PNGs (1024², opaque) + SVGs + overview image exist.
- [ ] Three animation previews open locally and loop; Reduce Motion switch works.
- [ ] README with a recommendation.
- [ ] No file outside `docs/design/2026-11-03-icon-and-launch/` is changed.
- [ ] **Jakub chooses** one concept; the implementation (icon into the asset catalog, launch screen, animation) becomes a new ticket.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app), **high** reasoning. This is a design task with taste and brand identity at stake, and the three concepts must be clearly different from each other, so a thorough pass is worth it.

## Done rule

Stop after the deliverables exist; do not commit. Jakub reviews, Claude commits afterwards.
