# 184 — Remove the first-launch pop-up and bring the help texts up to date

Status: ready-for-agent. Approved by Jakub on 2026-11-12 (findings from his "fresh" scenario check of the help/tutorial).

## Goal

Three small, related fixes found while checking the app in the debug scenario "fresh":

1. The tutorial pops up by itself on the first launch. The "How it works" screen is more detailed, so the pop-up is not needed. Remove the automatic pop-up.
2. Since ticket 182 Today and Training are one screen ("Training"), but the help still talks about two screens.
3. Since ticket 177 the From-memory notes hide only after two good passes in a row, but the help card for From memory does not say the passes must be good.

## Rules

### A. No automatic tutorial
- Do not show the tutorial sheet by itself on a fresh/empty profile. Remove the auto-presenting logic in `HomeScreen.swift` (`tutorialEligible`, `showingTutorial` trigger, `tutorialBlocksInput` when it only existed for the pop-up) and `TutorialLaunch.shouldPresent` if nothing else uses it. No dead code, no unused keys.
- **Keep:** "Watch tutorial" / "Zobrazit tutoriál" in How it works (`help.tutorial.reopen`) with the same 5 cards, and the help screen itself.
- **Keep:** the first-run Intro pad pulse from ticket 157 (empty profile, no text, pad-abbreviation legend opening once on the first lesson). Today the pulse is set in the tutorial sheet's `onDismiss` (`introFocused = true`). It must now start on its own on an empty profile, without the sheet. Check this on the "fresh" scenario.
- Check `ProgressBackup.swift` / `SettingsManager.swift` and the tests (`FirstRunAndLegibilityTests`, `ProgressLoadFailureTests`) for references to `TutorialLaunch.seenKey`; adjust them, do not leave a stored key nobody reads.

### B. Help texts for one Training screen
Use the real button and card names from the strings added by ticket 182 (look them up, do not invent). Suggested wording, adjust the button names to the real ones:

- `help.training.title`: "Training" / "Trénink".
- `help.training.caption` EN: "Training is your plan for today. Continue starts the next step: up to two reviews, then a new lesson and a Mix when available. You can skip steps.\nBelow you find the review queue, your memory overview and the next seven days. You can put off reviews until tomorrow.\nStart an Extra mix once at least two lessons have ★★. Play them back to back at their goal tempos or choose Another mix.\nChoose After me to copy what the app plays, with the pattern hidden and no lesson stars."
- `help.training.caption` CS: "Trénink je tvůj plán na dnes. Pokračovat spustí další krok: nejvýš dvě opakování, potom novou lekci a podle dostupnosti Mix. Kroky můžeš přeskočit.\nNíže najdeš frontu opakování, přehled paměti a výhled na sedm dní. Opakování můžeš odložit na zítra.\nSpusť Extra mix, až budeš mít aspoň dvě lekce s ★★. Hraj je za sebou v cílovém tempu nebo vyber Další mix.\nZvol Po mně a zopakuj, co aplikace zahraje. Pattern je skrytý a hvězdy nezískáš."
- `help.tutorial.whereNext.caption` EN: "Start with Intro. Tap Rules there for the details.\nBrowse all lessons in Library.\nOpen Training for today's plan and your reviews.\nOpen the question mark in a lesson, or How it works on Home or in Settings."
- `help.tutorial.whereNext.caption` CS: "Začni v Intru. Podrobnosti najdeš pod tlačítkem Pravidla.\nVšechny lekce najdeš v Knihovně.\nPlán na dnes a opakování najdeš v Tréninku.\nV lekci klepni na otazník. Na Domově a v Nastavení najdeš Jak to funguje."
- Then search all `help.*` keys (both languages) for "Today", "Dnes" and "Training/Trénink" used as two separate places, and fix any other leftover. Cards keep 2–4 lines (ticket 169 rule).

### C. From-memory help card
`help.memory.caption`, EN and CS: say that the first pass shows the pattern, the second fades it only after a good first pass, and the pattern is hidden after two good passes in a row (80 % and more); a weaker pass starts the count again. Keep it within 4 lines. Keep the existing `%@` placeholder for the Settings option name. Keep it consistent with `help.reviews.warmups`.

## Files to read

- `AGENTS.md`
- `SmackAPad/Sources/UI/HomeScreen.swift`, `TutorialLaunch.swift`, `HelpDeck.swift`
- `SmackAPad/Sources/Persistence/SettingsManager.swift`, `ProgressBackup.swift`
- `SmackAPad/Resources/en.lproj`, `cs.lproj` strings (keys above)
- `docs/tickets/2026-11-09-157-*`, `2026-11-11-177-*`, `2026-11-11-182-*`

## Tests

Update the tests that referred to the pop-up. Add a test that an empty profile does not present the tutorial and that the Intro pulse still starts. Run the localisation validation (both languages) and the full suite.

## Acceptance criteria

- [ ] No tutorial pop-up on a fresh profile; "Watch tutorial" in How it works still opens the 5 cards.
- [ ] Intro pad pulse on an empty profile still works.
- [ ] No help text describes Today and Training as two screens.
- [ ] From-memory help states the "two good passes in a row" rule, EN and CS.
- [ ] No dead code or unused stored key; build and full suite pass.

### Manual iPad checks for Jakub

Debug scenario "fresh": app opens without any pop-up and the Intro pad pulses. Settings → How it works → Watch tutorial still plays the 5 cards. Read the Training and From-memory help cards in Czech and English.

## Agent assignment

Gemini 3.8 Flash, thinking **medium** (mostly text edits plus one small removal). Fallback: Codex GPT-6.1 Sol, medium, if the Intro-pulse change turns out to be tangled.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
