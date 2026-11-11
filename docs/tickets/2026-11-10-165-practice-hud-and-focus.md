# 165 — Practice screen: timing cue B1, run progress C2 and focus mode

Status: implemented. Approved by Jakub on 2026-11-10. Follows design ticket 164 (`docs/design/2026-11-10-164-practice-hud-and-focus.md`, previews in `docs/design/previews/164/`). Jakub chose **B1 (Gliding Horizon Pip)** and **C2 (Stepped LED Meter)**. Sizes, BPM priority and focus layout below are updated by ticket 171 and its approved variant B (2026-11-11).

## Goal

While drumming, the practice screen shows only what the drummer needs: the band, a calm timing cue, a clear run-progress meter, a small BPM readout, the pad grid and STOP/RESTART. Everything else fades out on START and comes back on STOP or when the run ends.

## Rules

### A. Remove the per-hit timing line
- Delete `HitTimingBar` (`PracticeComponents.swift` ~325) and its use in `PracticeScreen.swift` (~513–523). This also removes the "Early %lld ms" / "Late %lld ms" / "Centred" read-out it carries.
- Keep `HitTimingPlot` in the result Detail sheet unchanged.
- `TimingHistory.tendency` (and its `Tendency` enum) is used only by `HitTimingBar`. Delete it and `testTendencyUsesMedianOfLastEightHitsAndStrictCentredThreshold` in `TimingHistoryTests.swift`; the new cue value below replaces it.
- Remove localization entries that become unused only if no other code uses them (check `Early`, `Late`, `On time`, `Hit timing`, `Centred` — `HitTimingPlot` still uses some).

### B. Timing cue B1 (Gliding Horizon Pip)
- New pure function on `TimingHistory` (in `FeedbackWindow.swift`), e.g. `cueOffset(at date: Date) -> Double`, returning −1 … +1:
  - median error of the last 8 samples that are younger than 3 s; needs at least 3 samples, else 0;
  - inside the deadband (|median| ≤ 40 % of the good window, the same threshold `BandTone.edgeTendency` uses today) → exactly 0;
  - outside: scaled linearly from the deadband edge to the maximum window, clamped to ±1;
  - negative = ahead / rushing, positive = behind / dragging. No quantising.
- New view `TimingCue` (in `PracticeInstruments.swift`): 180×30 pt recessed capsule (`Theme.surface`, hairline), 2×20 pt centre notch, faint deadband marks, 14×20 pt capsule pip. Scale with Dynamic Type. Pip travel = offset × (half-track minus half-pip). Pip is `Theme.orange` when offset is 0, `Theme.ink` otherwise.
- Motion: spring `response 0.35, dampingFraction 0.78` on the offset. Reduce Motion: no spring, plain 0.15 s opacity cross-fade between positions (or instant).
- Feed it once per frame from the existing `TimelineView` in `PracticeScreen` only while scoring (`scored` is true); otherwise offset 0 and the cue is dimmed (opacity ~0.35) while the HUD is shown. The idle Play HUD is removed under ticket 171.
- Accessibility: one element, label reuses the existing `"Hit timing"` string; value reuses existing words (`"Early"` / `"On time"` / `"Late"`). No new strings.
- **Retire `BandEdgeGlow`.** Delete the view and `BandTone.edgeTendency` (`PracticeInstruments.swift` ~96–130), the `edgeTendency` parameter of `PatternField` (`PatternField.swift` 97, 190) and the argument in `PracticeScreen.swift` 493.
- `HelpIllustration.swift` 240 also uses `BandEdgeGlow` in the "signals" help example: replace that overlay with a `TimingCue` placed above the example band, animated between ahead and behind with the same `progress` input. Note the old glow used *right = ahead*; the new cue uses *left = ahead*. Swap the arrow symbols on the `help.signals.behind` / `help.signals.ahead` tags so they match (behind → `arrow.right`, ahead → `arrow.left`). Do not change help text (ticket 169 rewrites it).

### C. Run progress C2 (Stepped LED Meter)
- Replace `LapVaultView` (`PracticeInstruments.swift` 486–641) with a new `RunMeterView`. Delete `LapVaultView`. Same place in `PracticeScreen` (the top-trailing overlay, still alternating with `MemoryPhaseChip`).
- Data, all existing, no rule changes:
  - target star: `starRunProgress.starIndex` (0 → ★ 1, 1 → ★ 2); show a compact badge "★" + number (digits only, no new words);
  - `required` vertical blocks (1–4), each block = 3 stacked micro-steps, 40 pt tall and 22 pt wide in total, scaled with Dynamic Type;
  - banked: the first `count` blocks are fully lit (`Theme.ink`; `Theme.orange` while `starMomentActive`, as today);
  - active block (index `count`, only if `count < required`) lights its micro-steps from the bottom as the current run elapses: step 1 at ⅓, step 2 at ⅔, step 3 at the end of the run.
- Live run fraction: new pure function, e.g. `PracticeSession.runFraction(tapePosition:totalSteps:repeatsPerRun:) -> Double` = `(tapePosition mod (repeatsPerRun × totalSteps)) / (repeatsPerRun × totalSteps)`, clamped 0…1, and `0` during count-in or when not scoring. A helper `litMicroSteps(fraction:) -> Int` (0…3) gives the active block's lit steps. Pass the fraction from the existing `TimelineView` frame.
- Verdict behaviour (from `session.lastVerdict`, as `LapVaultView` does today):
  - Learning, unclean run: banked blocks stay lit; only the active block drains to empty (0.20 s ease-out).
  - Challenge, `brokenStreak`: all blocks drain to empty together (0.20 s ease-out), with the existing short `Theme.markWrong` outline flash.
  - Clean run: the active block locks full (0.15 s snap), the next block becomes active.
  - Reduce Motion: opacity changes only, no scale.
