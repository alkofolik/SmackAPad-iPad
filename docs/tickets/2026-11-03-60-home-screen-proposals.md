# 60 — Home screen: design proposals (no app code)

Status: ready. Source: Jakub, 2026-11-03. Follow-up: ticket 61 (implementation) is written **after** Jakub chooses a proposal.

## Problem

1. On cold start the user sees only the launch animation (ticket 46, 1.6 s), which is too short to enjoy, and then lands straight in the library. The app has no front door: the logo is gone as soon as it appears, and a returning player has to find their lesson again in the library.
2. There is no place for the few things a player does first: continue where they stopped, open the library, change settings, see that the controller is connected.

## Goal

A **home screen** that becomes the new root of the app. The launch animation no longer ends by fading away; it **ends in the home screen**: the big logo (three black pads, orange "smack" pad, wordmark "Smack-a-Pad") stays on screen as the result of the animation, and the menu appears around/below it.

This ticket produces **proposals only**. Jakub chooses, then ticket 61 implements. **Do not change app code, asset catalogs, project settings or Localizable.strings.**

## What the home screen contains

Primary actions (large, always shown):

| Action (cs / en) | What it does |
|---|---|
| **Pokračovat / Continue** | Opens the next lesson: `progression.nextLesson(after: lessonStore.lesson(for: settings.lastLessonID), source: …)` — the same logic as the "Next" banner in the library. Shows a second line with the lesson name and its stars. **First run** (`lastLessonID == 0`): the button reads **Začít / Start** and opens the first Intro lesson. |
| **Knihovna / Library** | Opens the existing library (`LibraryScreen`). |
| **Nastavení / Settings** | Opens the existing settings sheet. |

Secondary items (smaller, proposals may place, merge or drop them; each proposal states which it keeps and why):

- **Úvodní cvičení / Intro** — shortcut to the Intro page (new players, and the rules popover from ticket 43).
- **Ovladač / Controller status** — one quiet line or chip: controller name when `midi.sources` is not empty, otherwise "Připoj ovladač / Connect a controller". Tapping it opens Settings (hardware section). This matters because the app is played mainly on an external MIDI controller.
- **Kalibrace / Calibration** — shortcut to latency calibration (today buried in Settings → Hardware and calibration).
- **Pokrok / Progress** — one line, e.g. total stars earned out of all (read from `ProgressStore`); not a button.
- **Plná verze / Full version** — only while locked content exists (`StoreManager`); opens the purchase sheet. Hidden for users who own everything.
- **O aplikaci / About** — version number and font licence line, tiny, at the very bottom.

Not in scope (do not draw as working features): free play, statistics page, accounts, news. If a proposal wants one of them, mention it in the README as an idea for later, not in the mockups.

## Animation → home (storyboard to design)

- Total time until the menu is **fully usable: about 3.0–3.5 s** (today 1.6 s). Menu items become tappable as soon as each appears; they do not wait for the end.
- Start frame = the static launch screen of ticket 46 (solid cream `#F2F0EA`, empty), so there is no flash.
- Logo build = the sequence of ticket 46 (three black pads pop in, the orange pad smacks in at 12°, wordmark rises in). It may be **stretched** (slower, calmer), not redesigned.
- After the smack the logo **settles to its home position and size** (it may move up and/or scale; it must be big — the dominant element) and the menu appears with a short stagger (≤ 0.12 s per item). No fade-out at the end: the last frame of the animation **is** the home screen.
- Tap anywhere during the animation jumps to the finished home screen (it does not dismiss it).
- Not replayed when the app returns from background. When the user comes back to home from the library or from a lesson, the logo and menu are already there (at most a short 0.25 s cross-fade; no logo animation).
- **Reduce Motion**: no movement; the finished home screen fades in (0.25 s).
- Native SwiftUI only (shapes, `withAnimation`, `TimelineView`/`Canvas`), no Lottie, no video, no packages.

## Rules for the design

