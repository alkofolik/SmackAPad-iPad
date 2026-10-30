# Bar Summary for the Scoring Engine (follow-up to 08)

Status: draft — Jakub approves before it goes to an agent

## Goal

Ticket 08 grades every hit and returns one result per attempt. The practice screen (`docs/design/2026-10-30-practice-screen-spec.md`) shows no per-hit feedback; it shows one word per bar. Add a bar summary on top of the existing engine. Do not change timing windows, calibration, adaptive centre, pass/mastery or tempo progression.

## Files to read

- `AGENTS.md`
- `docs/design/2026-10-30-practice-screen-spec.md`
- `docs/SPEC.md` (§5), `docs/DECISIONS.md` (§6, §7, §9)
- Ticket 08 (implemented)

## Tasks

1. When a bar ends, return a `BarSummary`: bar index, number of expected notes, matched, missed, extra, median signed timing offset of the matched hits (negative = early).
2. Derive one verdict per bar: `clean`, `ahead`, `behind`, `uneven`.
   - `clean`: all notes matched, none extra, offset small.
   - `ahead` / `behind`: median offset beyond a threshold in the early / late direction.
   - `uneven`: anything else (misses, extras, large spread). Errors are not counted or shown separately.
   - Proposal for thresholds (Jakub approves before merge): use a fraction of the level's perfect window; document them in DECISIONS §7.
3. The verdict is computed after the bar ends, never during it. It must not depend on the Listen mode (no scoring in Listen) or on whether the pattern is visible.
4. Tests first (tdd): a clean bar, a bar consistently early, a bar consistently late, a bar with a miss, a bar with an extra hit, a bar with empty pattern.

## Acceptance criteria

- [ ] Existing 08 tests still pass.
- [ ] New tests for the four verdicts pass.
- [ ] Verdict thresholds recorded in DECISIONS §7 and approved by Jakub.
- [ ] **iPad test**: verdicts feel fair; "ahead" and "behind" match what the player feels.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high (same agent and context as ticket 08).
- **Reasoning**: high. Timing logic with a subjective threshold; low reasoning tends to make the verdict flicker.

## Skill

tdd.

## Done rule

Stop after successful build; Jakub tests on iPad.
