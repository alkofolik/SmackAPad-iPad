# Review request

Attached: `00-brief.md` (what the app is and what was decided), screenshots of every screen (no video recordings are provided), and the source code (GitHub repository or ZIP).

Please review the native iPad app **Smack-a-Pad**, a finger-drumming trainer built by an independent developer. You cannot see or hear the app in motion; judge timing, sound and flow only from the screenshots, the brief and the source code, and say clearly when a point cannot be judged without video.

## Ground rules

- You are an independent reviewer. You have no stake in this app. The developer explicitly wants blunt, specific criticism; praise is only useful when it says what must not be lost.
- Base every finding on evidence from the materials: name the screenshot, document section or source file. If you are guessing, say so and lower your confidence.
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

**R1 — Complete beginner.** You own a cheap 16-pad controller and have never finger-drummed. Walk through the first launch, first lesson and first 10 minutes as seen in the screenshots. Where are you confused, lost, bored or stuck? What words do you not understand? When would you quit?

**R2 — iPad UX and accessibility expert.** Judge against Apple's Human Interface Guidelines for iPadOS: hierarchy, navigation, touch target sizes, readability at arm's length (iPad on a stand next to a controller), Dynamic Type, VoiceOver, colour contrast, motion, landscape and portrait. Point to concrete screens.

**R3 — Experienced finger-drumming teacher.** Judge the curriculum and practice method: order of lessons, difficulty steps, what is missing compared to how you teach real students (technique, posture, dynamics, groove feel, musicality), and whether the scoring rewards the right things. Judge the timing feedback from the screenshots of run results and from the scoring code.
