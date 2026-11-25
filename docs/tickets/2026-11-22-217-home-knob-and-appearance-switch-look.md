# 217 — Home: language knob and appearance switch look like real hardware (labels without underline)

Status: done (2026-11-25). Previous: resolved (implemented in code; awaiting Jakub's iPad check). Jakub on 2026-11-22 (iPad review) and approved mockup on 2026-11-22 (design canvas "Smack-a-Pad – návrhy (kolo 22. 11.)", artboards Home and Home dark). **Only the language knob with its labels and the appearance switch change.** The rest of Home (display, faders, pads, buttons, layout) stays exactly as it is.

## Goal

1. Remove the underline under the selected language and the selected appearance. The position of the knob / switch cap alone says what is selected.
2. Labels look like lettering on a real controller.
3. The appearance switch no longer looks like an ugly black bar in light mode.

## Rules

### Language knob (`HomeLanguageKnob` in `SmackAPad/Sources/UI/HomeHardwareControls.swift`)
1. Remove `.underline(...)` from the detent labels (EN / CZ). Behaviour, drag, tap on a label, accessibility and `LanguageKnobMapping` stay unchanged.
2. The knob body is **static**: a fixed groove ring and a fixed shadow. Only the cap and its orange indicator rotate; the ring must **not** rotate with the cap.
3. Draw tick marks around the knob by trigonometry from `LanguageKnobMapping` angles (one tick per language detent, plus a few fine ticks between), positioned on a circle around the groove, not on the cap.
4. Detent labels EN and CZ are printed outside the ticks like panel lettering: condensed bold capitals, wide letter-spacing, small size, adaptive colour (secondary colour at rest). The selected label gets a small LED dot above or below it (orange, lit) instead of an underline; the other label's dot is dark/off. Keep the 44 pt touch target for each label.
5. The word "Language" under the knob stays, in the same lettering style (smaller, secondary colour).

### Appearance switch (`HomeAppearanceSwitch`)
6. Remove `.underline(...)` from the three labels (light / auto / dark).
7. Replace the black capsule track with a **three-position slide switch**: a recessed track in the hardware colours (use the existing `Theme.cavity` / `Theme.HomeController` colours so it matches the knob in both light and dark mode; it must be clearly not black in light mode), three small detent marks, a cap with grip lines that slides between the positions. Keep the existing drag gesture and `AppearanceSwitchMapping`.
8. Labels use the same panel lettering as the knob labels (rule 4). The active position has the same small LED dot above its label.
9. "Appearance" caption in the same lettering style as "Language".

### General
10. Light and dark mode, Czech and English, portrait and landscape, iPad sizes. Nothing else on Home moves: check that heights stay as now (the two controls are 144 pt tall) so the layout does not shift.
11. Do not change MIDI behaviour (ticket 207), localisation keys for the labels, or the saved settings.
12. Reduce Motion: no extra animation beyond what exists; the cap may move without a spring.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/HomeHardwareControls.swift`, `HomeControlMapping.swift`, `HomeScreen.swift` (where the controls are placed), `Theme` colours (`Theme.cavity`, `Theme.HomeController`), `docs/tickets/2026-11-13-206-home-hardware-display-knob-switch.md`.

## Acceptance criteria

- [ ] No underline on any Home label; selected state is shown by the knob / cap position and the LED dot.
- [ ] The knob ring and ticks stay still while the cap turns; tick marks sit correctly around the knob.
- [ ] The appearance switch is a proper hardware-style slide switch in both light and dark mode; no black bar in light mode.
- [ ] Drag, tap, VoiceOver adjust and haptics work as before.
- [ ] The rest of Home looks identical to before.
- [ ] Build and tests pass.

### Manual iPad checks for Jakub

Turn the knob and slide the switch in light and dark mode, in Czech and English; compare with the mockup; check the rest of Home did not change.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (drawing code with exact geometry). Fallback: Codex GPT-6.1 Sol, high. Independent of the practice-screen tickets (different files).

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
