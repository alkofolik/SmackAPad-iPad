# 157 — First run guidance and legibility fixes

Status: approved by Jakub 2026-11-09 (both open questions answered: pulsing Intro pad without text; legend opens once on its own), ready for the agent. Blocked by: 156 (tested 2026-11-09, done). Source: AI panel findings #15–#19 (`docs/reviews/ai-panel/results/synthesis.md`; `round1-gemini.md` R1-01, R1-02, R1-03, R1-05, R2-01, R2-02; plan: `docs/2026-11-08-ai-panel-action-plan.md`, batch 4).

## Hard constraint

Jakub does **not** want any new text in the UI. No "Start here" label, no new hints, no new strings in `Localizable.strings`. Everything below uses existing icons, motion and drawing only. The rules/modes explanation and the first-launch tutorial are a separate, later ticket and are **not** part of this one.

## Problems and rules

### A. New player has no clear starting point (finding #15)

Home shows Today, Library, Training and Intro with no hint where to begin.

1. When the profile has **no progress at all** (no lesson with a star, nothing started), the **Intro** pad gets the same breathing light bar already used for Training with reviews due (`PadLightBar` in `HomeScreen.swift`, ticket 112). No other pad is lit in that state.
2. As soon as any progress exists, the Intro pad returns to its normal state and the existing Today/Training lighting rules apply unchanged.
3. Respect Reduce Motion exactly as `PadLightBar` already does.
4. Add a small pure helper ("has any progress") with a unit test (empty vs. non-empty progress). Reuse an existing ProgressStore query if one exists.

### B. Pad abbreviation legend is hidden (finding #17)

The legend already exists (icon `list.bullet.rectangle`, popover in `PracticeScreen.swift`), but nobody finds it.

1. The **first time** a lesson with at least one pad abbreviation is opened in a practice screen, the legend popover opens by itself once, before the run starts. Store a flag (`@AppStorage`, e.g. `smackapad.legend.shownOnce`); never auto-open again.
2. Never open it while a run is active or during the count-in. If it would conflict with the lesson info popover, the info popover wins and the legend is skipped for that visit (flag stays unset).
3. The legend content and the icon stay as they are.

### C. MIDI learn pad numbering (finding #16)

`MIDILearnView` (`ContentView.swift`) lays out "Pad 1…16" from the top-left, but the 16-pad preset and typical hardware count from the **bottom-left** (notes 36–51).

1. Change only the **display order** of the grid so slot 1 is bottom-left, slot 4 bottom-right, slot 13 top-left, slot 16 top-right (8-pad: slot 1–4 bottom row, 5–8 top row).
2. The order in which pads are learned, `MIDIInput.learnedNotes` and saved profiles do **not** change. Highlight (`slot == learnedNotes.count`) must still follow the learning order.
3. Check the same grid orientation in `ControllerSetupView.swift` and the touch-pad/pad-layout display; report any other place that counts from the top-left, fix it only if it is the same bug.

### D. Touch targets (finding #18)

1. Practice toolbar icons are already 48×48 pt (`Theme.Size.touch`); verify spacing between neighbours and leave them if they meet 44 pt targets.
2. Audit controls smaller than 44 pt in `Components.swift` (e.g. `minWidth: 28`, `minHeight: 32` around lines 600, 797, 842) and `PracticeScreen.swift`/`PracticeComponents.swift` (frames of 20–28 pt that are tappable). Raise the **hit area** to at least 44×44 pt (`.contentShape` / larger frame) without changing how it looks.
3. Pure decoration (not tappable) stays untouched. List what was changed in the final report.

### E. Ghost-note contrast in From memory (finding #19)

Faded dark orange notes on the orange band have a contrast of about 1.5:1.

1. In `PatternField.swift` (ghost / faded drawing, around the `fadedContext` and cross code) draw ghost notes with a clear **outline** (black or white, whichever contrasts with the band in light/dark theme) and only a light fill. Keep the palette (orange, black, white); no new colours.
2. Target at least 3:1 against the band in both themes. Add a small test or documented calculation for the chosen colours.
3. Do not change the scoring colours of played hits or the timing of the fade.

## Files to read

`AGENTS.md`, this ticket, `docs/2026-11-08-ai-panel-action-plan.md`, `SmackAPad/Sources/UI/HomeScreen.swift` (`PadLightBar`, home pad lighting), `SmackAPad/Sources/UI/PracticeScreen.swift` (toolbar ~365–430, legend ~1080+), `SmackAPad/Sources/UI/PracticeComponents.swift` (`PracticeIconButton`), `SmackAPad/Sources/UI/ContentView.swift` (`MIDILearnView`), `SmackAPad/Sources/UI/ControllerSetupView.swift`, `SmackAPad/Sources/UI/Components.swift`, `SmackAPad/Sources/UI/PatternField.swift`, `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [ ] Fresh profile: only the Intro pad breathes on Home; after the first star or any started lesson it stops; Reduce Motion respected.
- [ ] First opened lesson shows the legend once automatically; it never reopens by itself; never during a run.
- [ ] MIDI learn grid shows Pad 1 bottom-left; learned notes and existing profiles are unchanged; learning order and highlight correct.
- [ ] No tappable control below 44×44 pt hit area in the audited files; looks unchanged.
- [ ] Ghost notes in From memory clearly visible in light and dark theme (≥ 3:1).
- [ ] No new strings added; build succeeds; existing tests pass; new tests: "has progress" helper, MIDI learn display-order mapping, contrast calculation.
- [ ] **iPad test (Jakub)**: reset progress and open Home; open a first lesson (legend appears once); run MIDI learn with a controller and confirm Pad 1 is bottom-left; use From memory in light and dark mode and check the ghost notes; tap the small controls.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high** (medium would do, high is safer across five small UI changes). Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: several small, unrelated UI edits; the risk is touching layout or adding text by accident.

## Done rule

Stop after a successful build and passing tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad. Report the list of changed files and controls.

## Test result (Jakub, iPad A16, 2026-11-09)
Tested on the iPad per the acceptance list (fresh-profile Intro pad, auto-opened legend, MIDI learn numbering, touch targets, From memory ghost notes): all passed. Ticket closed.
