# 141 — Today session screen redesign (Variant 1 — Studio Console Plate)

Status: ready-for-agent. Type: implementation. Depends on: 137 (proposal & chosen variant), 133 (button system). Source: Jakub, 2026-11-07: selected **Variant 1** (Satinová řídící konzole / Studio Console Plate) from ticket 137 preview ("líbí se mi 1").

Spec = preview `docs/previews/137-today-session.html` (Variant 1).

## Goal

Replace the current draft-like, left-crammed `TodaySessionScreen.swift` with the approved **Variant 1 — Studio Console Plate** layout. The screen must feel finished, balanced, and studio-grade on iPad Pro 11″ in both landscape and portrait orientations, in light and dark mode.

## What to build

1. **Centred screen layout**:
   - Remove the old unconstrained left-aligned scroll container that left the right side of the screen empty.
   - Center content horizontally and vertically on `Theme.background` (`calmChassisBackground`), keeping generous padding and safe areas.
   - Keep the "Domů" pad button in the top toolbar confirmation placement (tickets 109, 133).

2. **Top Stepper / Roadmap (`TodayStepperView`)**:
   - Horizontal progress row across the top of the session view:
     - 4 steps: `1. Opakování` -> `2. Opakování` -> `3. Nová lekce` -> `4. Denní mix`.
     - Visual states:
       - `completed`: green tint / check + percentage (e.g. `✓ 91 %`).
       - `current`: orange hairline highlight + current step score or indicator.
       - `upcoming`: muted secondary appearance.

3. **Master Console Plate (`.satinPlate()`)**:
   - A single unified satin plate (16 pt radius, satin gradient, hairline, bevels, contact shadow).
   - **Landscape layout (two-column split, ~960 pt max width)**:
     - **Left column — Previous run evaluation**:
       - Step kicker (e.g. `OPAKOVÁNÍ 2 ZE 2 DOKONČENO`, `Theme.stepTag`).
       - Dominant score: large 64–68 pt bold percentage (`83 %`) + 3-star meter in `Theme.orange` / `Theme.ledOff`.
       - Lesson title and meta line: e.g. "Rock 1" + "8 osminových úderů · Cvičení zpaměti při 94 BPM".
       - Calm verdict sentence: set in comfortable 15–16 pt body text inside a warm status container (`verdict-box`): *"Nepočítá se · Dokonči průchod bez nápovědy, aby se lekce uložila jako zvládnutá."* (No oversized 28 pt shouting headline).
     - **Right column — Next lesson preparation & actions**:
       - Kicker: `PŘIPRAV SE NA DALŠÍ KROK`.
       - Next lesson title & meta: e.g. "Funk 1" (32–34 pt bold display) + "Nová lekce · 98 BPM · 4 takty groove".
       - 16-step rhythm preview strip: reuse `LessonPatternStrip` from Library rows to display the rhythm groove (Hi-Hat, Snare, Kick).
       - Button cluster (Variant B from ticket 133):
         - Primary Hero button: "Pokračovat na Funk 1" (`PadPrimaryButtonStyle`, min height 52 pt, orange `#FF6B00`, ink text, 6 pt radius).
         - Secondary row: "Přeskočit" and "Konec na dnes" (`PadSecondaryButtonStyle`, min height 48 pt).
   - **Portrait layout**:
     - Columns stack smoothly into a vertical master console card (~680 pt max width) without horizontal overflow or clipped text.

4. **Lifecycle states**:
   - **Before first run (Day start)**: Hides the left evaluation column; the console shows the first lesson directly with the pattern preview and a "Začít trénink" / "Start training" hero button.
   - **Between steps (Handoff)**: Full two-column evaluation and preview as described above.
   - **End of day (Summary)**: Centered end plate ("To je pro dnešek vše" / "That's enough for today") with session stats breakdown (reviews passed, new lesson score, mix completed) and primary "Domů" button.

5. **Localization**:
   - Provide natural English and Czech strings for all labels, verdict sentences, and steppers in both `Localizable.strings`.

## Rules

- Layout and UI presentation only. Do not change the session flow logic, plan storage (`TodayPlan.swift`), or practice screen coordinator.
- Use existing Theme tokens and `LessonPatternStrip`. Add new layout tokens only if needed for spacing/proportions, and name them by role.
- No code outside `SmackAPad/Sources/UI/TodaySessionScreen.swift` and `Localizable.strings` (unless small helper views in `Components.swift` are appropriate).
- Build must succeed with zero new warnings. No extra tests.

## Files to read

`AGENTS.md`, this ticket, ticket 137, `docs/previews/137-today-session.html` (Variant 1), `TodaySessionScreen.swift`, `TodayPlan.swift`, `LessonPatternStrip.swift`, `Theme.swift`, `Components.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] Today session screen matches Variant 1 from `docs/previews/137-today-session.html`.
- [ ] Content is centred on the screen in landscape and portrait with no empty-corner look.
- [ ] Stepper displays all steps of today's plan with correct status.
- [ ] Score is prominent with 3-star meter; verdict line reads as a calm sentence in a status box.
- [ ] Next lesson shows a 16-step pattern sequencer preview (`LessonPatternStrip`).
- [ ] Buttons use Variant B styling (hero orange 52 pt for continue, secondary 48 pt for skip and done).
- [ ] Start-of-day and End-of-day states render cleanly without panels collision.
- [ ] Both light and dark modes look great on iPad Pro 11″.
- [ ] Czech and English localizations complete.
- [ ] Build succeeds with zero warnings.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: Precision UI rewrite of a single screen to match an approved offline HTML preview.

## Done rule

Stop after successful build and simulator verification. Commit (AGENTS.md); Jakub tests on physical iPad.
