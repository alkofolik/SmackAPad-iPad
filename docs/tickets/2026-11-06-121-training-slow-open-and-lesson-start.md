# 121 — Training: pad opens after ~5 s, lessons do not start from Training

Status: ready-for-agent. Source: Jakub, 2026-11-06 (iPad).

## Problem

1. **Slow open**: tapping the Training pad on Home shows nothing for about 5 seconds, then the Training screen opens.
2. **Lesson does not start**: from the Training screen a lesson cannot be started. The same lesson starts fine from the Library.

## Rules

1. Find why the Training screen is slow to appear (likely heavy work on the main thread when the screen is built: loading all lessons/progress, computing the mix or due list, or a blocking call in `init`/`body`). Move that work off the main thread or compute it once and cache it; show the screen at once (the pad-zoom transition from ticket 113 must start right away) and fill data in when ready. Measure before and after (simple timestamps in a debug log is enough) and give both numbers in the report.
2. Find why starting a lesson from Training fails while the Library path works. Compare both paths; Training must use the same start path as the Library (same session setup), not a copy that drifted. Name the cause in the report.
3. No changes to scoring or timing code.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/TrainingScreen.swift`, `SmackAPad/Sources/UI/LibraryScreen.swift` (how it starts a lesson), `SmackAPad/Sources/UI/AppNavigation.swift`, `SmackAPad/Sources/UI/HomeScreen.swift` (Training pad action only).

## Acceptance criteria

- [ ] Training screen appears without a visible delay (numbers before/after in the report).
- [ ] Every lesson offered in Training starts and plays.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: open Training, start a lesson.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: two diagnoses (performance + broken navigation path).

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
