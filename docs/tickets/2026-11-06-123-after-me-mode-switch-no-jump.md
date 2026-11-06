# 123 — Mode switch to and from "After me": no jump, smooth like the others

Status: ready-for-agent. Depends on: 122 (same header). Source: Jakub, 2026-11-06, screenshots of Play and After me modes.

## Problem

Switching between Listen / Play is smooth and animated. Switching **to or from After me** makes the whole screen jump: the header, the mode buttons and the toolbar move up/down and the pattern field shifts. Visible causes in the screenshots:
- After me shows an extra line "Poslouchej…" above the field, which pushes the field down.
- The header subtitle changes length ("Jen cvičení · bez hvězd" one line vs. two lines in Play), so the top row changes height and the buttons move.
- The "hide notes" button changes state (greyed) and possibly its size.

## Rules

1. Nothing moves on a mode switch except what is meant to animate. The top row (Knihovna, title, mode buttons, toolbar icons), the pattern field frame and the bottom row keep their exact position and size in all three modes.
2. Reserve fixed space for the After me status line ("Poslouchej…" / "Tvoje řada…") in every mode (empty or hidden with opacity in Listen and Play), or overlay it so it takes no layout space. Fade it in/out.
3. The header has a fixed height (one line subtitle, ticket 122).
4. Use the same animation (curve and duration) as the Listen ↔ Play switch for everything that changes in After me (notes fading out, status line, greyed button). No layout jump in the middle of the animation.
5. Check portrait and landscape.

## Files to read

`AGENTS.md`, this ticket, ticket 122, `SmackAPad/Sources/UI/PracticeScreen.swift`, `SmackAPad/Sources/UI/PracticeComponents.swift`, `SmackAPad/Sources/UI/PatternField.swift`.

## Acceptance criteria

- [ ] Listen ↔ Play ↔ After me in any order: no element jumps, only smooth fades.
- [ ] Same animation style as Listen ↔ Play.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: switch modes several times, portrait and landscape.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: layout stability across states; explicit rules.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
