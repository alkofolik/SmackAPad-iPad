# 91 — Practice: the two transport buttons look equal (same size and same square corners); Czech "Restart" shortened

Status: ready. Source: Jakub, 2026-11-05 (iPad, photo 2): "Align the buttons to the same size. The Czech button for a new attempt probably just shorten to ZNOVU."

## Problem

In the transport square (`PracticeComponents.swift`, `TransportControls.squareBody`) the two stacked buttons are both `s × buttonHeight` but are drawn by different styles: the top one with `InstrumentButtonStyle` (main), the second one either as the Restart button (outlined, with an icon) or, after a run, as the "Memory ★3" button (`MemoryChallengeButtonStyle`, orange, rounded, with horizontal padding). The main visible difference (Jakub, correction): **one button is rounded and the other is square.** `InstrumentButtonStyle` draws square corners (Again / Start / Restart), `MemoryChallengeButtonStyle` uses `Theme.Radius.pad` (8 pt, rounded, "Memory ★3"). Outline and padding differ too (photos 1 and 2). The Czech label "Spustit znovu" is also too long for the button.

## Rule

- Both buttons in the square have **identical** outer size, corner radius and edge: same width `s`, same height, same corners: **both square**, like the toolbar buttons, the Library button and the result card (change `MemoryChallengeButtonStyle` to square corners; do not round the other buttons). Orange fill and outline are only colour differences, not size differences.
- Same text size and weight for both labels.
- Czech: `"Restart"` → **"Znovu"** (cs `Localizable.strings`). Note that `"Again"` is already "Znovu" in Czech: after a run the top button says "Znovu" and the second one "Zpaměti ★3", so no clash; but before a run the second button is "Znovu" below "Začít" — fine. Keep English "Restart".
- Applies to all states: before start, running, after a run with the second button, after a run with the single "Again" button.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeComponents.swift` (`TransportControls`), `SmackAPad/Sources/UI/PracticeInstruments.swift` (`InstrumentButtonStyle`, `MemoryChallengeButtonStyle`), `SmackAPad/Sources/UI/PracticeScreen.swift` (`transportSecondAction` only), `SmackAPad/Resources/cs.lproj/Localizable.strings`.

## Acceptance criteria

- [ ] Both buttons the same width, height and corner radius in every state.
- [ ] Czech label "Znovu" fits on one line, no truncation.
- [ ] Light and dark; landscape and portrait; cs and en.
- [ ] Build passes; do not run tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium** thinking. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
