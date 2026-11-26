# 247 — Story mode / Free practice switch (Story on by default) and consistent kit rule

Status: open

## Goal

Give the app two play modes:

- **Story** (default, also for existing players): the app guides the student. The Drummer's Path is the main route and only the lessons the path has opened are available.
- **Free practice** (Settings): the student goes his own way. The Library works as it does today, limited only by the purchase tier; no story gating, no Path map.

At the same time remove the inconsistent kit locking found in the 2026-11-26 audit: a locked kit must never block a lesson anywhere.

This ticket does **not** build the branching path choices or real boss fights. Those come after the game rules doc (ticket 248) is approved.

## Background (audit 2026-11-26, branch `release-polish`)

- Kit lock blocks a lesson on the Home pad (`HomeScreen.swift:424`, `store.isUnlocked(lesson) && …isKitUnlocked…`), drops it from the Today plan (`TodayPlan.swift:152`) and leaves it inactive on the Path map (`DrummerPathMapModel.swift:246–396`), but the Library does not check it.
- `SoundKitResolver` ignores kit locks, so "Automatic" plays a locked kit's sound anyway.
- A buyer of the full version can still hit the kit lock on Home.
- RPG data (`DrummerPathState`, card, keys) is computed in `ProgressStore` and must keep being computed in both modes.

## Rules

1. **Mode setting.** Add `playMode` (`story` | `free`) to the settings, default `story` for new and existing players, persisted and included in backup export/import (`BackupSettings`). Settings shows it as one row ("Story mode", Czech "Příběhový režim") with a short one-line hint, no extra screens.
2. **Story mode gating.** A lesson is available in Story mode when it is an Intro lesson, or its node on the Drummer's Path is completed or active. Use the existing Path map model as the single source of truth for this (one function, e.g. `isOpenInStory(lesson)`); do not add a second gating system. The purchase tier still applies on top (`store.isUnlocked`). Library, Home pads, Today plan and Review all use the same function. In the Library, lessons not yet opened by the story show as locked with the existing lock style and no new text.
3. **Free practice mode.** No story gating: availability = purchase tier only (today's behaviour). The Path map and story-only elements are hidden; the Training screen shows Today/Review as before; the Drummer card, XP, attributes and keys keep updating in the background so switching back to Story loses nothing.
4. **Kits never block a lesson (both modes).** Remove the kit check from Home, Today plan and Path node activation. Instead, in Story mode only, `SoundKitResolver` must resolve to an unlocked kit: if the kit the lesson (or "Automatic") would pick is locked, play the Starter kit. In Free mode all kits play normally. Keys and kit unlocking stay as they are (rewards for later).
5. **Switching mode** takes effect immediately, keeps all progress and never changes stars, keys or unlocked items.
6. Do not touch audio/MIDI timing. English is the primary language; add Czech strings for every new string.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Persistence/SettingsTypes.swift`, `SmackAPad/Sources/Persistence/SettingsManager.swift`, `SmackAPad/Sources/Persistence/SettingsManager+Backup.swift`, `SmackAPad/Sources/Progression/DrummerPathMapModel.swift`, `SmackAPad/Sources/Progression/TodayPlan.swift`, `SmackAPad/Sources/Audio/SoundKitResolver.swift`, `SmackAPad/Sources/UI/Home/HomeScreen.swift`, `SmackAPad/Sources/UI/Home/HomePadGrid.swift`, `SmackAPad/Sources/UI/Library/LibraryScreen.swift`, `SmackAPad/Sources/UI/Practice/TrainingScreen.swift`, `SmackAPad/Sources/UI/Settings/SettingsView.swift`.

## Tests

Add unit tests: default mode is `story` (fresh and migrated settings); Story gating opens Intro + completed/active Path nodes only, still respects the purchase tier; Free mode = purchase tier only; no code path blocks a lesson because of a locked kit; resolver falls back to Starter for a locked kit in Story mode and does not in Free mode; `playMode` round-trips through backup. Run the narrow tests for these files while working and the full `SmackAPadTests` suite on the iPad simulator once at the end.

## Acceptance criteria

- [ ] `playMode` setting exists, defaults to Story, persists and round-trips through backup.
- [ ] Story mode: Library, Home, Today and Review use one shared availability function based on the Path map plus the purchase tier.
- [ ] Free mode: availability = purchase tier only; Path map hidden; RPG data still updates.
- [ ] A locked kit never blocks a lesson; in Story mode a locked kit's sound falls back to Starter.
- [ ] App builds and `SmackAPadTests` passes on the iPad simulator.

### Manual iPad checks for Jakub (no good playing needed)

- Debug scenario `fresh`: Story mode is on; the Library shows only Intro (and the first open Path lesson) as playable, the rest locked.
- Settings → switch to Free practice: the Library opens per purchase tier, the Path map disappears; switch back: nothing lost.
- Your real profile: Story mode on, lessons you already have stars in are open, no lesson anywhere says it needs a kit.

## Agent assignment

Antigravity: **Gemini 4 Hydrogen, thinking medium** (it wrote ticket 241's model). Fallback: Codex Sol 6.2, high.

## Done rule

Build, run the full test suite on the iPad simulator once, commit on `release-polish`, and report changed files concisely.
