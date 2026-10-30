# 11 — Theme.swift + Shared Components + Play Screen

Status: ready-for-agent

## Goal

Convert the chosen design direction (from ticket 10) into SwiftUI code: a `Theme.swift` token file, shared UI components, and the main play screen.

## Files to read

- `AGENTS.md`
- `docs/DESIGN-BRIEF.md`
- `docs/SPEC.md` (§3.8 Screens — play screen description)
- `docs/DECISIONS.md` (§3 Play screen, §20 Visual design)
- `docs/design/2026-10-30-practice-screen-spec.md` (play screen decisions; this overrides older wording)
- The mock-up images in `docs/design/mockups/` (static and scrolling views, dense variants, legend). Ticket 10 is superseded; no direction choice is needed.

## Tasks

1. Create `Theme.swift` with all design tokens: the three colours (orange, black, white) with light and dark variants, typography (display face + text face), spacing, corner radii. No status colours (good/miss).
2. Build shared components: buttons (START / STOP / RESTART), pattern block, bar header with verdict word, summary strip with stars, pad-layout grid.
3. Implement the play screen exactly as specified in `docs/design/2026-10-30-practice-screen-spec.md` (source of truth). Summary:
   - Orange pattern field with a grid; hit = solid block with the pad abbreviation, hand by colour (white = right, black = left); no row labels (pad names are in a Legend); static and scrolling views; static shows 1, 2 or all bars.
   - Small BPM and score, no per-hit feedback; one-word verdict per bar; summary strip with three stars at the end.
   - START that turns into STOP (about 60 %) + RESTART; Listen / Play switch; From memory toggle (pattern hidden only after START and only in From memory).
   - Tempo changeable only while stopped; automatic increase after a clean pass.
   - The 4x4 pad-layout grid is hidden by default; a Settings option shows it small inside the lesson.
   - Dependencies: bar verdicts come from the scoring bar summary (separate ticket); the memory star needs a `memory` flag in the progress model (coordinate with tickets 04/05, SPEC §4.3).
4. Check against the reject list in DESIGN-BRIEF.md.

## Acceptance criteria

- [ ] Theme.swift defines all tokens (colours, fonts, spacing) in one place.
- [ ] Play screen matches `docs/design/2026-10-30-practice-screen-spec.md`: pattern grid with abbreviations, static and scrolling views, START / STOP + RESTART, Listen / Play, From memory, per-bar verdict, end summary strip with stars.
- [ ] No per-hit feedback; per-bar verdict is quiet and readable (no tiny text, no flashing).
- [ ] Dark theme by default.
- [ ] No violations of the "AI look" reject list.
- [ ] **iPad test**: all screens render correctly on iPad, landscape and portrait.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high (with gpt-taste skill)
- **Reasoning**: Converting visual design to production SwiftUI. Requires design sensitivity.

## Done rule

Stop after successful build; Jakub tests on iPad.
