# Návrhy domovských padů a animací aplikace (Ticket 111)

Status: návrhy připraveny k rozhodnutí Jakuba.
Zdroj: Jakub (2026-11-06): *„Pady na Home vypadají obyčejně; šlo by je udělat modernější a hezčí? Taky mi celkově chybí moderní animace a přechody.“*
Návaznost: implementační ticket se sepíše po Jakubově výběru. V tomto úkolu se **nemění žádný kód aplikace, assety ani lokalizační řetězce**.

---

## 1. Rychlé odkazy na náhledy

Všechny náhledy jsou plně soběstačné a spustitelné přímo v prohlížeči na Macu (bez nutnosti webového serveru či internetového připojení; font IBM Plex Sans i vektorová grafika jsou přímo vloženy):

| Soubor | Návrh | Token zaoblení | Klíčový charakter |
|---|---|---|---|
| [**index.html**](index.html) | **Srovnání & Přehled** | – | Srovnávací přehled všech parametrů, živý tester padů vedle sebe a tabulky tokenů. |
| [**proposal-a.html**](proposal-a.html) | **Návrh A (Doporučeno)** | `Theme.Radius.pad = 8 pt` | **Akai MPC Tactile Rubber** — Taktilní silikonový pad s fazetkou, přirozeným stlačením a pružným odskokem. |
| [**proposal-b.html**](proposal-b.html) | **Návrh B** | `Theme.Radius.pad = 12 pt` | **Maschine Milk-Silicone** — Difuzní mléčný silikon s obvodovým světlovodem a horním proužkem. |
| [**proposal-c.html**](proposal-c.html) | **Návrh C** | `Theme.Radius.pad = 5 pt` | **SP-1200 Metal Collar** — Industriální pad zasazený do kovového šasi s klenutou kontrolkou DUE. |

Každý náhled obsahuje interaktivní lištu s přepínači:
- **Vzhled**: Světlý (krémová `#F4EFE6`) vs. Tmavý (teplá černá `#1F1D1A`).
- **Orientace**: Na šířku (1194×834) vs. Na výšku (834×1194).
- **Pohyb (Reduce Motion)**: Plný pohyb vs. Přísný režim bez posunů a deformací (max 0.2 s prolnutí).
- **Přechod (Zoom)**: Simulace nativního iOS 18 zoomu z rámečku padu vs. náhradní iOS 17 přechod.
- **Replay náběhu**: Znovuspuštění bootovací animace mřížky 3×3.
- **Simulace MIDI úderu**: Tlačítka 1–8 (či klávesy 1–8 na klávesnici) simulující reakci padu na úder z fyzického kontroleru.
- **Test relace Dnes**: Klepnutím na oranžový pad POKRAČOVAT/DNES se otevře obrazovka relace (ticket 109/110) s plynulým krokem mezi výsledkem a dalším cvičením bez poskakování tlačítek.

---

## 2. Podrobný popis jednotlivých návrhů

### Návrh A: Akai MPC Tactile Rubber (*DOPORUČENO*)
- **Inspirace a filozofie**: Klasické hutné silikonové pady bicích automatů Akai MPC (od MPC 2000XL po MPC One/Live). Pady mají přirozenou fyzickou váhu a hloubku, aniž by působily kýčovitě či plasticky.
- **Zaoblení**: `Theme.Radius.pad = 8 pt` (~8 px). Zlatá střední cesta – pad je na první pohled odlišen od ostrých tlačítek a panelů (ticket 94), ale zůstává přesně vymezeným bicím padem.
- **Materiál a hloubka**: Dvoutónová fazetka vytvořená jemnou horní světelnou hranou a spodním 2px stínem lůžka. Vytváří dojem autentického 4mm vyvýšeného silikonového bloku.
- **Stav svícení (Trénink)**: Při čekajících opakováních svítí obvodový oranžový lem padu s jemnou září a v pravém horním rohu klidně dýchá kruhová LED kontrolka (perioda 2.4 s).
- **Odezva na úder**: Mechanické stlačení (scale 0.965, y: 1.5 px) s bleskovým plošným zábleskem (60 ms) a rychlým pružným odskokem zpět (0.18 s spring).
- **Náběh mřížky**: Diagonální vlna z levého horního rohu (pad 1) do pravého dolního (pad 8) s odstupem 40 ms mezi sousedy.

---

