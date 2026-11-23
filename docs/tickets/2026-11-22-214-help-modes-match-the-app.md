# 214 — Help for the practice modes does not match the app

Status: resolved (implemented in code; awaiting Jakub's iPad check). Reported by Jakub on 2026-11-20 (checklist "Help: topic list and short cards"): the help for the modes does not match reality, neither the text nor the icon.

## What is known

The practice toolbar has four mode controls (ear, drumsticks, speech bubbles, brain). The help texts `help.modes.caption` and `help.tutorial.modes.caption` (`Resources/en.lproj/Localizable.strings` ~lines 860 and 876, same keys in `cs.lproj`) describe only three modes: Listen, Play and After me. "From memory" is a separate toggle (brain icon) and is not in that card. `HelpDeck.swift` and `HelpIllustration.swift` hold the card structure and the drawn icons.

## Rules

1. **Audit first.** Before editing, compare, one by one, what each toolbar control really does in the code (`PracticeScreen.swift` toolbar, `PracticeSession` flags `listen`, `afterMe`, `fromMemory`, `unscored`) with what the help card says and shows. Write the findings as a short table into this ticket (control, real behaviour, what help says, wrong/ok).
2. Fix every mismatch in text and drawn icon, in Czech and English. Each icon in the help card must be the same symbol as the real toolbar button.
3. Keep the rules Jakub already decided: help cards 2–4 lines, plain wording, no extra UI text anywhere else, drum names English in both languages, "From memory" hides notes after two good passes (and, once ticket 216 is done, the peek rules; do not describe peek before it exists).
4. No changes outside help text and help illustrations.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/HelpDeck.swift`, `SmackAPad/Sources/UI/HelpIllustration.swift`, `SmackAPad/Sources/UI/PracticeScreen.swift` (toolbar), `SmackAPad/Resources/en.lproj/Localizable.strings`, `SmackAPad/Resources/cs.lproj/Localizable.strings` (keys `help.*`).

## Acceptance criteria

- [x] Audit table in this ticket.
- [x] Text and icons in the modes card (and the tutorial card) match the real controls, both languages.
- [x] Build and tests pass (localisation tests included).

## Audit

| Control | Real behaviour | What help says and shows | Verdict |
|---|---|---|---|
| **Listen** (`ear`) | Plays pattern audio; user can play along; fixed tempo; unscored, no stars earned; disabled while running or in Mix. | Texts (`help.modes.caption`, `help.tutorial.modes.caption`) describe hearing pattern, fixed tempo, no stars. Illustration `modesExample` draws `speaker.wave.2`. | **Wrong icon** (shows `speaker.wave.2`, toolbar uses `ear`). Text is OK. |
| **Play** (crossed drumsticks `.crossedSticks`) | Scrolling notes; user plays pads; clean passes raise tempo; hits scored; earns stars (★, ★★). Metronome and pattern sound configurable. | Texts describe playing pattern, earning stars, metronome / pattern sound. Illustration `modesExample` draws `hand.tap`. | **Wrong icon** (shows `hand.tap`, toolbar uses `.crossedSticks`). Text is OK. |
| **After me** (`bubble.left.and.bubble.right`) | Alternating passes (listen then repeat); notes hidden; response scored, no lesson stars (`unscored`). Disabled in Mix. | Texts describe listening to phrase and repeating, response score, no stars. Illustration `modesExample` draws `repeat`. | **Wrong icon** (shows `repeat`, toolbar uses `bubble.left.and.bubble.right`). Text is OK. |
| **From memory** (`brain.head.profile`) | Toggle button next to playback modes. Notes hide after two good passes in a row (or immediately if fade off). Prepares for reviews (★★★). | Omitted from Modes card and tutorial modes card. Dedicated card `help.memory.caption` erroneously instructs to tap "crossed-out eye" ("přeškrtnuté oko"), and `memoryExample` draws `eye.slash`. | **Wrong text and icon** (missing from Modes card; Memory card text and illustration use crossed-out eye instead of `brain.head.profile`). |

### Manual iPad checks for Jakub

Open How it works → modes, compare each icon and sentence with the toolbar in a lesson, in Czech and English.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
