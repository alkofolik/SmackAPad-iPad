# Motion proposals — display and transition animations (draft for Jakub's approval)

Status: proposal, 2026-11-01. Nothing implemented. If approved it becomes ticket 27 and runs **after** tickets 24-26 (it depends on the shared components from 25).

## Principles

- Decent, modern, short: 150-350 ms, ease-out or a light spring (response 0.4, damping 0.8). Nothing bounces more than once.
- Three colours only; motion carries meaning (something appeared, changed, was earned), never decoration.
- **Never animate anything timing-critical**: the position marker, hit judging and the Canvas pattern stay exactly as they are (drawn from the audio clock). Animations live in the chrome around them.
- **Reduce Motion**: every movement or scale becomes a plain opacity change of at most 0.2 s; pulses and springs are removed.
- One token set in `Theme`: `Motion.fast 0.15`, `Motion.standard 0.25`, `Motion.emphasis` (spring), so all screens move alike.

## Proposed animations

| # | Where | Animation | Value |
|---|---|---|---|
| 1 | Library -> Practice | Lesson opens with a zoom from the tapped row (iOS zoom navigation transition) instead of the default slide-up cover; fallback fade + scale 0.98 | Feels connected to the row |
| 2 | Practice -> Library | Reverse zoom; the row's stars update right after (see 5) | |
| 3 | Switching Path / Genres / Techniques and groups | Content cross-fade 0.2 s with a 6 pt rise | Calmer than an instant jump |
| 4 | Level / stage disclosure | Smooth expand and collapse, chevron rotates | |
| 5 | New star in a library or Intro row | When returning from practice the new star fills with a small scale pop, once | Makes the reward visible |
| 6 | Progress lines (group, stage unlock) | Fill animates 0.4 s on appear and on change | |
| 7 | Filter chips and counters | Selected state fades in 0.15 s; counts roll (numeric text transition) | |
| 8 | Unlock banner | "Unlock" -> "Really?" swaps in place (cross-fade); after unlocking the banner collapses and the lock icons turn to open and fade | |
| 9 | START / STOP | Buttons morph in place (width change + cross-fade) rather than swap abruptly | |
| 10 | Count-in numerals | Each numeral scales 1.15 -> 1.0 while fading in on its beat (pattern stays dimmed) | |
| 11 | Hit colours on the pattern | Colour transitions in about 0.12 s instead of snapping; the trailing tail from ticket 24 fades 0.25 s | Smoother, still readable |
| 12 | Tempo up | The tempo number rolls (numeric text) and the field pulses once; banner from ticket 24 fades | |
| 13 | Star earned | Existing `StarBurst`; add staggered fill of the stars (80 ms apart) and a soft fade of the pattern behind it | |
| 14 | End-of-run strip | Slides up from the bottom with a light spring, stars fill in sequence | |
| 15 | Settings, sheets, popovers | Keep system sheet/popover motion; only inner toggles and rows use `Motion.fast` | Consistency without fighting iPadOS |

## Cost and risk

- Items 1, 3-8, 15: small, SwiftUI only, low risk.
- Items 9-14: touch the practice screen; must be checked on the iPad for dropped frames (the pattern redraws at 60 fps). Rule: if frame time suffers, the animation is dropped, not the pattern.
- Item 1 needs iPadOS 18 for the zoom transition; check the deployment target and use the fallback below it.

## Suggested ticket 27

Agent: Claude Opus 4.6 (Antigravity), **medium** thinking (many small, well-specified changes; the risky ones are listed above). Acceptance: each item switchable off by Reduce Motion, no change in scoring or timing tests, iPad check of 60 fps during a 4-bar scrolling run.
