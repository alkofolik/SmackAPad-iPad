# 10 — Design Directions (3 Visual Concepts)

Status: superseded (2026-10-30) — Jakub replaced the three prompt directions with the mock-ups of the practice screen designed in conversation; see `docs/design/2026-10-30-practice-screen-spec.md` and `docs/design/mockups/`. DIRECTIONS.md is kept for reference only.

## Goal

Use the `imagegen-frontend-mobile` skill to produce 3 distinct visual directions for the app, based on DESIGN-BRIEF.md. Jakub generates the images (in Gemini/ChatGPT), picks one direction.

## Files to read

- `AGENTS.md`
- `docs/DESIGN-BRIEF.md` (all sections)
- `docs/SPEC.md` (§3.8 Screens — play screen, library, settings, calibration)

## Tasks

1. Read the `imagegen-frontend-mobile` skill instructions.
2. Read DESIGN-BRIEF.md dials, feel, context of use, play screen requirements, look, and the "AI look" reject list.
3. Produce 3 distinct visual directions as image generation prompts. Each direction should cover:
   - Play screen (primary focus — clean, eyes-off, dark theme).
   - Library screen (category browse).
   - Overall colour palette, typography choice, accent colours.
4. Each direction must avoid everything on the reject list (purple/blue gradients, glassmorphism, grid of identical cards, emoji/default SF Symbols, default system font, centered hero + three cards, same corner radius everywhere, fake 3D).
5. Output the 3 directions as structured image prompts that Jakub can paste into Gemini or ChatGPT image generation. Save them to `docs/design/DIRECTIONS.md` (create the folder) and commit.

## Acceptance criteria

- [x] 3 distinct visual directions produced.
- [x] Each direction covers play screen + library screen.
- [x] None of the directions violate the reject list.
- [x] Prompts are clear enough for Jakub to generate images from them.
- [ ] Jakub picks one direction (this ticket is done when prompts are delivered; Jakub decides).

## Agent assignment

- **Agent**: Claude Opus 4.6 Thinking (Antigravity, account B) with the imagegen-frontend-mobile skill. Run before 2 Nov 2026; after that use Gemini 3.8 Flash High.
- **Reasoning**: Creative design work requiring the specialised image generation skill.

## Done rule

This ticket is done when the 3 direction prompts are delivered. Jakub generates images and picks one. No build step.

## Delivery

Delivered in [DIRECTIONS.md](../design/DIRECTIONS.md): Signal Panel, Practice Ledger, and Open Cue. Each direction includes a self-contained image prompt for Play and Library, palette and typography choices, and the full reject list. Font license sources are linked. Image generation and direction selection remain with Jakub.

The previous prompt set is preserved unchanged in [DIRECTIONS-previous.md](../design/DIRECTIONS-previous.md).
