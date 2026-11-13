# 194 — Home pad lines: one line, shorter text (no "…")

Status: ready-for-agent. Reported by Jakub on 2026-11-13 with an iPad screenshot (English).

## What Jakub saw

On Home in English, two pad lines are cut off with "…":
- 03 Continue: "Kick on every b…" (lesson "Kick on every beat").
- 05 Controller: "Network sessio…" (the iPad's network MIDI session, "Network session 1").

The Czech texts must be checked the same way ("Kick na každou dobu", "Síťová relace 1").

## Rules

1. **One line stays** (ticket 181). What changes: the text itself must be short enough to fit, so it never ends in "…". This replaces 181's "truncated to one line" for the Continue pad.
2. **Length limit: 14 characters** for any Home pad line, in both languages (fits the pad at the narrowest supported layout; confirm on the iPad A16 simulator in portrait and landscape and lower the limit if 14 does not fit).
3. **Controller:** for the network MIDI session show "Network MIDI" / "Síťový MIDI" instead of "Network session 1". Other device names longer than the limit are cut at a word boundary without "…" (or to the first word if one word is already too long).
4. **Continue:** show the lesson's **short name**. Add an optional short name per lesson as localized strings (key `home.short.<lesson title>` in both `Localizable.strings` files) for every lesson whose title is longer than the limit in either language; lessons that fit use their title. Short names must still say what the lesson is (e.g. "Kick on every beat" → "Kick on beats" / "Kick na doby"). Put the full list of new short names into this ticket under `## Short names` for Jakub to review.
5. Delete the old truncation code on the pad line; no dead code.

## Files to read

`AGENTS.md`, `HomeScreen.swift` (`HomePadView`, `HomePadSubtitles`), `MIDIInput.swift` (line 87, network source name), `LessonData.swift` and `Resources/Data/*.json` (lesson titles), `en.lproj/Localizable.strings`, `cs.lproj/Localizable.strings`, ticket 181 (`docs/tickets/2026-11-11-181-back-arrow-and-home-pads.md`).

## Tests

1. `HomePadSubtitles.controller`: the network session returns "Network MIDI" / "Síťový MIDI"; a long device name is cut at a word boundary within the limit.
2. Every lesson (core, path, genre extensions, intro) has a Home line of at most 14 characters in English and in Czech (title or short name).
If an existing test enforces the old truncation, delete it.

## Acceptance criteria

- [ ] English and Czech Home: every pad line is one line with no "…", including Continue after "Kick on every beat" and Controller with the network session.
- [ ] Short names listed in the ticket for review.
- [ ] All eight Home pads are still exactly the same size, in landscape and portrait.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

Home in English and in Czech, landscape and portrait, with the network MIDI session connected and after playing "Kick on every beat": no "…" under any pad, pads all the same size, and the short names read well.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (many short names to write in two languages). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
