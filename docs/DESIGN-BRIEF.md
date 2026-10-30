# DESIGN-BRIEF — Smack-a-Pad iPad

Status: draft by Claude Pro. Dials are proposals; Jakub decides.

## Dials
VARIANCE 7 / MOTION 3 / DENSITY 4

## Feel
A practice instrument for finger drummers. Closer to hardware (pads, LEDs, printed labels) than to a gamified kids app or a SaaS dashboard. Calm, confident, a bit raw. No mascots, no confetti.

## Context of use
- iPad on a stand or table next to a MIDI controller, landscape primary, portrait supported.
- Viewed from arm's length and mostly glanced at: the player's eyes are on the pads.
- So: big type for BPM and the next hit, high contrast, readable in dim studio light, large touch targets for navigation.

## Play screen
- Minimal chrome, pattern first. Pattern is the dominant element of the play screen and always visible: a grid with one row per used pad and one column per sixteenth step, count labels 1 e & a, beat starts emphasised. A hit is a cell carrying the pad abbreviation; the hand is shown by cell colour (white = right, black = left) and the currently playing cell is outlined. User-selectable modes: **static** (the whole pattern visible, a position marker moves) and **scrolling** (the pattern moves past a fixed hit marker). 1 bar = one block across the width; 2-4 bars = blocks stacked or 2x2 with the current bar emphasised; longer patterns and whole tracks = pages of 4 bars or scrolling, with a thin overview strip of the whole track. Everything else (score details, settings, section loop) is hidden but one touch or gesture away. The 4x4 pad-layout grid is hidden by default; a Settings option shows it small and unobtrusive in the lesson.
- No per-hit feedback. Feedback is one quiet word per bar (clean / ahead / behind / uneven) in the bar header, plus a small summary strip at the end. Never tiny text, never flashing. A hit cell shows the pad abbreviation, the hand by cell colour (white = right, black = left), the playing cell is outlined. See `docs/design/2026-10-30-practice-screen-spec.md`.

## Look
- Exactly three colours: orange, black, white (plus greys derived from them). Dominant element: a strong orange band that carries the pattern and is seen first. Light variant: white background, black text. Dark variant: black background, white text. Layout is designed from scratch, not copied from the legacy tool; only the orange band with the pattern is fixed. There is no per-hit feedback and no status colours; feedback is a one-word verdict per bar. All colours defined once as tokens in Theme.swift.
- A deliberate type choice (a display face plus a text face). Fonts must be embeddable in an app by licence.
- Motion only where it carries meaning: hit feedback, count-in, screen changes. Nothing decorative.

## "AI look" reject list (any one of these = redo)
- Purple/blue-violet gradients, mesh gradients, neon glow on black.
- Glassmorphism / blur cards everywhere.
- Uniform grid of identical rounded cards with soft shadows.
- Emoji or untouched default SF Symbols as the icon language.
- Default system font with no typographic decision.
- Centered hero + three feature cards layout.
- Same corner radius on everything; fake 3D.

## Process
1. imagegen-frontend-mobile produces 3 distinct directions as image prompts (Jakub generates the images in Gemini/ChatGPT).
2. Jakub picks one.
3. Codex (gpt-taste) converts it to SwiftUI: Theme.swift, shared components, main play screen.
4. Check against the reject list above.
