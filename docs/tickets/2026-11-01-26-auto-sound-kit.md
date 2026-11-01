# 26 — Sound kit "Automatic" (default) and per-lesson choice

Status: ready-for-agent (2026-11-01). Independent of 24 and 25; can run in parallel with them (touches Settings, Persistence, Audio selection only).

## Goal

Add **Automatic** to the sound kit choice. It is the default: every lesson gets the most suitable kit by itself. The student may override the kit for one lesson, lesson by lesson.

## Current state

One global `settings.selectedKitId` (default `acoustic`), picked in `SettingsView` (`Picker "Sound kit"`), applied in `PracticeSession.prepare()` and `start()` through `audio.selectKit(...)`. Lessons carry no kit. Eight kits exist in `sample-kits.json`: `acoustic`, `808`, `jazz`, `world`, `rock`, `brush`, `worldperc`, `house`.

## Behaviour

1. Settings: kit picker gets a first option **Automatic** (id `auto`), default for new and existing users (migrate: users who never changed the kit get `auto`; a user who explicitly chose a kit keeps it as the global fixed kit).
2. Resolution order for a lesson: per-lesson override, then global setting; when the result is `auto`, the kit comes from the table below.
3. Per-lesson override: in the practice screen "More tools" popover add "Sound kit": Automatic / the eight kits. Stored as a dictionary lesson id -> kit id in settings (not in `LessonProgress`). "Automatic" removes the override. Changing it is only possible while stopped, and the next START uses it. Show the kit actually used (e.g. "Automatic · Rock") in that popover.
4. Safety: if the resolved kit lacks a voice that the lesson needs, fall back to `acoustic` and keep playing (no error banner). Verify in code which voices each kit has (`sample-kits.json`) and cover this in a test.
5. Library and Intro are not affected. Texts via the localisation catalogs (`en`, `cs`).

## Automatic mapping (proposal; keep it as one table constant so it is easy to change)

By lesson `genre` (exact legacy names are those in the bundled data; match case-insensitively):

| Kit | Genres |
|---|---|
| `rock` | Rock, Punk, Country, Pop, Blues, Gospel |
| `acoustic` | Funk, Soul, Disco, Lo-fi, Trip hop, anything not listed (default) |
| `jazz` | Jazz, New Orleans |
| `world` | Latin, Afrobeat, Highlife, Reggae, Reggaeton, Middle Eastern |
| `worldperc` | Afro-Cuban |
| `808` | Hip hop, Trap, Miami bass, Electro |
| `house` | Dance, House, Deep house, Tech house, Techno, Hard techno, Trance, UK garage, Dubstep, Drum and bass, Jungle, Breakbeat, Moombahton, Synthwave |

Jakub reviews the table after listening on the iPad; it is expected to change.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/SettingsView.swift`, `SmackAPad/Sources/Persistence/Persistence.swift` (`SettingsManager`, `selectedKitId`), `SmackAPad/Sources/UI/PracticeSession.swift` (kit selection), `PracticeComponents.swift` (`PracticeTools`), `SmackAPad/Sources/Audio/AudioEngine.swift` (`selectKit`, voices), `SmackAPad/Resources/Data/sample-kits.json`.

## Tests

Resolution order (override beats global beats auto); each genre in the table maps to its kit; unknown genre -> `acoustic`; missing voice -> fallback; migration of an untouched and of an explicitly chosen kit.

## Acceptance criteria

- [ ] Settings shows Automatic first and it is selected on a fresh install.
- [ ] A rock lesson and a house lesson play with different kits without any user action.
- [ ] A per-lesson override survives restart and can be cleared.
- [ ] A user who had chosen a kit before keeps it.
- [ ] Build succeeds, new tests pass.
- [ ] **iPad test (Jakub)**: listen to 5 lessons of different genres on Automatic.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking (Antigravity).
- **Reasoning**: Settings plumbing plus a lookup table that is fully specified above; no timing or scoring code. If it fails twice, hand over to Claude Opus 4.6 (medium).

## Done rule

Stop after successful build and tests. Commit after the task. Final report max 5 lines.