- Keep the existing accessibility label `"Consecutive passes for %@"` and value `"%lld of %lld"`.
- Drop the old verdict flag and notch marks; the block behaviour replaces them.

### D. Focus mode
- `focusActive = session.running && !session.listen` (from the moment START is pressed, so during count-in too). Listen mode keeps full chrome.
- On START, fade and collapse the whole top bar (`libraryButton`, `titleAndSubtitle`, `modeButtons`, `patternTools`, `helpTools`) and show the HUD. Fade `tempoSquare` in place and disable its input and accessibility while hidden.
- The band may move or resize with one `Theme.Motion.standard` (0.25 s ease-out) transition at START and STOP. Reduce Motion: instant geometry changes. Do not change the layout again when count-in ends.
- New quiet BPM readout, visible only in focus mode, at the left end of the HUD row above the band: current tempo number in bold `Theme.display(28)`, with monospaced digits plus the existing unit text used by the tempo tile. No new strings. It must follow tempo-up steps.
- HUD row above the band: BPM left, `TimingCue` centred, `RunMeterView` right, with at least 64 pt height scaled with Dynamic Type. BPM is never hidden. Notices use a separate row; on narrow windows move the cue below BPM and the meter. Nothing may overlap the band. Remove the unused HUD space in idle Play; Listen keeps its chrome.
- Stays visible and working: band with count-in numerals, star moment beam, tempo-up banner, badge banner, `PlayingLastRunChip`, pad layout square, transport square (STOP/RESTART).
- Return to full chrome on STOP and when the run ends (also Mix auto-finish from 168), same 0.25 s ease-out. Reduce Motion: 0.15 s opacity or instant.
- MIDI transport and pad input work unchanged during focus mode (no input code changes).

### General
- Three colours only, IBM Plex Sans, `Theme.swift` tokens, motion from `docs/design/2026-11-01-motion-proposals.md`. No new UI text. Nothing flashes per hit.
- Must work with 1–4 bars, scrolling and static view, Listen and Play, After me, From memory, section loop, Mix, portrait and landscape, narrow window, Czech.
- No changes to `StarStreak`, scoring or `starRunProgress`.

## Files to read

- `AGENTS.md`
- `docs/design/2026-11-10-164-practice-hud-and-focus.md`
- `SmackAPad/Sources/UI/PracticeScreen.swift`
- `SmackAPad/Sources/UI/PracticeInstruments.swift`
- `SmackAPad/Sources/UI/PracticeComponents.swift` (only `HitTimingBar`, ~325–405)
- `SmackAPad/Sources/UI/PatternField.swift` (only `edgeTendency`, 97 and 190)
- `SmackAPad/Sources/UI/FeedbackWindow.swift`
- `SmackAPad/Sources/UI/HelpIllustration.swift` (only `signalsExample`, ~235–242)
- `SmackAPad/Sources/UI/PracticeSession.swift` (only `repeatsPerRun`, `starRunProgress`, `tapeFrame`, `RunVerdict`)
- `SmackAPadTests/TimingHistoryTests.swift`

## Tests

Use the tdd skill (timing code).

1. `TimingHistory.cueOffset`: fewer than 3 recent samples → 0; samples older than 3 s ignored; median inside the deadband → exactly 0; early median → negative, late → positive; large error clamps to ±1; uses only the last 8 samples.
2. `runFraction`: 0 at run start, 0.5 halfway through a run with `repeatsPerRun` 2, wraps to 0 at the next run; `litMicroSteps` gives 0, 1, 2, 3 at the thirds.
3. Delete the old `tendency` test (rule removed).

Then run the full test suite.

## Acceptance criteria

- [ ] `HitTimingBar`, `TimingHistory.tendency`, `BandEdgeGlow`, `BandTone.edgeTendency` and `LapVaultView` are gone; no dead code or tests left for them.
- [ ] `HitTimingPlot` still shows in the Detail sheet.
- [ ] Timing cue glides left when ahead, right when behind, sits orange at centre when on time; no numbers, no flicker.
- [ ] Run meter shows the target star, `required` blocks, banked blocks lit and the active block filling in 3 steps during the run.
- [ ] Learning: failed run empties only the active block. Challenge: broken streak empties all blocks.
- [ ] On START the top bar and tempo square fade out; on STOP / run end they fade back; the band moves or resizes smoothly once.
- [ ] Focus mode shows the BPM readout and it follows tempo-up.
- [ ] Help "signals" example uses the new cue with matching arrows.
- [ ] Build succeeds and the full test suite passes.

### Manual iPad checks for Jakub

1. Open a lesson, press START: top bar collapses, tempo button fades out, and the orange band uses the remaining space with one smooth transition.
2. Play deliberately early, then on time, then late: the pip glides left, settles orange in the middle, glides right; calm, no jumping per hit.
3. Watch the meter: the active block fills bottom-up in 3 steps during each run; a clean run locks it.
4. Learning mode: play one bad run — earlier blocks stay. Challenge mode: bad run — all blocks empty.
5. Press STOP (on screen and from the MIDI controller): everything returns smoothly.
6. Repeat 1 in portrait and in a narrow split window, Czech language: nothing overlaps the band.

## Agent assignment

Codex GPT-6.1 Sol, high (layout stability plus timing state). Fallback: Gemini 3.8 Flash, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
