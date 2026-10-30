# 16 — Milestone Code Review

Status: ready-for-agent

## Goal

Full code review of all modules after integration. Check standards compliance and spec coverage.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (all sections, especially §7 Acceptance Criteria)
- `docs/DECISIONS.md` (all sections)
- All source files in the project.

## Tasks

1. Use the `code-review` skill.
2. Review against two axes:
   - **Standards**: Does the code follow the project's documented coding standards (AGENTS.md)?
   - **Spec**: Does the code match what SPEC.md requires?
3. Check all acceptance criteria from SPEC §7 are addressed.
4. Verify calibration logic: offset measures against actual sound time, outputLatency used only for playback scheduling.
5. Verify content-pack architecture: LessonStore supports multiple sources.
6. Verify localisation: all UI strings in both languages.
7. Report findings. No fixes in this ticket — create follow-up tickets for any issues found.

## Acceptance criteria

- [ ] All modules reviewed against SPEC and AGENTS.md standards.
- [ ] Calibration logic verified correct (no double-counting of outputLatency).
- [ ] Content-pack loader architecture verified.
- [ ] Localisation completeness verified.
- [ ] Report delivered with any issues as follow-up tickets.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Thorough review requiring understanding of the full system. Uses code-review skill.

## Done rule

Stop after review report is delivered. No build required.
