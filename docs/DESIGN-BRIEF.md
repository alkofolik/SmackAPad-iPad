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
- Clean, eyes-off. Pattern shown as pad names, not a visual grid. Small optional pad-layout thumbnail.
- Timing feedback must be readable peripherally (colour + position + size), never tiny text, never flashing.

## Look
- Dark theme by default. One base colour, one accent, two status colours (good / miss). All defined once as tokens in Theme.swift.
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
