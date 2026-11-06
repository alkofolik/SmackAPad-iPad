# 113 — Transitions: pad zooms into its screen, Today steps in

Status: ready-for-agent. Depends on: 112 (same Home files; do 112 first). Source: Jakub, 2026-11-06 (missing modern animations and transitions), proposal A of ticket 111.

Spec = `docs/design/2026-11-06-home-pads-and-motion/proposal-a.html` (zoom demo and Today demo) and the table "Mapování animací na Theme tokeny" in the README of that folder.

## What to build (chrome only)

1. **Pad → screen zoom**: tapping a Home pad (Library, Training, Badges, Settings, Today) grows that pad into the screen, going back shrinks it into the pad. Tokens `Theme.Motion.padZoom` (0.28 s spring, response 0.28, damping 0.82) and `padDismiss` (0.22 s ease-out). iOS 18: the native zoom navigation transition from the pad. **iOS 17 fallback** (deployment target stays 17.0): fade plus scale 0.98. Ticket 27 already has a Library ↔ Practice zoom; reuse its helper in `Theme.swift` / `ContentView.swift`, do not build a second one.
2. **Today session (tickets 109/110)**: the hand-off card content steps in when the step changes: 0.24 s ease-out, 20 pt rise with fade (`Theme.Motion.cardStep`). The buttons row must not jump while text changes (fixed position or reserved height).
3. **Small live details** only where the code already shows the value: numbers that change use the numeric text roll (ticket 27 already does this for tempo; reuse it for the Home Library stars count and the Training "due" count).
4. **Reduce Motion**: every item above becomes a pure opacity change of at most 0.2 s (no zoom, no rise, no spring). Use the existing helper (`Theme.Motion.Policy`, `.motion(_:value:)`).

## Rules

- No change to Practice drawing, playhead, hit judging, scoring, audio (ticket 27 rule 3). Practice screen internals stay as they are.
- Do not change navigation structure or what each pad opens; only how it appears and disappears.
- No new user-facing text.
- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).

## Files to read

`AGENTS.md`, this ticket, ticket 27, tickets 109, 110, 112, the README and `proposal-a.html` of the folder above (zoom and Today parts), `SmackAPad/Sources/UI/HomeScreen.swift`, `ContentView.swift`, `TodaySessionScreen.swift`, `Theme.swift` (`Motion`).

## Acceptance criteria

- [ ] Each Home pad zooms into its screen and back (iOS 18); fade + scale on iOS 17.
- [ ] Today hand-off steps in; buttons do not jump.
- [ ] Reduce Motion: only short fades.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: open and close every Home pad; run a Today session; repeat with Reduce Motion on.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: navigation transitions with an iOS 18 / iOS 17 split need care, but they reuse the ticket 27 helper; Sol if Flash fails twice.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
