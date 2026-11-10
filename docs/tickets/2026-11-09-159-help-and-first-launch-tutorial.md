# 159 — "How it works" help and first-launch tutorial (design phase first)

Status: DRAFT written 2026-11-09, waiting for Jakub's approval. Amended 2026-11-09: content scope points 3 and 4 corrected (3rd star comes from two spaced reviews on separate days, not from a practice run; the agent's stop-on-conflict caught this). Blocked by: 158 (implemented, not yet tested on the iPad). Source: Jakub's iPad check 2026-11-08 (`docs/2026-11-08-ai-panel-action-plan.md`, section "Nové z kontroly na iPadu"); AI panel findings about unclear modes and rules. Related: 157 (first-run guidance), 158 (review launch), 150 (review summary states).

## Goal

The player can learn, in a simple and logical way, how the app works: the practice modes, From memory, reviews, tempo, stars and what counts. Two entry points: a first-launch tutorial that shows the rules on screen, and a help pop-up the player can open again at any time.

## Hard constraints (Jakub)

1. **No more explanatory text spread over the UI.** Do not add hints, captions or labels to existing screens. Help lives behind **one icon with a pop-up**, plus the first-launch tutorial.
2. The help and the tutorial themselves must be **visual first**: small animated or drawn examples using the real pattern band, pads and star icons (orange, black, white only), with the shortest possible caption. Target at most one short sentence per card.
3. The player must never have to think about switching modes (design stance, 2026-11-08). The help explains what the app already does for them; it does not introduce a new thing to manage.
4. English is the primary language, Czech is optional (existing localisation path). Every new string exists in both languages and is listed in the design doc.
5. Never block the player: the tutorial can be skipped at any moment and can be reopened from the help entry.
6. Do **not** change any scoring, review, star or tempo rule. The rules below are intentional and only get explained. If the text of a rule in this ticket disagrees with the code, stop and report; do not "fix" the code.

## Known trap: the (i) icon is already taken

The earlier plan said "reuse the existing (i) icon". On the practice screen `info.circle` is already **Lesson info** (`PracticeScreen.swift`, ~383), and Intro has a "Rules" button with the same symbol (`IntroScreen.swift`, ~95). Reusing it for general help would make two different (i) icons mean two different things on one screen.

The design doc must pick one of these and justify it (recommend the first):
- **A.** A distinct help symbol (e.g. `questionmark.circle`) in the practice toolbar group next to Legend, plus a row in Settings and a row on Home.
- **B.** Fold the help into the existing Lesson info pop-up as its first card.
- **C.** Only Settings plus Home, nothing on the practice screen.

Jakub decides.

## What the help must explain (content scope, in this order)

1. **The goal of a lesson**: play the pattern in time; stars show how well you know it.
2. **Listen vs Play**: Listen plays the lesson sound, is unscored and you may play along; Play is only you and the metronome and is scored.
3. **From memory**: the pattern is visible before START, the count-in starts, then it disappears (only in Play). Practising From memory does **not** award a star by itself; it is how you prepare for the reviews that earn the 3rd star (`SPEC.md` §5.3, "Practice *From memory* mode alone does NOT award Star 3").
4. **Stars**: 1st star = pass the lesson (the required number of runs), 2nd = reach the goal tempo cleanly (the required number of runs), **3rd = pass two spaced reviews in Training on separate days** (From memory at goal tempo; shown in the app as "Star 3: two reviews in Training · n of 2"). The 2nd star is enough to unlock the next stage. Source of truth: `SPEC.md` (~line 140–165) and `StarRequirement.swift` (~line 52); read the exact numbers there, do not copy them from this ticket.
5. **Tempo**: it can be changed only while stopped; it rises during a run when you play cleanly (the tempo-up banner).
6. **Reviews** (Today / Training): a lesson due for review starts ready (From memory, goal tempo). The first two From-memory passes are non-counting warm-ups; short lessons need at least about 3 runs, of which 1 to 2 must qualify. The exclamation circle means the review was played but did not count.
7. **Today, Training, Library, Mix, After me**: one line each on what the place is for, in a single overview card.
8. **Controller or touch**: pad controller via MIDI (Settings), touch pads in portrait, hardware keyboard. Neutral wording, no brand names, no tested-controller list.

Verify every statement against the code and `SPEC.md` / `DECISIONS.md` before it goes into a card. Anything unclear: list it as an open question for Jakub in the design doc.

## Phase 1 — design proposal (this ticket delivers ONLY this, no Swift code)

Create `docs/design/2026-11-09-help-and-tutorial.md` containing:

1. The entry point decision (A, B or C above) with a small wireframe each.
2. The **first-launch tutorial**: at most 5 screens or cards, flow, how to skip, when it appears (empty profile only, once; flag name), how it coexists with the T157 first-run behaviour (the pulsing Intro pad and the legend that opens once). The tutorial must come first and must not fight them; define the order.
3. The **help pop-up** structure: a list of short cards in the order of the content scope, each with its visual (what is drawn or animated, using which existing components) and its caption in English and Czech.
4. A table of every new string (key, English, Czech) and a count. Target: as few as possible.
5. Reduce Motion behaviour and accessibility labels for every animated card.
6. Which existing views and components can be reused, and what has to be built new. Estimate file count.
7. Open questions for Jakub (max 5).

Mock the proposal with 2 or 3 static previews (SwiftUI previews or simple images in `docs/design/2026-11-09-help-previews/`) so Jakub can judge the look. Cards use the app's own look only (three colours, IBM Plex Sans); no generic "AI look".

**Stop after Phase 1.** Jakub reviews and picks. Phase 2 (implementation) becomes a separate follow-up ticket written afterwards.

## Phase 2 — outline only (not part of this ticket)

Implement the approved entry point, the tutorial flow with an `@AppStorage` flag (e.g. `smackapad.tutorial.seen`), the help pop-up, the strings in both languages, a test that every new key exists in both languages, a test for the "show tutorial once, only on an empty profile" rule, and the Reduce Motion variants.

## Files to read

`AGENTS.md`, this ticket, `docs/2026-11-08-ai-panel-action-plan.md`, `docs/SPEC.md`, `docs/DECISIONS.md`, `docs/tickets/2026-11-09-157-*.md`, `docs/tickets/2026-11-09-158-*.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (toolbar ~330–400, legend, lesson info), `IntroScreen.swift` (Rules pop-up), `HomeScreen.swift` (first run, `PadLightBar`), `SettingsView.swift`, `StarRequirement.swift`, `TempoUpBanner.swift`, `TrainingScreen.swift` and `TodaySessionScreen.swift` (step markers), `Theme.swift`, `Components.swift`.

## Acceptance criteria (Phase 1)

- [ ] `docs/design/2026-11-09-help-and-tutorial.md` exists with all 7 parts above.
- [ ] The three entry options are compared, with a recommendation.
- [ ] Every rule stated in the cards is checked against code or `SPEC.md`; conflicts listed.
- [ ] String table in English and Czech with a total count.
- [ ] 2 or 3 previews included.
- [ ] No Swift, localisation or project file changed. Only docs.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Flash, high (weaker on visual design; use only if Codex is out of limit).
- **Reasoning**: a design document with a lot of reading across the codebase; a wrong rule in a card is worse than a missing one, so the check against the code matters more than speed.
- Phase 2 (later): Codex GPT-6.1 Sol, high.

## Done rule

Docs only, so no build or test run is needed. Commit the docs (AGENTS.md); Jakub reads them and decides. Final report max 5 lines: recommended entry option, number of cards, number of new strings, open questions.
