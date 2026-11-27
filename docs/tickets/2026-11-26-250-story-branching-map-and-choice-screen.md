# 250 — Story mode: branching map, route choice and story cards

Status: open · after 247 and 249

Design source: `docs/design/2026-11-26-story-mode-gdd-v1.md` — the **Amendments** section at its top is binding and wins over the draft below it.

## Goal

Make Story mode an actual guided adventure: the Path map shows each stage as keystones and forks from `story-map.json`; after passing a lesson (★1) the student picks the next step; unchosen fork lessons become side trails; the boss node opens by the existing stage rule.

## Rules

1. **Availability (replaces 247's "completed or active Path node" source):** in Story mode a lesson is open when it is a reached node of the story map: the first keystone of an open stage; the next node after a node passed at ★1; every alternative of a reached fork (the chosen one on the route, the others as side trails). Keep the single shared function from 247; only its source changes.
2. **Route choice screen** (GDD §1.4, §3.4): shown on the result card after ★1, max 3 actions, only applicable ones: after a keystone → fork options (+ "Reach goal tempo" when the lesson lacks ★2); after a branch → "Rejoin the trail" / "Other branch" / "Reach goal tempo"; consecutive keystones → "Continue the trail" / "Reach goal tempo"; boss available → "Face the boss". Fork options use placeholder strings `story.fork.<stageId>.<index>.<a|b|c>` falling back to the lesson title until 253 delivers texts. The choice is remembered (route per fork) and can be changed by simply playing another alternative.
3. **Boss node** opens when the stage meets the existing rule (★2 on half of its lessons, rounded up, max 10; any stage lesson counts). The map shows how many ★2 lessons are still missing. Until 251 is done, the boss node starts the stage's existing exam lesson.
4. **Story card:** one card per stage shown once on first entry (title + 3–5 sentences + one button), reopenable from the stage on the map. Strings `story.card.<stageId>.title/body` with placeholder text until 253.
5. **Existing players** (GDD §1.11): route per fork = the alternative with most stars (ties → first); a stage that was open stays open; the current location = earliest unfinished open objective.
6. Free practice is unchanged. Do not touch audio/MIDI timing. Keep the calm UI: no extra text on the practice screen.

## Files to read

`AGENTS.md`, the 247 changes (shared availability function), `StoryMap` from 249, `SmackAPad/Sources/Progression/DrummerPathMapModel.swift`, `SmackAPad/Sources/UI/Practice/DrummerPathMapView.swift`, `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift` (result card), `SmackAPad/Sources/Progression/Progression.swift` (`requiredStageCompletions`).

## Tests

Availability follows the map (fresh, mid-stage, side trails); choice options per situation (table in rule 2); boss opens exactly at the existing threshold; migration picks the best-starred alternative and never relocks. Narrow tests while working, full `SmackAPadTests` once at the end.

## Acceptance criteria

- [ ] Map renders keystones, forks and side trails from `story-map.json`; boss node shows missing ★2 count.
- [ ] Result card offers the correct 1–3 actions; the chosen route is stored.
- [ ] Story card appears once per stage and can be reopened.
- [ ] Existing profile is placed correctly, nothing relocks.
- [ ] Builds, `SmackAPadTests` passes on the iPad simulator.

### Manual iPad checks for Jakub (no good playing needed)

- Debug scenario `fresh` → pass the first Intro lessons (they are easy) until Path opens; see the story card and the first fork choice.
- Your real profile: the map shows your progress, the boss node of a finished stage is open.

## Agent assignment

Antigravity: **Gemini 4 Hydrogen, thinking medium**. Fallback: Codex Sol 6.2, high.

## Done rule

Build, full test suite once, commit on `release-polish`, report changed files concisely.
