# 165 — Practice screen: timing cue B1, run progress C2 and focus mode

Status: ready-for-agent. Approved by Jakub on 2026-11-10. Follows design ticket 164 (`docs/design/2026-11-10-164-practice-hud-and-focus.md`), where Jakub selected **Variant B1** (Gliding Horizon Pip) and **Variant C2** (Stepped LED Meter).

## Goal

Implement the new Practice Screen HUD and Focus Mode:
1. **Remove `HitTimingBar`** from `PracticeScreen.swift` (keep `HitTimingPlot` in `sessionResultsView` Detail sheet).
2. **Implement Timing Cue (Variant B1 — Gliding Horizon Pip):**
   - Positioned in the HUD above the band.
   - Smooth gliding pip on a subtle track with a center notch.
   - Smooth rolling median error over 6–8 strikes from `timingHistory` with soft spring motion.
   - Left = ahead / rushing (-ms), right = behind / dragging (+ms), settles dead-center on time (deadband ±12 ms). No numbers, no per-hit flicker.
   - Retire `BandEdgeGlow` (remove from `PatternField.swift`) so the timing cue is the single clear groove indicator.
3. **Implement Run Progress (Variant C2 — Stepped LED Meter):**
   - Replaces `LapVaultView` in `PracticeInstruments.swift`.
   - Shows target star badge (`★ 1` or `★ 2`).
   - Displays `required` vertical block units (from `starRunProgress.required`).
   - Banked qualifying runs are solidly filled (`starRunProgress.count`).
   - Active run fills live with 3 micro-steps per run as sixteenth notes elapse in the current pass (`elapsedSteps / totalSteps`).
   - In Learning mode: on an unclean pass, banked credit stays locked; only the active block recoils to empty.
   - In Challenge mode: on an unclean pass, streak breaks and all blocks drain to 0.
4. **Implement Focus Mode:**
   - When START is tapped and count-in begins (`session.running && !session.listen`), smoothly fade out (0.25 s ease-out) non-drumming chrome:
     - Top bar (back button, title, subtitle, mode buttons, view switches, info, legend, help, tools).
     - Bottom zone stopped tempo button (`tempoSquare`).
   - Keep visible:
     - Stationary orange pattern band (`PatternField` keeps exact position and size; layout does not jump).
     - Minimal Performance HUD above the band: quiet current BPM label (`90 BPM`), Timing Cue B1, Run Progress C2.
     - Pad layout square (lights up hits in bottom-left).
     - Transport square (STOP / RESTART in bottom-right).
     - Live announcements: 4-beat count-in numerals, mid-lesson Star Moment beam, tempo-up banner, badge banner.
   - On STOP or run completion: full chrome smoothly fades back in (0.25 s ease-out).
   - Under Reduce Motion: instant swap / 0.15 s simple opacity fade.
   - MIDI transport: external MIDI commands (start, stop, restart, pad hits) remain fully functional during Focus mode.

## Rules

- Three colours only (orange `#FF6B00`, black, white; light `#F4EFE6` and dark `#1F1D1A`), IBM Plex Sans, existing `Theme.swift` tokens and motion policy from `docs/design/2026-11-01-motion-proposals.md`.
- No new UI text. No live per-hit feedback that flashes.
- Works with 1–4+ bars, scrolling and static view, Listen and Play, From memory, Mix (T168), portrait and landscape, narrow window, Czech strings.
- Band must NOT jump or change vertical position when entering or leaving Focus Mode.
- No rule changes to `StarStreak` or scoring; use existing `PracticeSession` published properties.

## Files to read & touch

- `AGENTS.md`
- `docs/design/2026-11-10-164-practice-hud-and-focus.md`
- `SmackAPad/Sources/UI/PracticeScreen.swift`
- `SmackAPad/Sources/UI/PracticeInstruments.swift`
- `SmackAPad/Sources/UI/PracticeComponents.swift`
- `SmackAPad/Sources/UI/PatternField.swift`
- `SmackAPad/Sources/UI/PracticeSession.swift`
- `SmackAPad/Sources/UI/StarStreak.swift`
- `SmackAPad/Sources/UI/StarRequirement.swift`
- `SmackAPad/Sources/UI/Theme.swift`

## Tests

- Add unit test verifying that `starRunProgress` accurately reports target star index (0 or 1), required run count, and banked runs.
- Verify `TimingHistory` median tendency smoothing correctly calculates normalized offsets.
- Verify full test suite passes without regressions.

## Acceptance criteria

- [ ] `HitTimingBar` is completely removed from the live practice screen.
- [ ] `HitTimingPlot` remains in the result Detail sheet.
- [ ] Timing cue B1 (Gliding Horizon Pip) glides smoothly above the band; left=rushing, right=dragging, center=on-time.
- [ ] Run progress C2 (Stepped LED Meter) indicates target star, required runs, banked runs, and fills live during the pass.
- [ ] Learning mode retains banked progress on error; Challenge mode resets to zero.
- [ ] Focus mode fades out top bar and tempo knob during count-in and drumming.
- [ ] Pattern band maintains rock-solid position without jumping when Focus mode activates or deactivates.
- [ ] Pressing STOP or finishing a run restores full toolbar and controls.
- [ ] Reduce Motion uses simple opacity change without spatial animation.
- [ ] MIDI transport controls remain active during Focus mode.
- [ ] Full test suite passes.

### Manual iPad checks for Jakub

1. Open a lesson and press START: verify top bar and tempo button fade out smoothly, and the orange band stays perfectly in place without jumping.
2. Play early / on time / late: verify the timing pip glides left (ahead) or right (behind) with a calm spring and settles centered when on time.
3. Observe star meter: verify the active block fills step-by-step as you play through the run.
4. Press STOP: verify all navigation and tools return smoothly.

## Agent assignment

Codex GPT-6.1 Sol, high. Visual judgment, layout stability, and timing state integration.

## Done rule

Build, run full test plan per `AGENTS.md`, commit, stop for Jakub's iPad check.
