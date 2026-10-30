# 03 — Lesson Models & Content-Pack Loader

Status: ready-for-agent

## Goal

Define Swift data models for lessons, sample kits, and controller profiles. Build a content-loading architecture that supports multiple sources (bundled JSON + future external content packs).

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.3 Lesson Data, §4.1–4.4 Data Formats, §6 8-Pad Controller Rule)
- `docs/DECISIONS.md` (§5 Lesson data, §18 Content packs)

## Tasks

1. Define `Lesson` model matching the schema: `id, cat, title, genre, tags, text, division, bars, startBpm, targetBpm, level, score, src, hits` where hits = `[step, padIndex, hand, velocity]`.
2. Define `SampleKit` model: `kitId, name, license, voices` with velocity variants.
3. Define `ControllerProfile` model: `profileName, noteMap (midiNote → padIndex), padCount (8|16)`.
4. Build `LessonStore` that loads from multiple JSON sources (bundled resources + future external paths). Each source registers its JSON files; the store merges them.
5. Implement the 8-pad playability check: a lesson is playable if every padIndex in its hits array exists in the active controller profile's noteMap.

## Acceptance criteria

- [ ] All lesson JSON files parse into typed Swift models without error.
- [ ] `sample-kits.json` parses correctly (all kit definitions including virtual kits like jazz/world that reference shared WAV files).
- [ ] LessonStore loads from bundled JSON by default.
- [ ] LessonStore supports registering additional JSON sources (content-pack architecture ready).
- [ ] 8-pad playability filter correctly marks lessons as playable/not-playable for a given profile.
- [ ] Invalid or missing JSON produces a clear error, not a crash.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: Data modelling and JSON parsing, no complex runtime logic.

## Done rule

Stop after successful build; Jakub tests on iPad.
