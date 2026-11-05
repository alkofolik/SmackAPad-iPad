# 99 — From memory: the notes fade out over the first passes

Status: ready-for-agent. Source: Jakub, 2026-11-05 (bridge from reading to playing from memory; legacy concept 2026-10-06 §6.6b "fading help").

## Goal

Today From memory hides all notes at START. That is a jump into the dark. Instead the notes fade out over the first passes of a continuous From memory session, so the player reads, then half-reads, then plays from memory. Credit is still earned only by passes with the notes fully hidden.

## Rules

1. Applies only to From memory in Play (not Listen, not section loops, not Play after me).
2. Passes counted from START (RESTART starts again at pass 1):
   - **Pass 1:** notes fully visible (as normal Play).
   - **Pass 2:** notes faded: hit cells drawn at low contrast (outline only, no pad label), still readable if the player looks hard. Use existing `Theme` tokens; no new colour.
   - **Pass 3 and later:** notes hidden exactly as today (grid skeleton, counts and playhead stay).
3. Only hidden passes (3+) can earn memory credit and count as a review (ticket 98). Passes 1–2 are scored and shown as normal practice; they never earn star 3 or a review, and they do not touch pass/goal-tempo credit either (they are From memory passes).
4. Setting in the practice section of Settings: "Fade notes in From memory" / "Nápověda zpaměti postupně mizí", default **on**. Off = today's behaviour (hidden from pass 1, every pass may earn credit).
5. The pass counter shows the phase: "Pass 1 · notes shown", "Pass 2 · notes fading", then the normal counter. Czech: "Průchod 1 · noty vidět", "Průchod 2 · noty mizí".
6. Accessibility value of the pattern field says the same phase.
7. Reduce Motion: switch between phases without animation; otherwise a short cross-fade at the pass boundary (reuse the motion tokens from ticket 27).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PatternField.swift` (the `hidden` flag and the three note views), `SmackAPad/Sources/UI/PracticeSession.swift` (`fromMemory`, pass number, memory qualification), `SmackAPad/Sources/UI/PracticeScreen.swift` (pass counter only), `SmackAPad/Sources/UI/SettingsView.swift`, `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Resources/en.lproj/Localizable.strings`, `SmackAPad/Resources/cs.lproj/Localizable.strings`.

## Tasks

1. Replace the boolean `hidden` with a three-state visibility (shown / faded / hidden) derived from pass number and the setting.
2. Memory credit and review counting only for hidden passes (use the tdd skill for this one rule).
3. Setting, counter texts, accessibility texts in `en` and `cs`.
4. Unit test (only this): with the setting on, passes 1–2 never qualify for memory credit, pass 3 does; with it off, pass 1 qualifies.

## Acceptance criteria

- [ ] From memory: pass 1 shows notes, pass 2 faded, pass 3+ hidden, in static and moving views and for 1, 2, 3 and all bars shown.
- [ ] Only hidden passes earn star 3 or count as a review.
- [ ] Setting off restores today's behaviour.
- [ ] Test passes, build succeeds.
- [ ] **iPad test (Jakub)**: one From memory session; check the readability of pass 2 in light and dark.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: mostly drawing; one small scoring rule.

## Done rule

Run after 97 and 98. Stop after successful build and test; do not commit. Jakub tests on iPad, Claude commits afterwards.
