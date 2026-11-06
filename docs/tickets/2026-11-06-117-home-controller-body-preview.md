# 117 — Home background v2: a real-looking controller body (one design, preview only, no app code)

Status: preview-ready (2026-11-06). Source: Jakub, 2026-11-06, after the proposals of ticket 114 ("none of them is great, at most a bit of C, except its two horizontal lines"). Follow-up: implementation ticket after Jakub approves.

## What Jakub wants (his words, condensed)

- The pads sit in a **plate screwed into the corners with screws** (C had a bay plate with 4 screws: keep that idea).
- **Around the plate, graphics that imitate sliders (faders) on a controller.**
- The background colour should be **rough and grainy, imitating plastic**; a **combination of materials** is welcome (for example grainy plastic body, a smoother or brushed metal plate, **metal screws**).
- It should look like a **real controller, in a light version and in a dark version**.
- From C he does **not** want the two horizontal grooves that split the panel into zones. Nothing else from A, B, C is a requirement; the rest of C (bay plate, soft vignette) is fine if it helps.

## Goal

**One** carefully made design (not three), as an offline HTML preview, with the controls below so Jakub can judge it and tune it. **Do not change app code, assets, project settings or `Localizable.strings`.**

## Design brief

1. **Body**: the whole Home background is the controller's top surface: matte plastic with visible **fine grain/speckle** (rough, not smooth). Light version = warm off-white / light grey plastic from the app's cream family; dark version = soft warm black plastic (ticket 92 palette as the base, only tints of it). Grain must be subtle enough that text on top keeps WCAG AA contrast.
2. **Plate**: the 3×3 pad grid sits in a plate of a different material (smoother, slightly metallic or satin; light/dark variants), with a bevelled edge and **4 metal screws in its corners** (slotted or Phillips, small highlight, tiny shadow, each screw turned to a slightly different angle so they do not look copied). The plate edge and the pad wells give depth; pads keep the look from ticket 112.
3. **Faders**: decorative slider graphics around the plate: slim slots with a small knob/cap, tick marks and tiny engraved numbers, placed in the free space beside the plate in landscape and above/below it in portrait. They are **not interactive** and show **no real data** (static positions). Keep them quiet: engraved/printed look, not brighter than the pads. Optional: one small orange detail (a cap or tick) as accent, nothing glowing.
4. **Small extras allowed** (only if they look good, keep few): engraved labels (pad numbers 1–8, "SMACK-A-PAD"), a thin printed line, rubber feet are not needed.
5. **No** zone-splitting horizontal grooves, no glass/glow/gradient blobs, no emoji. Logo tile (ticket 115) and wordmark keep working on top.
6. Built so it can be done in SwiftUI cheaply: say for each layer how (grain = one small seamless noise tile image or `Canvas` drawn once; plate/screws/faders = shapes with gradients and shadows; no per-frame work, no animation of the surface). List the assets that would be needed and their size in KB. Reduce Motion: the surface is static anyway.
7. Must work in landscape and portrait on any iPad size without visible tile seams; Home only (Library, Practice, Settings keep their plain background).

## Deliverable

Folder `docs/design/2026-11-06-home-controller-body/`:

- `index.html`: the design on a full Home mock (same 3×3 pads and logo tile as the current app, orange light bar on Training), with switches: **light / dark**, **landscape / portrait**, **grain strength** (off / subtle / strong), **faders on/off**, **plate material** (satin / brushed metal), **background off** (for comparison).
- `README.md` in Czech, plain language, for Jakub: what it is, what to look at, the build recipe and cost per layer (asset sizes), open questions.
- Self-contained, offline, no CDN. Grain can be an inline SVG noise or a generated data-URI tile.

## Rules

- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).
- Reference only: `docs/design/2026-11-06-home-background/proposal-c.html` (bay plate and screws), `docs/design/2026-11-06-home-pads-and-motion/proposal-a.html` (pad look), the current `SmackAPad/Sources/UI/HomeScreen.swift` and `Theme.swift` for real colours and sizes.

## Files to read

`AGENTS.md`, this ticket, tickets 92, 94, 112, 115, `docs/DESIGN-BRIEF.md`, the files named under Rules.

## Acceptance criteria

- [x] One design, light and dark, landscape and portrait, all switches work offline.
- [x] Grainy plastic body, plate of another material, 4 metal screws, decorative faders, no zone grooves.
- [x] Pad titles and subtitles still pass AA contrast on top (state the measured ratios for the lowest-contrast text in both modes).
- [x] Build recipe and asset sizes per layer written down.
- [x] No file outside `docs/design/2026-11-06-home-controller-body/`, this ticket and the README table changed.

## Implementation — 2026-11-06

- Created `docs/design/2026-11-06-home-controller-body/index.html` with self-contained, offline HTML preview featuring full interactive switches (light/dark, landscape/portrait, grain strength off/subtle/strong, faders on/off, plate material satin/brushed metal, background on/off, reduce motion, and MIDI hit simulation).
- Hardware controller body features:
  - Textured matte ABS plastic body with directional light gradient and adjustable fine speckle grain.
  - Central recessed pad plate with choice of satin anodised polycarbonate or horizontal brushed metal finish.
  - 4 machined metal corner screws with countersunk rims and realistic highlights, each uniquely rotated (–24°, 51°, 108°, –63°).
  - 4 decorative slider/fader channels with dB tick scales, recessed travel slots, tactile ribbed knobs, and an orange indicator accent on CH 03.
  - Responsive hardware layout: 2+2 vertical faders framing the plate in landscape; 4 horizontal channel strips docked below the plate in portrait.
  - Preserved ticket 112 tactile pad styling (8pt radius, bevel, flash, Today hero pad, Training breathing light bar) and ticket 115 logo tile.
  - Strictly no zone-splitting horizontal grooves across the chassis.
- Measured WCAG AA & AAA contrast ratios:
  - Light mode: Normal pad title: **13.41 : 1** (AAA); Normal pad subtitle: **5.55 : 1** (AA); Hero title: **5.89 : 1** (AA); Hero subtitle: **4.73 : 1** (AA). Lowest contrast is 4.73:1 (exceeds 4.5:1 AA requirement).
  - Dark mode: Normal pad title: **12.85 : 1** (AAA); Normal pad subtitle: **6.60 : 1** (AA); Hero title: **5.89 : 1** (AA); Hero subtitle: **4.73 : 1** (AA). Lowest contrast is 4.73:1 (exceeds 4.5:1 AA requirement).
- Complete build recipe and asset budgets (~11–20 KB total) documented in `README.md`.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: realistic material rendering in CSS/SVG is fiddly and taste-driven, but there is no app code, so risk is low.

## Done rule

Stop when the files are written. Commit (AGENTS.md); Jakub opens the preview and decides.
