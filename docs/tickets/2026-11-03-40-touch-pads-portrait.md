# 40 — Playable on-screen pads in portrait (no controller needed)

Status: Phase B implemented (2026-11-03); unsigned iPad build passed, Jakub's iPad acceptance pending. Source: Jakub 2026-11-03 (widen the audience: iPad owners without a pad controller can try the app).

## Phase B implementation — 2026-11-03

Jakub selected Proposal 1, with compact transport approximately 380 × 72 pt, aligned right above the deck. Pads show abbreviations only, without numbers or full names. Phase A proposals remain unchanged.

- Portrait is detected from the window geometry. The 4×4 deck remains below the scrollable reading section; the existing landscape footer remains in use otherwise.
- Each pad owns an independent UIKit touch surface, shared with the existing Settings touch pads. Leaving the starting pad releases it without triggering its neighbour or retriggering on re-entry. Cancellation, removal and readiness changes also release the note.
- Practice touches use `midi.touch`, including its fixed velocity, `touch` device ID and existing calibration path. Input is gated by the open lesson, session readiness, active scene and 16-pad layout.
- The global “Touch pads in portrait” preference defaults to On and persists with AppStorage. EN/CS labels and a separate-touch-calibration hint are included.
- No scoring, timing, tempo or star rules changed. Multi-touch, sliding, appearance and controller coexistence require Jakub's physical iPad check.
- Validation: unsigned Debug build for `generic/platform=iOS` passed. The initial sandboxed Simulator build could not run compiler macros; the device build succeeded outside that restriction. No tests were run. Build used the current working tree, including pre-existing changes excluded from this task's commit.

## Goal

In **portrait** orientation the pad layout grid on the practice screen becomes large, playable touch pads. The same element is both the layout display and the input surface. **Landscape is unchanged**: it keeps the small, non-touchable `PadLayoutGrid` (landscape touch pads were rejected by Jakub: the pattern band and the pads do not fit together).

## What exists already (do not rebuild)

- `MIDIInput.touch(padIndex:isPressed:)` emits a `PadInputEvent` with `deviceID: "touch"` into the same pipeline as MIDI (audio, calibration, scoring). Touch hits are already scored like MIDI hits.
- `TouchPad` view and its grid in Settings → MIDI tools (`SettingsView.swift`, section "Touch Pads"). Reuse its press/release mechanics.
- `PadLayoutGrid` (`PracticeComponents.swift`) with pad abbreviations, "used by this lesson" outline and `PadFlash` colours; shown through the `showPads` setting (`PracticeScreen.footerContent`).
- Touch has its own calibration entry (`CalibrationView`, `deviceID == "touch"`).
- The app already allows all four orientations (project settings).

## Phase A — design only (stop afterwards)

Write `docs/design/2026-11-03-portrait-practice-layout.md` with **two** proposals for the portrait practice screen. No Swift code in this phase.

Constraints (Jakub's standing design rules, see `docs/design/`):
- Three colours only (orange, black, white), light and dark variant, IBM Plex Sans (ticket 39), no generic "AI look".
- The orange pattern band stays dominant; every pad used by the lesson keeps its own row (band v2 variant B).
- Large pad grid 4×4 in the lower part of the screen (thumb area), pads as square as the width allows; each pad shows its abbreviation (HH, SN, OH …).
- Pads must show hits in colour exactly as `PadFlash` does now (played pad lights up); pads used by the lesson keep the outline; no new per-hit timing shapes (Jakub finds them stressful).
- START/STOP/RESTART stay large and reachable; compact tempo field as in round 6/7 decisions.
- Everything else (info, settings, details) stays one touch away, as in landscape.
- Show how the pattern band, pad grid and transport divide the vertical space on an iPad 11" and 13" (give heights in points), and what happens at the largest accessibility text size.

Deliver text wireframes (ASCII is fine) plus a short recommendation. **Stop and report in max 5 lines.**

## Phase B — implementation (only after Jakub chooses a proposal)

1. Portrait practice layout as approved. Detect orientation by the geometry (height > width), not by device type, so Split View / Stage Manager windows behave sensibly.
2. Portrait: the grid is touchable and calls `midi.touch(padIndex:isPressed:)` on touch down / up. Landscape: the old small grid, not touchable.
3. Multi-touch: at least 4 fingers at once must work, each pad tracks its own finger (check the existing `TouchPad` for this; fix if it uses a gesture that blocks simultaneous touches). Sliding a finger from one pad to another must release the first pad and must not trigger the second.
4. Setting (global Settings, not on the practice screen): **"Touch pads in portrait"** On/Off, default On. Off = small layout grid as in landscape. The existing "Small pad layout" toggle keeps working for landscape.
5. Only active when a lesson is open, the session is ready and the lesson has 16 pads (the current `midi.padIndices` guard). Touching pads while the session is not ready must not play anything.
6. Calibration: touch hits use the existing `"touch"` calibration offset. Add a one-line hint in the Calibration screen if not yet present: "Calibrate touch separately; it differs from a controller."
7. Texts in `en` and `cs`.

## Out of scope

- iPhone layout. Landscape touch pads. Any change to scoring, tempo or star rules. Velocity sensitivity (touch sends a fixed velocity as today).

## Files to read

`AGENTS.md`, `docs/design/` (latest practice-screen and band documents), `SmackAPad/Sources/UI/PracticeScreen.swift`, `PracticeComponents.swift`, `SettingsView.swift` (Touch Pads section), `SmackAPad/Sources/MIDI/MIDIInput.swift`, `Theme.swift`, localisation catalogs.

## Acceptance criteria

- [ ] Phase A document delivered, work stopped.
- [ ] Portrait: a lesson is fully playable with fingers only, pads light up and are scored.
- [ ] Four simultaneous touches play four sounds; sliding between pads does not double-trigger.
- [ ] Landscape looks and behaves exactly as before.
- [ ] Setting works and survives restart. Build succeeds.
- [ ] **iPad test (Jakub)**: play an intro lesson in portrait without the controller; then with the controller connected, check nothing regressed.

## Agent assignment

- **Phase A (design)**: Codex GPT-6.1 Sol, **high**. Layout reasoning with several constraints; no code, so it is cheap.
- **Phase B (implementation)**: Codex GPT-6.1 Sol, **high**. SwiftUI layout plus multi-touch input in front of scoring.

## Done rule

Phase A: stop after the document. Phase B: stop after a successful build; Jakub tests on the iPad. Commit after each phase.
