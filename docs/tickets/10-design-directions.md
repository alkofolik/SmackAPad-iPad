# 10 — Design Directions (3 Visual Concepts)

Status: ready-for-agent

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
5. Output the 3 directions as structured image prompts that Jakub can paste into Gemini or ChatGPT image generation.

## Acceptance criteria

- [ ] 3 distinct visual directions produced.
- [ ] Each direction covers play screen + library screen.
- [ ] None of the directions violate the reject list.
- [ ] Prompts are clear enough for Jakub to generate images from them.
- [ ] Jakub picks one direction (this ticket is done when prompts are delivered; Jakub decides).

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high (with imagegen-frontend-mobile skill)
- **Reasoning**: Creative design work requiring the specialised image generation skill.

## Done rule

This ticket is done when the 3 direction prompts are delivered. Jakub generates images and picks one. No build step.
