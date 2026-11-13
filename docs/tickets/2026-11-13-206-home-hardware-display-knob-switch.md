# 206 — Home as a real controller: display, language knob, appearance switch

Status: ready-for-agent. Decided by Jakub on 2026-11-13 (iPad review, photos 11 and 12). Defaults below follow the recommendation Jakub approved ("Ano, napiš tickety"); he may still change details after the iPad check.

## Goal

The Home faders now work (ticket 191), so Home should keep becoming a believable, working controller. The "SMACK-A-PAD" title becomes a display on the device; language and appearance get real hardware controls; the "How it works" bar goes away and help moves to a hardware button. Portrait gets bigger faders and pads moved up.

## Rules

### Display
1. Replace the plain title with a **display window** that is part of the hardware: dark recessed glass with a thin bezel, the logo "SMACK-A-PAD" drawn in a dot-matrix / LED style in the accent colour, a faint pixel grid and a slight glow. Draw it in code (SwiftUI shapes / Canvas), no bitmap.
2. Under the logo the display has one small status line: the active controller name and connection ("JP-Mini · connected" / "No controller"). Ticket 207 will use the same line for the last hit, so build it as a small view with a text input, not hard-coded.
3. **Landscape:** display centred above the pad plate, the same width as the plate. **Portrait:** display at the top, the same width as the plate.

### Language knob and appearance switch
4. **Landscape:** move the fader bays up so their tops line up with the top of the plate. Under the left bay: a **rotary knob** for language, with detents labelled "EN" and "CZ" around it (one detent per `AppLanguage` case, so a new language only adds a detent). Under the right bay: a **3-position slide switch** for appearance labelled "Light", "Auto", "Dark" (`AppAppearance` light / system / dark; the setting already exists in Settings → Appearance).
5. **Portrait:** knob and switch sit at the two ends of the fader row (knob left, switch right).
6. Both controls change the real settings at once and stay in sync with Settings both ways. Knob: drag in a circle or tap a label; turns snap to detents with a light haptic. Switch: drag or tap a position.
7. Labels in sentence case, localized, not monospaced. Colours from `Theme` only; both must look right in light and dark.
8. Accessibility: knob is an adjustable element "Language, English"; switch is an adjustable element "Appearance, Auto".

### Help
9. **Delete the "How it works" bar** (`HelpEntryLabel` row and `HomeControllerLayout.helpRowSpace`) in both languages; remove its strings if nothing else uses them.
10. Add a small round rubber **"?" button** on the hardware, to the right of the display. It opens the existing help deck (`helpDeck`), anchored to the button. Keep VoiceOver focus return as today.

### Portrait layout (Jakub's addition)
11. Move the pad plate up so it sits close under the display, and use the freed space to make the faders taller (longer travel), keeping the three in one row. The rule that faders are dropped in very short windows stays.

### Launch animation
12. Change `LaunchAnimationView` so it ends on the new Home: the display powers on (bezel visible, pixels fade in, logo lights up), then the plate appears. Total ≤ 1.2 s; Reduce Motion → simple fade. Delete parts of the old animation that animated the old title.

### General
13. Hardware drawing stays static (no hit testing) except the interactive parts: faders, knob, switch, "?" button, pads. Dragging the knob or switch never triggers a pad or scroll.
14. No dead code: remove the old title view and any layout constants only it used.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/HomeScreen.swift` (`HomeControllerLayout`, `HomeControllerHardware`, `HomeControllerFaders`, logo, `helpDeck`), `LaunchAnimationView.swift`, `HelpDeck.swift`, `Theme.swift`, `SettingsView.swift` (Appearance and Language rows), `SettingsManager.swift`, `Persistence/AppLanguage.swift`, `Persistence/SettingsTypes.swift` (`AppAppearance`), `FaderValueMapping.swift` (pattern for value mapping).

## Tests

Unit test for the knob mapping: angle ↔ detent ↔ `AppLanguage` (snap to nearest, clamp at both ends). Unit test for the switch mapping: position ↔ `AppAppearance`. Nothing else; UI is checked by hand.

## Acceptance criteria

- [ ] Home shows a display with the logo and a status line instead of the plain title, in both orientations.
- [ ] Landscape: faders higher, language knob under the left bay, appearance switch under the right bay.
- [ ] Portrait: plate higher, faders taller, knob and switch at the ends of the fader row.
- [ ] Knob and switch change language and appearance at once and match Settings both ways.
- [ ] "How it works" bar is gone; the "?" button opens help.
- [ ] Launch animation ends with the display lighting up.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

- Turn the knob to CZ and back; flip the switch through Light / Auto / Dark. Does it feel like hardware?
- Portrait: are the faders big enough now and the pads high enough?
- Does the display look good in light mode too?

## Agent assignment

Codex GPT-6.1 Sol, thinking **high** (custom drawing, two new controls, layout in two orientations, launch animation). Fallback: Gemini 3.8 Flash, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
