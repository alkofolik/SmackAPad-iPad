# 11 — Theme.swift + Shared Components + Play Screen

Status: ready-for-agent

## Goal

Convert the chosen design direction (from ticket 10) into SwiftUI code: a `Theme.swift` token file, shared UI components, and the main play screen.

## Files to read

- `AGENTS.md`
- `docs/DESIGN-BRIEF.md`
- `docs/SPEC.md` (§3.8 Screens — play screen description)
- `docs/DECISIONS.md` (§3 Play screen, §20 Visual design)
- The chosen design direction images/description from ticket 10.

## Tasks

1. Create `Theme.swift` with all design tokens: base colour, accent, status colours (good/miss), typography (display face + text face), spacing, corner radii.
2. Build shared components: buttons, cards, timing feedback indicator, pad-layout thumbnail.
3. Implement the play screen:
   - Clean, eyes-off design.
   - Pattern display shows pad names, not a visual grid.
   - Current BPM display (large, readable from arm's length).
   - Score and timing feedback (colour + position + size, readable peripherally).
   - Optional small pad-layout thumbnail (user setting).
4. Check against the reject list in DESIGN-BRIEF.md.

## Acceptance criteria

- [ ] Theme.swift defines all tokens (colours, fonts, spacing) in one place.
- [ ] Play screen displays pattern, current BPM, timing feedback.
- [ ] Timing feedback readable peripherally (no tiny text, no flashing).
- [ ] Dark theme by default.
- [ ] No violations of the "AI look" reject list.
- [ ] **iPad test**: all screens render correctly on iPad, landscape and portrait.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high (with gpt-taste skill)
- **Reasoning**: Converting visual design to production SwiftUI. Requires design sensitivity.

## Done rule

Stop after successful build; Jakub tests on iPad.
