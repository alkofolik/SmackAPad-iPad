# Review request

Attached: `00-brief.md` (what the app is and what was decided), screenshots of every screen, and the source code (GitHub repository or ZIP).

Please review the native iPad app **Smack-a-Pad**, a finger-drumming trainer built by an independent developer. Use web search for every market claim and cite sources with links.

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

**R1 — Market analyst.** Find the real competitors (apps, courses, hardware bundles) for learning finger drumming on pad controllers, on iPad and elsewhere. For each: price model, strengths, what they lack. Where exactly does Smack-a-Pad fit, and what is its sharpest possible positioning in one line? How big is the realistic audience?

**R2 — Pricing and business advisor.** The model is free download + one-time Full unlock (see brief). Is that right versus subscription, paid packs or controller-maker partnerships? Suggest a price and what should be free. How would the first 1 000 users find the app (App Store search terms, communities, YouTube, controller makers)? The developer is a solo hobbyist in the Czech Republic with no marketing budget.

**R3 — App Store Review risk.** List concrete reasons Apple could reject or delay this app (guideline numbers), especially: the app being usable without a MIDI controller during review, in-app purchase and restore, privacy, Bluetooth permission text, third-party sound licences, metadata. For each: how to avoid it.

**R4 — Devil's advocate.** Argue as strongly as you can why this app will fail. Then say which of your arguments you actually believe.
