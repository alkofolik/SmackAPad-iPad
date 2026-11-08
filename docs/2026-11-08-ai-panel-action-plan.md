# Plán oprav podle AI panelu (2026-11-08)

Zdroj: `docs/reviews/ai-panel/results/synthesis.md` (čísla v závorkách = řádek tabulky „Decision list“). Jakub schválil 2026-11-08, pořadí navrhl Claude. Každá dávka = jeden ticket, teprve po odsouhlasení zadání.

## Dávka 1 – ochrana dat a důvěry (hned)
- [x] **T149 (ticket napsán: docs/tickets/2026-11-08-149-…)** Postup se nikdy nesmí přepsat po chybě načtení** (#1). Záloha poškozeného souboru, zákaz ukládání, varování, verze formátu, načítání po lekcích, testy se „zlatými“ soubory. Codex GPT-6.1 Sol, high.
- [ ] **AGENTS.md: před commitem projít všechny testy** (#2), plus pravidlo „odstraněné pravidlo = smazat kód i testy“ (#30) a doplnění šablony ticketů (#32). Úprava AGENTS.md, ukázat Jakubovi před zápisem.
- [x] **T150 Shrnutí dne a revize** (#3, #4, #5). Proč se 2 revize nezapočítaly, jasné stavy (zahráno / splněno / nezapočteno + důvod), staré ★3 vs „0 of 2“, „2 dnes“ místo 29, popisek předpovědi, pryč oranžové číslo z Home. Codex Sol, high.
- [ ] **T151 Dvojitý úder pad (~25 ms) se ignoruje** (#6; ticket napsán: docs/tickets/2026-11-08-151-…). Codex Sol, medium.
- [ ] **T152 Srovnat dokumenty s aplikací** (#7). SPEC hvězda 3, brief „verdikty po taktech“, 574 vs 587, 24 vs 25 intro, Learning 60 %. Gemini 3.8 Flash, high.

## Dávka 2 – vydání v App Store (blockery)
- [ ] Tickety 79 (privacy manifest, šifrování) a 81 + 80 (web, O aplikaci, kredity AVL CC BY-SA, odkazy) (#8, #9) – už existují, zařadit do pořadí.
- [ ] **T153 Nákupní okno: „529 lekcí navíc“** + co se hráč naučí; lokalizované hlášky nákupu; „Síť Session“ (#10, #20).
- [ ] **T154 Kontroléry a kontrola Applem** (#11, #14). Seznam otestovaných, přejmenovat „NI Maschine“, nápověda bez kontroléru, text Bluetooth, poznámky pro recenzenta (navázat na ticket 83).

## Dávka 3 – zvuk a stabilita
- [ ] **T155 Jeden zvukový engine, načíst jen vybranou sadu** (#13, souvisí s ticketem 121), pak zvuk padu mimo hlavní vlákno – měřit na starém iPadu.
- [ ] **T156 Změna výstupu zvuku během hry** (#12) a opožděný zvuk neukončí běh (#21).

## Dávka 4 – první spuštění a čitelnost
- [ ] **T157** „Začni tady“ pro nového hráče (#15), legenda zkratek padů (#17), dotykové plochy ≥ 44 pt (#18), kontrast ghost notes v režimu z paměti (#19), kontrola číslování Pad 1 v MIDI learn (#16).

## K rozhodnutí Jakuba (mění dřívější rozhodnutí)
- [ ] Revize skryjí vzor hned od 1. průchodu (#22)
- [ ] Ukazovat skutečnou, nevycentrovanou chybu v čase (#23)
- [ ] Denní relace podle času, pauza nových lekcí nad ~10 revizí (#24)
- [ ] Hvězda 2 jen s ≥ 80 % úderů perfect/good, nebo užší okna (#25)
- [ ] Hvězda 3 „Remembered twice“, „Settled“ až po 4. kroku (#26)
- [ ] Skrýt údaj o každém úderu v režimu z paměti / revizích / Mixu (#27)

## Údržba pro agenty (po dávce 1)
- [ ] `LearningRules.swift` – všechny prahy na jednom místě (#28)
- [ ] Rozdělit velké soubory, začít `Persistence.swift`, bez změny logiky (#29)
- [ ] Jedna cesta lokalizace + test, že každý klíč je v obou jazycích (#31)

## Mimo kód
- [ ] Uzavřený TestFlight, 5–10 cizích bubeníků, aspoň 1 starší iPad a 1 Bluetooth kontrolér – hned po dávce 1 (#33)
- [ ] Marketing: videa s nastavením kontrolérů, komunity, výrobci (#36)

## Později (po 1.0)
- [ ] Tempo i dolů (2× nahoru / 2× dolů) (#34) – porovnat s post-v1 plánem §4
- [ ] Kontrola síly úderu u lekcí s ghost notes (#35)
