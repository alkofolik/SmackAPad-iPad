# 111 — Home pads and app motion: design proposals (no app code)

Status: proposals-ready (2026-11-06). Source: Jakub, 2026-11-06: "the Home pads look ordinary; could they be more modern and better looking? I also miss modern animations and transitions overall." Follow-up: an implementation ticket is written after Jakub chooses.

## Problem

1. Home pads (`HomePadView` in `HomeScreen.swift`) are flat square tiles with a hairline border and centred text. The only feedback is `TactilePadButtonStyle` (scale 0.97, darker fill, 0.1 s). They do not feel like the pads of a drum controller, which is what the app is about.
2. Motion is thin. Ticket 27 added tokens (`Theme.Motion`) and a Reduce Motion policy, and Library ↔ Practice has a zoom (iOS 18). Home → Library / Training / Settings / Badges, the Today session, and the Home grid itself have little or no motion.

## Goal

**Three distinct proposals** as offline interactive HTML previews, so Jakub can see and feel them on the Mac and decide. **Do not change app code, assets, project settings or `Localizable.strings`.**

Each proposal covers both parts:

### A. Pad look

- Pads should read as **controller pads**: material and depth (for example a soft inner shade, a raised edge, a thin LED or light strip), a clear lit state (Training pad when reviews are due, ticket 98), a hero pad (Continue / TODAY) that clearly stands out.
- Press feedback like hitting a real pad: light-up flash, short squash, release. Optional: when the player hits a pad on the MIDI controller on Home, the matching screen pad lights for a moment (check what ticket 73 already does; build on it, do not duplicate).
- Stay inside the brand: app palette only (cream / soft warm black, orange, ticket 92), IBM Plex type (ticket 39), logo unchanged. No purple, no glassy gradients, no glow blobs, no emoji.
- **Decided (Jakub, 2026-11-06): Home pads may be slightly rounded**, like real controller pads. This is an exception to ticket 94 for the Home pads only; buttons, panels and cards stay square. Keep the radius modest (pad-like, not pill-like); each proposal states its radius as a named Theme token. No square-vs-rounded comparison needed.

### B. Motion and transitions (whole app chrome)

- Home grid entrance after the launch animation (for example a short staggered light-up across the 3×3 grid, like a controller booting).
- Transition Home pad → its screen (Library, Training, Settings, Badges, Today): the pad grows into the screen and shrinks back (zoom), with a fallback for iOS 17.
- Today session (tickets 109/110): hand-off card content steps in; buttons do not jump.
- Small live details: numbers that roll when they change, the lit LED breathing slowly, stars filling.
- Every proposal lists each animation with duration and curve, mapped to existing `Theme.Motion` tokens or proposing new named tokens.

## Hard rules (from ticket 27, still valid)

- **Reduce Motion**: opacity only, at most 0.2 s, no movement, scale, springs or pulses. The preview has a Reduce Motion toggle.
- **Never touch timing-critical drawing**: Practice pattern canvas, playhead, hit judging, scoring, audio. Motion proposals are for chrome only.
- iOS 17 deployment target; iOS 18-only effects need a stated fallback.
- Short and calm: most transitions 0.15–0.35 s. Nothing loops except an optional slow LED breath on a lit pad.

## Deliverable

Folder `docs/design/2026-11-06-home-pads-and-motion/`:

- `index.html` — overview, comparison table (character, what changes, cost to build, risk), links.
- `proposal-a.html`, `proposal-b.html`, `proposal-c.html` — each a working preview of the Home 3×3 grid (same content as today: hero, Library, Training, Badges, Full version, Settings, logo) with: tap feedback, lit Training pad, grid entrance (Replay button), a pad → screen zoom demo into a simple placeholder screen and back, light/dark switch, landscape/portrait switch, Reduce Motion toggle.
- `README.md` — Czech, plain language, for Jakub: what each proposal is, what to look at, which one you recommend and why (one paragraph).
- Self-contained files: no network, no CDN; fonts embedded or system fallback.

## Rules

- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).
- Look at the earlier proposal folders for format: `docs/design/2026-11-03-home-screen/`, `docs/design/2026-11-01-motion-proposals.md`.

## Files to read

`AGENTS.md`, this ticket, tickets 27, 61, 73, 92, 94, `docs/DESIGN-BRIEF.md`, `docs/design/2026-11-01-motion-proposals.md`, `docs/design/2026-11-03-home-screen/README.md`, `SmackAPad/Sources/UI/HomeScreen.swift` (`TactilePadButtonStyle`, `HomePadView`, grid), `SmackAPad/Sources/UI/Theme.swift` (colours, `Motion`).

## Acceptance criteria

- [x] Three clearly different proposals, all in brand palette and type.
- [x] Each preview runs offline and has all switches listed above.
- [x] Each animation listed with duration, curve and Reduce Motion behaviour.
- [x] README in Czech with a recommendation.
- [x] No file outside `docs/design/2026-11-06-home-pads-and-motion/` and this ticket changed.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: design work in HTML/CSS with motion; no app code, so the risk is low, but taste and care matter, hence high thinking.

## Done rule

Stop when the files are written. Commit (AGENTS.md); Jakub opens the previews and chooses.
