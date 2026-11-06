# 112 — Home pads: new look (proposal A + light bar from proposal B)

Status: ready-for-agent. Source: Jakub, 2026-11-06, after ticket 111: "I like proposal A, but instead of the orange dot in the corner I want the orange line from proposal B." Radius: pads slightly rounded (exception to ticket 94, Home pads only).

Spec = the preview `docs/design/2026-11-06-home-pads-and-motion/proposal-a.html` (open it in a browser) and the README in the same folder. Take everything from A **except** the lit-state corner dot.

## What to build (pad look and press only; no screen transitions, those are ticket 113)

1. **Pad material (A)**: 8 pt radius as a named token `Theme.Radius.pad`, two-tone bevel (soft light top edge, 2 px darker bottom edge), light and dark appearance, app palette only (tickets 92, 39). Hero pad (Continue / TODAY) keeps the orange fill and stands out as today.
2. **Lit state (changed from A)**: when Training has reviews due, the Training pad keeps A's orange rim and soft glow, but the **round LED dot in the top-right corner is NOT used**. Instead use **B's light bar**: a 2 pt orange line along the top edge of the pad, inset about 22 % from each side, with a soft glow and a slow breathing opacity (about 0.45 ↔ 1.0, 3.2 s ease-in-out). See `.light-bar` and `@keyframes barBreathB` in `proposal-b.html` (lines ~660–675) and the `<div class="light-bar">` in the Training pad. If a ring plus bar looks too busy on the real iPad, keep the bar and drop the glow; list that in the report.
3. **Press feedback (A)**: scale 0.965 and 1.5 pt down, 60 ms light flash across the pad, spring back in 0.18 s. Replaces the current `TactilePadButtonStyle` look (0.97, darker fill).
4. **MIDI hit**: if the Home screen already reacts to a hit on the controller (ticket 73), make that reaction use the same press and flash. Do not add new MIDI logic.
5. **Grid boot (A)**: after the launch animation the 8 pads light up in a diagonal wave from top-left to bottom-right, 40 ms between neighbours. The logo tile is not part of the wave.
6. **Reduce Motion**: no scale, no movement, no breathing, no wave. Press = darker fill only (0.1 s). Lit state = static bar. Grid appears with a 0.2 s fade. Use the existing helper from ticket 27 (`Theme.Motion.Policy`, `.motion(_:value:)`); do not scatter `if reduceMotion`.
7. Motion tokens in `Theme.Motion`: `padPress`, `padFlash`, `ledBreath` (name kept, it now drives the bar), `bootStagger`, with the durations above.

## Rules

- Only Home pads change shape. Buttons, panels, cards, the logo tile and Library/Practice stay as they are (ticket 94).
- Do not touch Practice drawing, timing, audio, scoring.
- No new user-facing text. Accessibility labels of pads stay.
- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).

## Files to read

`AGENTS.md`, this ticket, tickets 27, 73, 92, 94, `docs/design/2026-11-06-home-pads-and-motion/README.md`, `proposal-a.html` (pad CSS, press, boot), `proposal-b.html` (light bar only), `SmackAPad/Sources/UI/HomeScreen.swift` (`TactilePadButtonStyle`, `HomePadView`, grid), `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [ ] Pads look like proposal A in light and dark; radius from `Theme.Radius.pad`.
- [ ] Training pad with due reviews shows the top light bar, no corner dot.
- [ ] Press, flash and spring match A; Reduce Motion variant works.
- [ ] Grid boot wave plays once after launch, not on every return to Home.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: landscape and portrait, light and dark, hit pads by finger and by controller, turn Reduce Motion on and check.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: SwiftUI styling against a finished HTML preview; high thinking because of the press, flash and boot timings and the Reduce Motion variants.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