- Identity: the existing logo exactly as in `docs/design/2026-11-03-logo-source/` (cream `#F2F0EA`, black pads `#111111`, orange `#FF5B1F`, wordmark as outlined paths; an on-dark logo SVG exists). Do not recolour the logo. UI chrome around it follows `Theme.swift` and `docs/DESIGN-BRIEF.md` (orange / black / white + derived greys, IBM Plex Sans, radii from `Theme.Radius`, spacing from `Theme.Space`).
- Decide and show **what the home background is**: cream in both appearances (continuity with the launch screen, as Jakub chose for the animation), or cream in light and black with the on-dark logo in dark. Recommend one; mockups show both appearances.
- iPad only, **landscape primary, portrait supported**, 11" and 13", Split View width not required. Controller player is often at arm's length: touch targets ≥ 48 pt, primary actions much larger (≥ 72 pt high), body text ≥ 18 pt.
- Czech labels first (as in the table), English as a one-line note per proposal where the length differs a lot.
- **Reject list from the design brief applies** (any one = redo). Especially: no centered hero + three identical feature cards, no uniform card grid with soft shadows, no gradients/glow/glassmorphism, no emoji, no untouched default SF Symbols as the icon language, no fake 3D.
- Honest to what SwiftUI can do without extra libraries.

## Deliverables (in `docs/design/2026-11-03-home-screen/`)

1. **Three clearly different proposals**, each a self-contained HTML preview (opens locally in a browser, no network, fonts from `SmackAPad/Resources/Fonts/` referenced by relative path or embedded):
   - shows **landscape 1194×834 and portrait 834×1194** side by side or switchable;
   - shows two states: **returning player** (Continue with a lesson name and stars, controller connected) and **first run** (Start, no controller, no stars);
   - has a **Replay** button for the animation → home sequence and a **Reduce Motion** switch;
   - has a light / dark switch.
2. A short **storyboard with timings** per proposal (table in the README: time, what happens).
3. `README.md` with: one paragraph per proposal, which secondary items it keeps, its background decision, how it would map to SwiftUI (one line), a **recommendation of one proposal** with reasons, and a list of open questions for Jakub.

Seed idea for **proposal A** (the other two must differ from it and from each other): *the logo is the menu* — the four pads of the logo are the four main actions: the orange "smack" pad = Pokračovat, the three black pads = Knihovna, Nastavení, Úvodní cvičení; the wordmark below; controller status and the tiny items as a quiet strip. Proposals B and C should try a different structure, for example a left-aligned typographic list of large rows under the logo (like printed labels on a hardware unit), and a split layout (logo on one side, menu on the other in landscape; stacked in portrait).

## Files to read

`AGENTS.md`, `docs/DESIGN-BRIEF.md`, `docs/design/2026-11-03-logo-source/README.md` and the SVGs there, `SmackAPad/Sources/UI/LaunchAnimationView.swift` (current sequence), `SmackAPad/Sources/App/SmackAPadApp.swift` (how the animation is overlaid today), `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Sources/UI/LibraryScreen.swift` (the "Next" banner and `next` logic only), `docs/tickets/2026-11-03-46-app-icon-and-launch-animation.md`. Read the rules of the `design-taste-frontend` skill only; do not run its scripts or browser steps.

## Acceptance criteria

- [ ] Three HTML previews open locally, both orientations, both states, Replay, Reduce Motion and light/dark switches work.
- [ ] Each proposal's final animation frame is the home screen (no fade-out to empty), and the first frame matches the cream launch screen.
- [ ] Primary actions are clearly larger than secondary items; every touch target ≥ 48 pt.
- [ ] README has storyboards, SwiftUI mapping lines, one recommendation and open questions.
- [ ] No file outside `docs/design/2026-11-03-home-screen/` is changed.
- [ ] **Jakub chooses** one proposal (or a mix); ticket 61 is then written.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking. This is a taste task: the three proposals must be genuinely different and avoid the "AI look" list, so low or medium thinking tends to produce three variations of one centered layout. If the result still looks generic after one revision, or the previews do not run, stop and hand the ticket to **Codex GPT-6.1 Sol, high** (as in ticket 45).
- Ticket 61 (implementation, fully specified by the chosen proposal) can then go to Gemini 3.8 Flash at **medium** thinking; the root-navigation change (home above the library, back-to-home) deserves **high** if it touches `NavigationSplitView` state.

## Done rule

Stop after the deliverables exist; do not commit. Jakub reviews, Claude commits afterwards.
