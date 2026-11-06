# 114 — Home background like a pad-controller surface: design proposals (no app code)

Status: ready-for-agent. Source: Jakub, 2026-11-06: "I'd like the Home screen to have some structure in the background, so it looks like the surface of a pad MIDI controller." Follows tickets 111 (chosen proposal A), 112 (pad look). Follow-up: an implementation ticket after Jakub chooses.

## Goal

**Three different proposals** of a Home background, as offline HTML previews. **Do not change app code, assets, project settings or `Localizable.strings`.**

The background is the "faceplate" the 3×3 pads sit in. Ideas to explore (one per proposal, or mixed, your call): a fine perforated or dotted grid, brushed or moulded plastic texture, panel seams and recessed pad wells around each pad, tiny engraved marks (screws, silkscreen lines, pad numbers 1–8, a faint logo/ruler strip), a subtle vignette or light falloff.

## Rules

- Pads from ticket 112 (proposal A: 8 pt radius, bevel, orange rim and top light bar on Training) must stay the stars. The background is quiet: text and pad titles keep full contrast (check WCAG AA in light and dark), no busy pattern behind text.
- App palette only (cream / soft warm black, ticket 92); no new colours except tints of those. No gradients that look glassy, no glow blobs, no emoji (ticket 94 spirit).
- Must be cheap to draw: a tiled image or simple SwiftUI shapes / `Canvas`, drawn once; no per-frame work and no animation of the texture itself. Say in each proposal how it would be built in SwiftUI (asset tile or Canvas) and its cost.
- Works in landscape and portrait, on any iPad size, without visible tile seams.
- Reduce Motion: the background is static anyway; if a proposal reacts to anything (for example the pad well lights when its pad is hit on the MIDI controller), that reaction follows the Reduce Motion rules of ticket 112.
- Home only. Library, Practice, Settings keep their plain background.
- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).

## Deliverable

Folder `docs/design/2026-11-06-home-background/`:

- `index.html` (comparison: character, how it is built, cost, risk), `proposal-a.html`, `proposal-b.html`, `proposal-c.html` — each shows the real Home grid with the ticket 112 pad look (copy the pad CSS from `docs/design/2026-11-06-home-pads-and-motion/proposal-a.html`, with the light bar on Training), with switches: light/dark, landscape/portrait, and a "background off" toggle for comparison.
- `README.md` in Czech, plain language, for Jakub: what each proposal is, what to look at, one recommendation with a short reason.
- Self-contained, offline, no CDN.

## Files to read

`AGENTS.md`, this ticket, tickets 92, 94, 112, `docs/DESIGN-BRIEF.md`, `docs/design/2026-11-06-home-pads-and-motion/proposal-a.html` and `README.md`, `SmackAPad/Sources/UI/HomeScreen.swift` (background and grid only), `SmackAPad/Sources/UI/Theme.swift` (colours).

## Acceptance criteria

- [ ] Three clearly different proposals, all readable and in the app palette.
- [ ] Each runs offline with all switches.
- [ ] Each says how it would be built in SwiftUI and what it costs.
- [ ] Czech README with a recommendation.
- [ ] No file outside `docs/design/2026-11-06-home-background/`, this ticket and the README table changed.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: design work in HTML/CSS, no app code; high thinking because taste and text contrast matter.

## Done rule

Stop when the files are written. Commit (AGENTS.md); Jakub opens the previews and chooses.
