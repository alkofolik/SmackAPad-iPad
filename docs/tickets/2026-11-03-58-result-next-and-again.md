# 58 — Result card: always offer "Next lesson"; "Start" becomes "Again"

Status: ready-for-agent. Source: Jakub's iPad test, 2026-11-03.
Agent: Gemini 3.8 Flash, high thinking.

## Symptom

After the run stops automatically on the second star, the result card offers only "From memory for ★3" and the main "Start" button. There is no way to move on to the next lesson without going for the third star.

## Cause

`PracticeScreen.swift`, the `result` view (around line 338): the memory-challenge button and `nextLessonControl` are an either/or (`if showsMemoryChallenge { … } else if passed { nextLessonControl }`).

## Rules

1. When the lesson is passed, the result card always shows `nextLessonControl`. When the memory challenge is available, it shows **both**: "From memory for ★3" and "Next lesson". Next lesson is the calmer secondary choice; the memory challenge keeps its current style. Lay them out side by side, or stacked if they do not fit.
2. The main transport button (`PracticeComponents.swift`, around line 141) reads **"Again"** instead of "Start" while a result card is shown (`session.summary != nil` and not running). Otherwise it stays "Start", and "Stop" while running. "Again" already exists in `SmackAPad/Resources/i18n/cs.tsv` ("Znovu"); do not add a new string.
3. The button does the same thing as before; only the label changes.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeScreen.swift` (`result`, `showsMemoryChallenge`, `nextLessonControl`), `SmackAPad/Sources/UI/PracticeComponents.swift` (the transport `buttons` and `ResultCard`).

## Do not

- Do not change star rules, auto-stop or the lesson order.
- No tests. If something fails twice, stop and report.

## Acceptance criteria

- [ ] After the second star: "From memory for ★3" and "Next lesson" are both visible.
- [ ] After any passed run: "Next lesson" is visible.
- [ ] The main button reads "Znovu" while the result is shown, and "Start" before the first run.
- [ ] Build passes. Commit, stop. Final report max 5 lines.
