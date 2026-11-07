# 132 — Announce in advance that the third star unlocks the next day

Status: ready-for-agent. Source: Jakub, 2026-11-07. He thought the third star was broken at 100 %; it was the ticket 97 rule (star 3 only on a day after star 2). Not a bug; the player must be told earlier.

## Problem

The sentence "From memory: from tomorrow. Today it is practice." only appears after the player switches to From memory (`PracticeScreen.swift` ~578, ~932, ~1047; `session.isMemoryPracticeToday`). Nobody learns the rule before wasting a run.

## Rules

1. **At the moment star 2 is earned** (star award / result card of that run): add one short line "Star 3: from tomorrow." (cs: "Třetí hvězda: od zítřka."). Only when star 2 is fresh in this run.
2. **On the Practice screen, same day**: while `isMemoryPracticeToday` is true, show the same short line in the existing star requirement line for star 3, even when From memory is off (today it needs From memory on). Reuse the `StarRequirement` text path; no new element, no layout change; if no free space exists, extend the existing line.
3. **Next day**: the line disappears by itself (same `masteryDay` check, same injectable clock).
4. One wording across all places; reuse the existing localisation key where it fits, otherwise one new key in `en` and `cs`.
5. Rules of ticket 97 stay unchanged. No scoring, timing or persistence changes. Do not touch `TrainingScreen.swift` / `LibraryScreen.swift` (ticket 121 may still be running).

## Files to read

`AGENTS.md`, this ticket, ticket 97, `SmackAPad/Sources/UI/StarRequirement.swift`, `StarAward.swift`, `PracticeSession.swift` (~417–450), `PracticeScreen.swift` (~570–580, ~925–940, ~1040–1095), both `Localizable.strings`.

## Acceptance criteria

- [ ] Run that earns star 2 shows "Star 3: from tomorrow."
- [ ] Same day, From memory off: star 3 requirement line already says it.
- [ ] Next day (clock changed): line is gone; star 3 can be earned as before.
- [ ] Czech and English texts; both orientations, no layout shift.
- [ ] Build succeeds. No new tests, existing ones still pass.
- [ ] **iPad test (Jakub)**: earn star 2, read the line; next day it is gone.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: text and display only, existing flag.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
