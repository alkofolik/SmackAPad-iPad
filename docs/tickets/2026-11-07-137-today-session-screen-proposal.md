# 137 — Proposal: Today session screen redesign (HTML previews, no code)

Status: ready-for-human. Type: proposal. Source: Jakub, 2026-11-07 (screenshot "Opakování 2 ze 2"): "The whole Today window is ugly: ugly text, not centred, empty, unfinished."

## Today's state

`TodaySessionScreen.swift`: a small card in the top-left corner ("OPAKOVÁNÍ 2 ZE 2", "Nepočítá se · dokonči průchod bez nápovědy", "Rock 1 · 83 % zpaměti při 94 BPM", "DALŠÍ Funk 1"), three buttons below, the rest of the screen empty. Mono caps labels look out of place.

## Task

One offline HTML file `docs/previews/137-today-session.html` with **3 variants**, iPad 11″ landscape + portrait, light + dark, in the app look (satin, Variant B buttons from 133, orange #FF6B00, IBM Plex Sans):

- Content centred and filling the screen; clear hierarchy: where I am in today's plan (step 1 Review / 2 New lesson / 3 Mix, with progress like "2 of 2"), result of the last lesson (big %, stars), what comes next (big lesson name, small pattern preview like Library rows), one main action "Pokračovat", secondary "Přeskočit", "Konec na dnes".
- The verdict line ("Nepočítá se · …") readable as a short sentence, not a headline.
- All texts in Czech, real lengths.

No Swift changes. Jakub picks; then an implementation ticket.

## Files to read

`AGENTS.md`, this ticket, `TodaySessionScreen.swift`, `TodayPlan.swift`, ticket 110, ticket 133.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Stop when the HTML opens offline. Commit (AGENTS.md).

## Proposal summary — 2026-11-07

Preview created at `docs/previews/137-today-session.html` with three distinct design variants:

1. **Varianta 1 — Satinová řídící konzole (Studio Console Plate)**:
   - Centred master satin console plate (16 pt radius, satin bevels, subtle drop shadow) on calm chassis.
   - Balanced two-column split in landscape (compact stack in portrait):
     - Left column: Previous run evaluation (dominant 68 pt score `83 %`, 3-star meter in orange, "Rock 1 · 8 osminových úderů · Cvičení zpaměti při 94 BPM", calm verdict sentence in status container: "Nepočítá se · Dokonči průchod bez nápovědy, aby se lekce uložila jako zvládnutá.").
     - Right column: Next step preparation ("Funk 1 · Nová lekce · 98 BPM · 4 takty groove", authentic 16-step sequencer pattern preview from Library rows, large 52 pt Variant B hero button "Pokračovat na Funk 1" + secondary "Přeskočit" and "Konec na dnes").
   - Stepper across top: 1. Rock 2 (done 91%) -> 2. Rock 1 (just played 83%) -> 3. Funk 1 (next) -> 4. Groove Mix (waiting).

2. **Varianta 2 — Dvě propojené karty (Dual Surface Bay)**:
   - Physical separation into two distinct satin bays:
     - Left card (Score Bay): Inset dark display showing `83 %` score, stars, Rock 1 details, accuracy/tempo breakdown (88 % / 78 %), and calm verdict sentence.
     - Right card (Launch Bay): Funk 1, 98 BPM tag, 16-step drum pattern strip, Hero "Pokračovat" and "Přeskočit" buttons.
   - Quiet "Konec na dnes" button centered at the bottom of the chassis.

3. **Varianta 3 — Čistá otevřená scéna bez rámečků (Open Typographic Stage)**:
   - Pure typographic execution without bounding inner panels (honoring the ticket 110 idea, but fully resolving centering and whitespace across the iPad).
   - Broad 860 pt stage:
     - Top block: 76 pt bold percentage `83 %`, stars, "Rock 1" and calm sentence verdict.
     - Hairline divider.
     - Bottom block: "Funk 1", 98 BPM, 16-step pattern sequencer preview.
     - Full-width action dock: [ Pokračovat na Funk 1 ] [ Přeskočit ] [ Konec na dnes ].

- **Interactive features**:
  - Orientation switcher: Landscape (1194×834) vs. Portrait (834×1194).
  - Theme switcher: Light vs. Dark mode.
  - Scenario switcher: Jakub's screenshot state (83% uncounted pass), Passed state (96% 3 stars), Start of day (no previous run), End of day ("To je pro dnešek vše").
  - Tactile Variant B button compression (scale 0.97, translateY 1.0pt) and 120ms pad flash.
  - 100% self-contained & offline: IBM Plex Sans embedded as base64.

