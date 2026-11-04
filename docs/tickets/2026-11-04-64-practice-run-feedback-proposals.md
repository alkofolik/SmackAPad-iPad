# 64 — Practice: run countdown, per-run result and star moment — design proposals (no app code)

Status: ready. Source: Jakub, 2026-11-04. Follow-up: an implementation ticket after Jakub chooses.

## Problem

While playing, the player's eyes are on the pads; the iPad is glanced at from arm's length.

1. **How much of the measured run is left** is hard to see: today a thin full-width line with bar ticks (ticket 35) and a small text counter "2/4" (repetition within the run, ticket 59).
2. **How each run went, and whether it counted** toward a star, is shown only as small text ("1 / 3" consecutive passes) or after the lesson ends.
3. **Earning the first star** (and any star that does not stop the lesson) passes almost unnoticed: `StarAward.shouldStop` stops only for stars 2 and 3, star 1 just fills in the result row.

## Goal

Three proposals for one coherent set of indicators, **without text or numbers** for 1 and 2:

1. **Run countdown**: glanceable remaining part of the current measured run (run = `repeatsPerRun × lesson.bars` bars, about four). Readable in peripheral vision; the last bar of a run must be recognisable before it starts. Replaces the "2/4" text and the thin line.
2. **Per-run result**: when a run ends, a mark for that run: passed / not passed, and whether it **counted toward the star being worked on** (`starRunProgress`: `count / required` consecutive or accumulated runs; Learning keeps credit, Challenge resets on a weak run — both must be visible). Replaces the "1 / 3" text. Optionally a live hint during the run (e.g. bars that already went wrong), only if it stays calm.
3. **Star moment**: a short animation when any star is earned **while the lesson keeps running** (mainly star 1): visible, pleasant, at most about 1 s, does not cover the pattern, does not shift the layout, does not pause or delay the next run. For stars 2 and 3 (which stop the lesson) keep the existing result flow, but the moment should look like the same family.

## Rules for the design

- Do not change scoring, star thresholds, run length or tempo steps; only how they are shown.
- Never cover the orange pattern band or the accuracy number; no layout jumps; nothing flashing (Jakub found per-hit shapes stressful, ticket 35).
- Palette and tokens from `Theme.swift` only (orange, black, white, derived greys; `markCorrect`/`markOff`/`markWrong` only where they already mean result marks). IBM Plex. Design-brief reject list applies.
- Shapes should come from the app's own language: pads, LED-like segments, band cells, the bar grid. No generic progress rings, no confetti, no trophies, no emoji.
- Landscape primary, portrait supported (see `docs/design/2026-11-03-portrait-practice-layout.md`).
- Reduce Motion: no movement; state changes by fill/opacity only.
- VoiceOver: each indicator has a spoken value (the text you remove becomes its accessibility value).

## Deliverables (in `docs/design/2026-11-04-practice-run-feedback/`)

1. **Three clearly different proposals** as self-contained HTML previews (offline; Plex fonts from `SmackAPad/Resources/Fonts/` by relative path or embedded). Each simulates a real session on the practice screen: count-in, a 1-bar lesson played as 4-bar runs, several runs with mixed results, a star 1 earned mid-session, and the next run continuing.
   - Switches: landscape / portrait, light / dark, Reduce Motion, Learning / Challenge mode, "star 1 needs 3 runs" (intro lesson) / "needs 1 run".
   - Replay button.
2. `README.md`: one paragraph per proposal, a storyboard of the star moment with timings, how each maps to SwiftUI (one line), **one recommendation** with reasons, open questions.
3. Do not copy the wordmark or logo SVGs from older HTML proposals (their viewBox is wrong); the logo is not needed here.

## Files to read

`AGENTS.md`, `docs/DESIGN-BRIEF.md`, `docs/design/2026-10-30-practice-screen-spec.md`, `docs/design/2026-11-03-portrait-practice-layout.md`, `docs/design/mockups/` (images), `docs/tickets/2026-11-02-35-practice-indicators.md`, `docs/tickets/2026-11-03-59-four-bar-runs.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (header with `repetitionProgress`, `starRunProgress`), `SmackAPad/Sources/UI/PracticeSession.swift` (same properties, `StarAward`, `starEvent`), `SmackAPad/Sources/UI/StarStreak.swift`, `SmackAPad/Sources/UI/StarAward.swift`, `SmackAPad/Sources/UI/StarBurst.swift`, `SmackAPad/Sources/UI/Theme.swift`. Read the rules of the `design-taste-frontend` skill only; do not run its scripts or browser steps.

## Acceptance criteria

- [ ] Three previews run offline with all switches and Replay.
- [ ] No text or numbers in the run countdown and the per-run result.
- [ ] Learning vs Challenge difference is visible in the per-run result.
- [ ] Star moment ≤ about 1 s, the next run starts on time, nothing covers the band.
- [ ] README with recommendation and open questions.
- [ ] No file outside `docs/design/2026-11-04-practice-run-feedback/` is changed.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking: a taste task on the most important screen, and the three proposals must really differ. If the previews look generic or do not run after one revision, hand over to **Codex GPT-6.1 Sol, high**.

## Done rule

Stop after the deliverables exist; do not commit. Jakub reviews, Claude commits afterwards.
