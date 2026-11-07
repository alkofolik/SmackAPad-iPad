# 137 — Proposal: Today session screen redesign (HTML previews, no code)

Status: ready-for-agent. Type: proposal. Source: Jakub, 2026-11-07 (screenshot "Opakování 2 ze 2"): "The whole Today window is ugly: ugly text, not centred, empty, unfinished."

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
