# 14 — Intro Section Screen

Status: ready-for-ipad-test

## Goal

Build the intro section entry point and exercise list for the 24 intro exercises.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.7 Progression — intro, §3.8 Screens — Intro section)
- `docs/DECISIONS.md` (§16 Intro)

## Tasks

1. Separate entry point accessible from the main navigation (not behind category unlock).
2. List the 24 intro exercises with pass/mastery status.
3. Intro-specific rules displayed: pass ≥80%, mastery requires 0 errors.
4. Tapping an exercise opens the play screen (reuses play screen from ticket 11).
5. Use Theme.swift tokens for all styling.

## Acceptance criteria

- [x] Intro section is always accessible (no unlock).
- [x] All 24 intro exercises listed with status.
- [x] Stricter pass/mastery thresholds clearly communicated.
- [ ] **iPad test**: renders correctly on iPad, landscape and portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: Simple list screen, reuses existing components.

## Done rule

Stop after successful build; Jakub tests on iPad.
