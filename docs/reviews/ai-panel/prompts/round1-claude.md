# Review request

Attached: `00-brief.md` (what the app is and what was decided), screenshots of every screen, and the source code (GitHub repository — please read it directly, including tests).

Please review the native iPad app **Smack-a-Pad**, a finger-drumming trainer built by an independent developer. Important context: the developer **cannot program at all**. Every line of code was written by AI coding agents (several different models) working from small ticket files in `docs/tickets/`. Your code findings must be useful to someone who will hand them to an AI agent, not fix them personally.

## Ground rules

- You are an independent reviewer. You have no stake in this app. The developer explicitly wants blunt, specific criticism; praise is only useful when it says what must not be lost.
- Base every finding on evidence from the materials: name the screenshot, video timestamp, document section or source file. If you are guessing, say so and lower your confidence.
- Do not invent features, screens or numbers. If something is not in the materials, write "not visible in materials".
- The app is played mainly on an external MIDI pad controller (finger drumming). Touch pads on screen are only a bonus. App navigation is by touch.
- Do not judge deliberate decisions listed in the brief as "Decided" unless you think one is a serious mistake; then say why in one finding.
- Prefer 10 sharp findings over 40 vague ones.

## Part A — Common core (answer exactly these, same for every reviewer)

A1. In one sentence: what is this app and who is it for, as you understand it from the materials?
A2. Scores from 1 (poor) to 10 (excellent), each with one sentence of reason:

| Axis | Score | Reason |
|---|---|---|
| First 10 minutes for a new user | | |
| Learning effectiveness (does it really make you a better finger drummer?) | | |
| Motivation to come back daily | | |
| Visual design and clarity | | |
| Readiness for App Store release | | |
| Commercial potential | | |

A3. The 3 strongest things (what must be protected in future changes).
A4. The 3 most serious problems, ranked.
A5. Would a target user pay for this? What one-time price for the Full unlock feels right, and why?
A6. If the developer could do only ONE thing in the next month, what should it be?

## Required output format

Answer in English, in Markdown, with these sections in this order and no others:

1. `## A. Common core` (A1–A6 as above)
2. `## B. Role findings` — one table per role, columns exactly:

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|

   - ID: role letter + number, e.g. `R1-03`.
   - Severity: `blocker` (must fix before release), `major`, `minor`, `idea`.
   - Confidence: `high`, `medium`, `low`.
   - Effort: `S` (hours), `M` (days), `L` (weeks).
3. `## C. What I could not judge` — what was missing from the materials, and what would change your mind.

## Part B — Your roles

Take each role in turn. Stay inside the role; do not repeat Part A.

**R1 — Senior iOS engineer (code and architecture).** Read the source. Focus on things that hurt real users: timing accuracy of MIDI input and scoring, audio latency, crashes, data loss of the player's progress (especially when an update changes the saved data format), memory and battery on older iPads, StoreKit purchase edge cases. Quote file paths and line numbers. Skip style nitpicks.

**R2 — Maintainability with AI agents.** This code base will keep growing only through AI agents with short tickets. Where is it fragile for that way of working: duplicated logic, files too large for an agent to read, unclear boundaries, missing tests on critical rules, conflicting docs, rules hidden in many places? What 3–5 structural changes would make future agent work safer? Also review how the tickets and `AGENTS.md` are written.

**R3 — Learning scientist.** Judge the learning design using evidence from motor-skill learning and spaced repetition: the star system, Training reviews, tempo progression, "From memory" mode, feedback after each run, difficulty curve. What is well grounded, what is likely to backfire (e.g. overjustification, wrong goals, frustration), and what small change would most improve real learning?
