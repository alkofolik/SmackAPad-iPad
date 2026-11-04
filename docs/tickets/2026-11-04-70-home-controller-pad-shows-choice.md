# 70 — Home: Controller pad shows the current choice (bug)

Status: ready. Source: Jakub, 2026-11-04: after choosing another controller or instrument in the controller setup and going back, the home Controller pad does not show the new choice.

## Cause

`HomeScreen.swift`, `pad5`: the subtitle is `midi.sources.first?.name`, the first connected MIDI port, not the controller profile or instrument chosen in `ControllerSetupView`.

## Rule

- Subtitle = the chosen controller profile name, then " · ", then the chosen instrument (sound kit) name, exactly as `ControllerSetupView` names them. If the text does not fit, drop the instrument part, never truncate the profile mid-word.
- If no MIDI source is connected, add a quiet second line "Not connected" / "Nepřipojeno" (do not replace the choice).
- The pad updates immediately when the setup sheet closes (read observed state, no cached copy).
- VoiceOver label reads the same text.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/HomeScreen.swift` (`pad5`, controller sheet), `SmackAPad/Sources/UI/ControllerSetupView.swift` (where profile and instrument are chosen and stored), both `Localizable.strings`.

## Acceptance criteria

- [ ] Change profile, close sheet: pad shows the new profile. Same for instrument.
- [ ] Unplugged controller: choice still shown plus "Not connected".
- [ ] Cs and en; light and dark.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
