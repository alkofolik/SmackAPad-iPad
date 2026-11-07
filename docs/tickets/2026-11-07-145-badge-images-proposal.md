# 145 — Proposal: badge images (HTML preview, no code)

Status: resolved — Jakub chose variant B (pad tiles), 2026-11-07. Implementation: ticket 146. Source: Jakub, 2026-11-07. Proposal: `docs/2026-11-07-training-stop-star-list-badges-proposal.md` §4.

## Preview

`docs/design/2026-11-07-badge-images/badge-images.html` (private page: https://claude.ai/artifact/HXWK65xxp7nf8ed7GspLgE). Example data only.

- Icon set: one icon per group; Genres, Techniques and Training get one icon per kind (23 icons). Tier stays as 1–3 LED dots.
- **Variant A** — today's Badges list plus a small engraved plate with the icon on the left; earned = orange icon on a dark cavity plate.
- **Variant B** — grid of pad-style tiles; earned tile lights up like a pressed pad; condition only in a tap detail.

## Next

After Jakub's pick: implementation ticket (icons as vector assets or nearest SF Symbols, Badges screen, earn banner, Training badges on the Training page).

## Agent assignment

- **Agent** (implementation, later): Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: display only; icons and one screen.
