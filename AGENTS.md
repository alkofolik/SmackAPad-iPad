# AGENTS.md — Smack-a-Pad iPad

## Project
Native SwiftUI iPad app: a finger-drumming trainer. Played mainly on an external MIDI controller; app navigation is touch; on-screen touch pads are only a bonus. The old JS/Capacitor prototype is read-only knowledge; its distilled notes are in docs/LEGACY-NOTES.md. Never copy its code. The legacy folder may be read only when a task names it explicitly (to copy data files).

## Language
- Talk to Jakub in Czech, plain language. Explain each step and why. No shorthand or jargon.
- Code, comments, docs, commit messages, tickets: English.

## Working rules
- One task = one conversation. Read only AGENTS.md, your task, and files the task lists. Never touch anything outside this project folder.
- Final report: max 5 lines.
- Write only the tests the ticket lists. Use the tdd skill only for timing and scoring code.
- Before every commit, run the full test suite (not only the new tests) and fix or report any failure. If xcodebuild stalls while finalizing logs after printing 'All tests passed', stop it and note that in the final report.
- When a ticket removes or changes a rule, delete the old code and the tests that enforce the old rule. Do not leave dead code or tests for a removed rule.
- After a successful build and a passing full test suite, stop. Jakub tests on the iPad.
- Commit after every task (Jakub pushes in GitHub Desktop).
- Never use the implement or implement-spec skills.
- design-taste-frontend: read its rules only. Never run its scripts or browser steps.
- If you hit a usage limit: run /handoff.
- If something fails twice, stop and report. Do not loop.

## Ticket template
Every ticket has: Status, Goal, Rules, Files to read, Tests, Acceptance criteria, Agent assignment (model and thinking level) and Done rule. Acceptance criteria are what can be checked in the app; list the manual iPad checks for Jakub separately.

## Layout
Docs in docs/. Tickets as local files in docs/tickets/.


## Agent skills

### Issue tracker
Issues and specs are tracked as local markdown files in `docs/tickets/`. See `docs/agents/issue-tracker.md`.

### Domain docs
Single-context layout stored in `docs/`. See `docs/agents/domain.md`.
