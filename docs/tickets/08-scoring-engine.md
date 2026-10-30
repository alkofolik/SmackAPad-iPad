# 08 — Scoring Engine

Status: ready-for-agent

## Goal

Implement the scoring engine with timing windows, pass/mastery logic, adaptive timing center, and BPM auto-progression.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§5 Scoring Rules — all subsections)
- `docs/DECISIONS.md` (§6 Scoring, §7 Philosophy of tolerance, §9 Adaptive timing center)

## Tasks

1. **Timing windows** (level-dependent):
   - L1–2: perfect ±45 ms, good ±100 ms, max ±200 ms.
   - L3–4: perfect ±38 ms, good ±85 ms, max ±175 ms.
   - L5: perfect ±30 ms, good ±70 ms, max ±150 ms.
2. **Timestamp flow**:
   - Raw MIDI timestamp → subtract calibration offset → subtract adaptive timing-center shift → final timestamp for window comparison.
3. **Adaptive timing center**: rolling median (window of 8 samples, gated ±100–110 ms). Shifts window, does NOT widen it.
4. **Double-hit guard**: second hit on same pad within 30 ms = wrong pad, not second match.
5. **Pass**: score ≥70% (non-intro), ≥80% (intro).
6. **Mastery**: clean run at or above targetBpm. Error limits: ≤15 hits → 0 errors, 16–32 → 1, >32 → 2. Intro always 0 errors.
7. **BPM auto-progression**: after clean run below targetBpm, increase tempo by user-selected step (1/2/5/10).

## Acceptance criteria

- [ ] Timing windows match §5.1 exactly for each level.
- [ ] Calibration offset applied once (not double-counted with outputLatency).
- [ ] Adaptive timing center shifts window correctly.
- [ ] Double-hit guard prevents re-matching within 30 ms.
- [ ] Pass/mastery thresholds match §5.3.
- [ ] BPM auto-progression fires after clean run below targetBpm.
- [ ] **iPad test**: scoring feels fair and matches player perception.

## Skill

Use the **tdd** skill for this ticket. Scoring logic must be test-driven.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Precise timing logic with multiple interacting rules. Critical for gameplay feel.

## Done rule

Stop after successful build; Jakub tests on iPad.
