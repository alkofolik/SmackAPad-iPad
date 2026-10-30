# AGENTS.md — Smack-a-Pad iPad

## Project
Native SwiftUI iPad app: a finger-drumming trainer. Played mainly on an external MIDI controller; app navigation is touch; on-screen touch pads are only a bonus. The old JS/Capacitor prototype is read-only knowledge; its distilled notes are in docs/LEGACY-NOTES.md. Never copy its code. The legacy folder may be read only when a task names it explicitly (to copy data files).

## Language
- Talk to Jakub in Czech, plain language. Explain each step and why. No shorthand or jargon.
- Code, comments, docs, commit messages, tickets: English.

## Working rules
- One task = one conversation. Read only AGENTS.md, your task, and files the task lists. Never touch anything outside this project folder.
- Final report: max 5 lines.
- Do not re-run tests that already passed. No extra tests. Use the tdd skill only for timing and scoring code.
- After a successful build, stop. Jakub tests on the iPad.
- Commit after every task (Jakub pushes in GitHub Desktop).
- Never use the implement or implement-spec skills.
- design-taste-frontend: read its rules only. Never run its scripts or browser steps.
- If you hit a usage limit: run /handoff.
- If something fails twice, stop and report. Do not loop.

## Layout
Docs in docs/. Tickets as local files in docs/tickets/.


## Agent skills

### Issue tracker
Issues and specs are tracked as local markdown files in `docs/tickets/`. See `docs/agents/issue-tracker.md`.

### Domain docs
Single-context layout stored in `docs/`. See `docs/agents/domain.md`.
