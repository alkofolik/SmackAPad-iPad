# 146 — Badges as pad tiles with icons (variant B)

Status: done. Source: Jakub, 2026-11-07, chose variant B in ticket 145. Preview: `docs/design/2026-11-07-badge-images/badge-images.html` (section "Varianta B"); open it in a browser, light and dark.

## Goal

The Badges screen becomes a grid of square pad-style tiles, each with an icon. An earned badge lights up like a pressed pad. Tier stays as 1–3 LED dots.

## Icons

1. The 23 icons are ready as SVG files in `docs/design/2026-11-07-badge-images/icons/` (`badge-<name>.svg`, 24×24, black stroke). Add each to `Assets.xcassets` as an image set named `badge-<name>`: **Preserve Vector Data** on, **Render As Template Image**. Do not redraw them.
2. Add an optional `icon` field to every entry in `badges.json` and to `BadgeDefinition` (`decodeIfPresent`). Fallback when missing: the group icon.

| Badges | Icon |
|---|---|
| group `passed` | `pad` |
| group `mastered` | `metronome` |
| group `memory` | `eye` |
| group `courses` | `flag` |
| group `levels` | `stairs` |
| `genre-rock` · `genre-funk` · `genre-jazz` · `genre-hiphop` · `genre-world` · `genre-electronic` · `genre-pop` | `bolt` · `sine` · `note` · `mic` · `globe` · `square` · `heart` |
| `tech-basic` · `tech-sixteenths` · `tech-ghost` · `tech-swing` · `tech-fills` | `four` · `sixteen` · `ghost` · `triplet` · `tom` |
| `review-*` | `review` |
| `settled-*` | `lock` |
| `bounce-back` | `bounce` |
| `mix-*` | `shuffle` |
| `after-me-*` | `ear` |
| `training-days-*` | `calendar` |

## Tile (one reusable view, e.g. `BadgeTile`)

1. Square-ish tile (width : height about 1 : 1.08), pad corner radius and the pad bevel (`Theme.padBevelTop` / `padBevelBottom`), as the Home pads.
2. Top left: tier LED dots (6–7 pt). Centre: icon about 52 pt. Bottom: name, max 2 lines, then a thin progress bar (unearned) or the earned date (earned, small monospaced).
3. **Unearned:** icon and name in `Theme.secondary` at reduced opacity, dots `Theme.hairline`, progress bar in `Theme.orange`.
4. **Earned:** dark cavity fill (same in light and dark mode), 2 pt `Theme.orange` edge with a soft orange glow, icon and dots in `Theme.orange` with a slight glow, name in cream. No new colours.
5. **Tap** opens a small detail (popover on iPad): large icon, name, condition, "Earned: …" or "Progress: x / y". This replaces the condition line of today's row.
6. Accessibility: one element per tile with name, condition and state; the tile is a button.

## Where

1. `BadgesScreen.swift`: keep the group headers; each group is an adaptive grid (minimum tile width about 150 pt, 14 pt spacing). Replaces `BadgeRowView`.
2. `BadgeBanner.swift`: show the badge icon (lit style) in the banner next to the name.
3. Training page badge section (`TrainingScreen.swift`, "Training badges"): use the same tile, smaller (minimum width about 120 pt), if it fits the existing layout without changing other sections; otherwise only add the icon to the existing rows.
4. Badge rules, evaluation and storage stay unchanged.

## Files to read

`AGENTS.md`, this ticket, the preview HTML (variant B section and CSS `.tile`), `docs/design/2026-11-07-badge-images/icons/`, `SmackAPad/Sources/UI/BadgesScreen.swift`, `SmackAPad/Sources/UI/BadgeBanner.swift`, `SmackAPad/Sources/UI/TrainingScreen.swift` (badge section only), `SmackAPad/Sources/Progression/BadgeModel.swift`, `SmackAPad/Resources/Data/badges.json`, `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Sources/UI/HomeScreen.swift` (pad look only), `Assets.xcassets`.

## Acceptance criteria

- [x] Every badge shows its icon; earned tiles light up, unearned tiles are dim with progress.
- [x] Tap shows the condition and progress or date.
- [x] Banner shows the icon.
- [x] Light and dark mode, landscape and portrait, Czech names fit in 2 lines (longest: "Dvě stě padesát v tempu", "Jazz a New Orleans – hotovo").
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: open Badges, tap a few tiles, earn a badge and see the banner.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: display only; icons are ready, one reusable view.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
