# 249 — Story map data: keystones and forks for every Path stage

Status: open · after 247

Design source: `docs/design/2026-11-26-story-mode-gdd-v1.md` — the **Amendments** section at its top is binding and wins over the draft below it.

## Goal

Produce one data file that splits every Path stage into an ordered list of **keystones** (mandatory lesson) and **forks** (2–3 equivalent lessons, the student plays one), so the branching map (250) and the boss (251) have a single source of truth. No UI in this ticket.

## Rules

1. **Format:** `SmackAPad/Resources/Data/story-map.json`: for each stage id (`L<level>-<technique>`, as `LibraryStage.id`) an ordered array of nodes: `{"keystone": <lessonId>}` or `{"fork": [<lessonId>, <lessonId>(, <lessonId>)]}`. Fork labels are not stored here (texts come in 253; reference forks by stage id + index).
2. **Coverage:** every Path lesson appears exactly once, in its own stage; node order follows the existing stage order (`LibraryCatalog.orderStage`) as closely as possible. Intro and genre-extension lessons are not in the map.
3. **Shape target:** about ⌊(N−1)/3⌋ forks per stage, one more keystone than forks; stage starts and ends with a keystone. Stages under 4 lessons: keystones only.
4. **Equivalence (a fork is allowed only when all hold):** same stage; same `division`; bars equal; `targetBpm` within 10 %; hit count within 25 %; same genre preferred. If not equivalent → keystone. Educational sense beats the shape target.
5. **How to build it:** a generator script `tools/story_map/generate.py` proposes the map from the lesson JSON using rules 2–4 (deterministic, re-runnable). Then the agent reviews the proposal stage by stage and fixes forks that make no musical sense, writing a short note per changed fork into `tools/story_map/review-notes.md`.
6. **Swift side:** a small loader (`StoryMap`) that reads the file, plus validation used by tests. No other code changes.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Progression/LibraryCatalog.swift`, `SmackAPad/Resources/Data/lessons-core.json`, `SmackAPad/Resources/Data/electronic-path.json`, the GDD §1.2–1.3.

## Tests

`StoryMapTests`: every Path lesson exactly once; every node in its own stage; forks have 2–3 lessons; first and last node of each stage is a keystone; the file parses. Run these tests, then the full `SmackAPadTests` once at the end.

## Acceptance criteria

- [ ] `story-map.json` covers all 23 stages and all Path lessons exactly once.
- [ ] Generator script re-creates the unreviewed proposal; review notes list every manual change.
- [ ] `StoryMap` loader + tests pass on the iPad simulator.

### Manual check for Jakub

- None on the iPad. Optionally open `tools/story_map/review-notes.md` and look at 2–3 forks of a stage you know.

## Agent assignment

Antigravity: **Gemini 4 Argon, thinking high** (the fork review is a judgement task). Fallback: Codex Sol 6.2, high.

## Done rule

Run tests, commit on `release-polish`, report changed files and the number of keystones/forks per stage (one line each).
