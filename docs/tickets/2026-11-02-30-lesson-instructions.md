# 30 — Lesson instructions panel

Status: ready. Source: legacy comparison 2026-11-02 (legacy manual §4.1, "Teaching"). The lesson data already contain instructions, but the iPad app never shows them.

## Goal

One touch on the practice screen opens a short panel with the lesson's instructions.

## Content (in this order, skip empty items)

1. Lesson title, level, bars, start and goal tempo.
2. `text` — the lesson instruction (every lesson has it), e.g. "Left hand: kick, snare, hi-hat. Right hand: hi-hat, open hat."
3. Intro lessons only (`intro` metadata): **Goal** (`goal`), **Watch for** (`watch`), and **Fingers**: from `fingers16` or `fingers8` for the current pad mode — keys are `"padIndex:hand"`, values are finger numbers. Show as rows "Kick L · left hand · finger 3". Add one line explaining the finger numbers (1 = thumb … 5 = little finger).
4. **How to earn the stars** — reuse the existing `StarRequirement` texts for all three stars, with earned ones marked.
5. Source (`src`) in small text.

## Behaviour

- Button with a clear icon ("Lesson info") in the practice header, next to the existing icons. It is shown **only while stopped**, like the tempo field; during a run it is hidden.
- Opens a popover/sheet in the style of the existing "More tools" popover; closes with a tap outside or Close.
- Does not open automatically.

## Localisation

Czech translations of lesson texts, goals and watch lines already exist in `SmackAPad/Resources/i18n/cs.tsv` (example: "Count 1, 2, 3, 4 aloud with the click." → "Počítej nahlas 1, 2, 3, 4 s klikem."). Use the same lookup the app already uses for lesson titles; if a line is missing in Czech, show the English one. New UI labels go into both catalogs.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Data/LessonData.swift` (`IntroMetadata`), `SmackAPad/Sources/UI/PracticeScreen.swift`, `PracticeComponents.swift`, `StarRequirement.swift`, `Theme.swift`, localisation catalogs, `SmackAPad/Resources/i18n/cs.tsv` (search only).

## Acceptance criteria

- [ ] Every lesson shows its instruction; intro lessons also show goal, watch for and fingers for the current pad mode.
- [ ] The button is hidden during a run.
- [ ] Czech shows translated lesson texts where they exist.
- [ ] Look matches the existing popovers: three colours, existing fonts.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: one intro lesson and one ordinary lesson, in English and Czech.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), **high**.
- **Reasoning**: UI and data display only; no timing or scoring.

## Done rule

Stop after successful build; Jakub tests on iPad. Commit after the task.