### Návrh B: Maschine Milk-Silicone Backlit
- **Inspirace a filozofie**: Moderní elektronické nástroje jako Native Instruments Maschine MK3 nebo Ableton Push. Hladký, difuzní mléčný silikon s jemným sametovým povrchem a obvodovým světlovodem.
- **Zaoblení**: `Theme.Radius.pad = 12 pt` (~12 px). Měkčí, moderní křivka příjemná pro bříška prstů.
- **Materiál a hloubka**: Lícní plocha padu je rovná a flush s panelem, ohraničená 2px zapuštěným difuzním kanálkem.
- **Stav svícení (Trénink)**: Celý obvodový kanálek padu se rozsvítí teplým oranžovým světlem a horní hrana padu nese integrovaný 2px světelný proužek s klidným pulzem (3.2 s).
- **Odezva na úder**: Čistě luminescenční záblesk plochy (40 ms) bez vertikálního propadu, doprovázený nepatrným stlačením (scale 0.975) a plynulým radiálním rozpadem světla.
- **Náběh mřížky**: Radiální záblesk šířící se od středového loga – nejprve se v 80 ms rozsvítí 4 křížové pady (2, 4, 5, 7) a následně ve 190 ms 4 rohové pady (1, 3, 6, 8).

---

### Návrh C: SP-1200 / TR-808 Industrial Metal Collar
- **Inspirace a filozofie**: Industriální nástroje zlaté éry hip-hopu a elektroniky (E-mu SP-1200, Roland TR-808, studiové mixážní pulty). Pevný hardware s přesným strojním lůžkem.
- **Zaoblení**: `Theme.Radius.pad = 5 pt` (~5 px). Velmi jemné, architektonické zaoblení respektující původní pravoúhlou geometrii aplikace.
- **Materiál a hloubka**: Dvojitý rámeček – vnější 2px kovový límec šasi a vnitřní stín zapuštění. Pad vizuálně sedí ve frézovaném otvoru čelního panelu.
- **Stav svícení (Trénink)**: Vyražená kruhová LED kontrolka s mosazným lemem a klenutou oranžovou čočkou, doplněná mikronápisem `● DUE`.
- **Odezva na úder**: Ostrý mechanický ráz (y: 2 px, 0.07 s) se ztmavnutím stínu lůžka a okamžitým cvakavým odskokem.
- **Náběh mřížky**: Sekvenční hardware self-test po řádcích (řádek 1, řádek 2, řádek 3 po 70 ms), stejně jako při zapnutí studiového rackového modulu.

---

## 3. Doporučení jednoho návrhu

### **Jednoznačně doporučujeme Návrh A (Akai MPC Tactile Rubber).**

**Důvody:**
1. **Pravá podstata prstového bubnování**: Smack-a-Pad je trenažér pro finger drumming. Pady v Návrhu A mají přesně tu správnou hmatovou hloubku a odezvu, jakou hráč očekává od skutečného bicího kontroleru (Akai MPD / MPC).
2. **Přirozený kompromis zaoblení (8 pt)**: Zaoblení 8 pt zřetelně odděluje herní pady od běžných systémových tlačítek a panelů (které dle ticketu 94 zůstávají pravoúhlé), ale nepůsobí přehnaně jako měkká mobilní pilulka (což by hrozilo u 12 pt a více).
3. **Mimořádně uspokojivá odezva**: Krátké stlačení s bleskovým zábleskem (60 ms) a pružným návratem (0.18 s) dává perfektní vizuální potvrzení jak při dotyku prstem na iPadu, tak při úderu na externím MIDI kontroleru.
4. **Klidný a účelný pohyb**: Diagonální náběh i iOS 18 zoom z rámečku padu probíhají v bezpečném rozmezí 0.15–0.28 s, nezdržují uživatele a plně vyhovují všem zásadám `DESIGN-BRIEF.md`.

---

## 4. Mapování animací na Theme tokeny a Reduce Motion

Všechny animace jsou přesně navrženy tak, aby se v budoucím implementačním ticketu začlenily do `Theme.swift`:

| Animace | Navržený token | Doba a křivka | Reduce Motion varianta (Ticket 27) |
|---|---|---|---|
| **Stisk padu** | `Theme.Motion.padPress` | `0.08 s ease-out` + `0.18 s spring` | Žádný scale ani posun, pouze ztmavení výplně (0.10 s) |
| **Záblesk padu** | `Theme.Motion.padFlash` | `0.05 s ease-out` | Vypnuto |
| **Zoom pad → obrazovka** | `Theme.Motion.padZoom` | `0.28 s spring (response 0.28, damping 0.82)` | Čisté prolnutí opacity (0.15 s) |
| **Návrat obrazovka → pad** | `Theme.Motion.padDismiss` | `0.22 s ease-out` | Čisté prolnutí opacity (0.15 s) |
| **Krokování Dnes (109/110)** | `Theme.Motion.cardStep` | `0.24 s ease-out (+20 pt posun)` | Čisté prolnutí opacity bez posunu (0.15 s) |
| **Dýchání LED Tréninku** | `Theme.Motion.ledBreath` | `2.40 s sine ease-in-out` | Statické svícení bez animace |
| **Náběh mřížky (Boot)** | `Theme.Motion.bootStagger` | `40 ms mezi sousedními pady` | Zobrazení mřížky naráz prolnutím (0.20 s) |
