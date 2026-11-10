# 163 — Nezávislá revize nápovědy „Jak to funguje“ a úvodního tutoriálu

Datum: 2026-11-10. Jen revize, nic v kódu se neměnilo. Zkontrolované soubory: `HelpDeck.swift`, `HelpIllustration.swift`, `TutorialLaunch.swift`, `PatternField.swift` (HelpPatternBand), klíče `help.*` v `en.lproj` a `cs.lproj`, design `2026-11-09-help-and-tutorial.md`, tickety 159 a 162 a k tomu kód obrazovek, podle kterého se ověřovalo, co aplikace opravdu dělá.

## 1. Shrnutí

1. **Každá karta má jen jednu heslovitou větu.** Ticket 159 povolil nejvýš jednu krátkou větu na kartu. Z popisků se tak staly slogany („Hraj přesně do rytmu a za pokrok získávej hvězdy“), které neříkají, co máš udělat, kde to najdeš ani co se pak stane. Nápověda se přitom otevírá až po klepnutí na (?), takže delší text hlavní obrazovky nijak nezaplní. Toto pravidlo je hlavní příčina problému.
2. **Obrázky jsou abstraktní a nic nepopisují.** Malý třířádkový pás, čtverečky padů a samotná „4“ nemají žádné šipky ani popisky, které by vysvětlily, co je řádek, co je čas, kde je tlačítko. Animace navíc proběhne jen jednou a trvá 0,8–1,6 s (`HelpIllustration.swift:24`). Kdo se dívá jinam, uvidí už jen statický obrázek.
3. **Tutoriál vysvětluje věci ve špatném pořadí.** Začátečníkovi ukáže Z paměti a třetí hvězdu přes „opakování“, ale co je opakování, se v tutoriálu nedozví. Tempo, které mění každý hned v první lekci, v tutoriálu chybí úplně.
4. **Názvy se neshodují s aplikací.** Třetí hvězda se jmenuje „Z paměti“, ale získáš ji opakováním. Nápověda mluví o „notách“ a „blednutí not“, kdežto aplikace používá „pattern“ a „Nápověda zpaměti postupně mizí“. Ve hře je třetí režim **Po mně**, ale nápověda ukazuje jen dva.
5. **Velká část funkcí není vysvětlená vůbec**, ani za (?): ikony nástrojové lišty, barvy úderů a pásu, Učení vs Výzva, filtry a etapy knihovny, MIDI learn a tlačítka kontroléru, zvukové sady, hlasitosti, kalibrace a záloha.

## 2. Karta po kartě

Tutoriál tvoří karty 1–4 (`HelpDeck.swift:95`), nápovědu všech 8 karet.

| # | Co chce říct | EN / CZ (dnes) | Co je nejasné | Oprava |
|---|---|---|---|---|
| 1 Lekce | Hraj pattern a sbírej hvězdy | „Play the pattern in time and earn stars as you learn it.“ / „Hraj přesně do rytmu a za pokrok získávej hvězdy.“ | Neříká, že každý řádek pásu je jeden pad, že čára jede zleva doprava, že se začíná tlačítkem START ani že úder se obarví (správně / mimo / špatně). Čtverec 2×2 se zkratkami HH/SN/KD nikdo nevysvětlí. „Za pokrok“ nic konkrétního neznamená. | Popsat pás šipkami „řádek = pad“, „čára = teď“, „START“. Text: 3 krátké řádky (viz T1 v kap. 5). |
| 2 Poslech a hra | Rozdíl mezi Listen a Play | „Play along in Listen, or play to the click for a score.“ / „Při poslechu se můžeš přidat, při hře na klik získáš skóre.“ | „Hra na klik“ je v češtině nesrozumitelný žargon. Hodnocení nezávisí na metronomu, ten se dá vypnout (`PracticeScreen.swift:1356`). Hráč nesbírá „skóre“, ale hvězdy. **Chybí třetí režim Po mně** (`PracticeComponents.swift:4-8`). Neříká, že Poslech nezvyšuje tempo (`PracticeSession.swift:955`). | Tři řádky: Poslech / Hra / Po mně, u každého „hraje aplikace / hraješ ty“ a „hvězdy ano/ne“. |
| 3 Z paměti | Hra bez patternu jako příprava na opakování | „Play without the notes to get ready for reviews.“ / „Hrou bez not se připravíš na opakování.“ | Neříká, kde se Z paměti zapíná (ikona přeškrtnutého oka). Neříká to hlavní: **při hře Z paměti v běžném cvičení nezískáš žádnou hvězdu** (`PracticeSession.swift:1145`, `StarStreak.swift:37` vrací vždy false). Čip „4“ po START bez popisu nikdo nepochopí. Slovo „noty“ aplikace jinde nepoužívá. V tutoriálu je karta zbytečně brzy. | Přesunout ji do nápovědy, z tutoriálu vyřadit. Doplnit ikonu oka, odpočet a jasnou větu „Hvězdy tu nezískáš, jen se připravíš.“ |
| 4 Hvězdy | Pravidla tří hvězd a otevírání etap | Nadpisy „Passed / Goal tempo / From memory“ = „Splněno / Cílové tempo / Z paměti“, řádek „Splň dvě opakování v různých dnech“, popisek „Další etapu otevře dostatek lekcí se dvěma hvězdami.“ | Třetí hvězda má nadpis „Z paměti“, ale podmínkou je opakování (`HelpIllustration.swift:166`). Na jedné kartě se míchají dvě témata, hvězdy a etapy. Šipka „★★ → Cesta“ svádí k dojmu, že jedna lekce otevře etapu. Neříká, že podmínky lekce najdeš pod ikonou hvězd na obrazovce lekce. Text „2krát“ vs „2krát po sobě“ se mění podle nastavení Učení/Výzva, které není nikde vysvětlené. Neříká, že lekce se sama zastaví po 2. a 3. hvězdě (`StarAward.swift:7`). | Rozdělit: Hvězdy (3 řádky + kde najdeš požadavky + automatické zastavení) a Etapy patří ke Knihovně. |
| 5 Tempo | Ruční nastavení a automatický růst | „Set tempo while stopped, then clean passes raise it up to the goal.“ / „Tempo nastavíš po zastavení, čisté průchody ho pak zvyšují až k cíli.“ | „Po zastavení“ zní jako „až potom, co zastavíš“. Obrázek ukazuje ⊖/⊕ u čísla, ale ve skutečnosti se klepne na pole tempa a otevře se okno −5/−1/+1/+5 a „Výchozí tempo“ (`PracticeScreen.swift:927-937`). Chybí, o kolik tempo vyskočí (nastavení, výchozí krok 5 BPM, `Persistence.swift:135`), co znamená „čistý“ průchod (0 chyb do 15 úderů, 1 do 32, jinak 2, `ScoringEngine.swift:180`) a že si lekce pamatuje poslední tempo (`PracticeSession.swift:275`). | Nakreslit skutečné pole tempa a okno. Tři řádky: kdy, jak, o kolik. Patří i do tutoriálu. |
| 6 Opakování | Jak se hraje a počítá opakování | „Due reviews open from memory at goal tempo.“ / „Opakování se otevře připravené ke hře zpaměti v cílovém tempu.“ + „Rozehrávka (při zapnutém blednutí not)“, „Dva celé průchody · cílové tempo nebo vyšší · každý alespoň 80 %“ | Neříká, **kdy** opakování přijde: den po 2. hvězdě, pak po 3, 7 a 21 dnech (`ReviewScheduler.swift:18, 213`). Neříká, co se stane při neúspěchu (krok zpět a znovu zítra, `ReviewScheduler.swift:200-204`), ani že po 4. úspěchu je lekce „Upevněná“. Chybí, že třetí hvězdu dá 2. úspěšné opakování, tedy nejdřív za 4 dny. „Blednutí not“ nesedí s názvem v Nastavení. Pásy bez not s fajfkou nic nevysvětlí. Popisek stojí nahoře, u ostatních karet dole. | Časová osa „Den 0 ★★ → +1 → +3 → +7 → +21 = Upevněno“. Pod ní 3 řádky: jak hrát, co se počítá, co znamená vykřičník. |
| 7 Kde hrát | Rozcestník obrazovek | Dnes / Trénink / Knihovna / Mix / Po mně, každá s jednou větou | Název „Kde hrát“ / „Jak hrát“ (karta 8) se plete. Chybí Intro, Odznaky a Nastavení. „Dnes“ existuje jen ve dnech, kdy je něco k opakování (`TodayPlan.swift:99`). Mix potřebuje 2 lekce se 2 hvězdami a hraje v cílovém tempu (`TrainingScreen.swift:439`, `PracticeSession.swift:275`). Po mně nedává hvězdy (`PracticeScreen.swift:279`) a je dostupné i přímo v lekci. Trénink má víc částí: kroky dne, přehled paměti, 7 dní dopředu a frontu. | Rozdělit na „Domů a Knihovna“ a „Dnes a Trénink“ s konkrétními řádky (kap. 5). |
| 8 Jak hrát (vstupy) | Kontrolér, dotyk, klávesnice | „Use a MIDI controller, a hardware keyboard or portrait touch pads with a 16-pad layout.“ / „Hraj na MIDI kontrolér, hardwarovou klávesnici nebo dotykové pady na výšku s rozložením 16 padů.“ | Neříká, kde co zapnout. Chybí rozložení kláves 1234 / QWER / ASDF / ZXCV (`KeyboardPadMapping.swift:5-10`), MIDI learn, tlačítka kontroléru (Start/stop, Restart, Poslech, Tempo ±, knob, `MIDIControl.swift:21`) a k čemu je kalibrace. Silueta kláves 5×2 neodpovídá mapování 4×4. | Rozdělit na „Kontrolér“ a „Dotyk a klávesnice“, v každé uvést cestu v Nastavení. |

Společné problémy prezentace:
- Nápověda je 8 karet za sebou a z lekce se vždy otvírá od karty 1. Chybí obsah, ze kterého by se dalo skočit rovnou na téma.
- Popisek je jediný text na kartě a mnoho termínů (Splněno, rozehrávka, Cesta) karta nevysvětlí.

## 3. Chybějící funkce a možnosti

T = tutoriál, N = nápověda, — = nikam (stačí UI samo).

| Funkce | Kde v kódu | Dnes | Kam |
|---|---|---|---|
| Tři režimy Poslech / Hra / **Po mně** v lekci | `PracticeComponents.swift:4-8`, `PracticeScreen.swift:329-345` | jen 2 režimy | T + N |
| Ikony lišty: Info o lekci, Legenda, ?, Další nástroje, Z paměti, Statický/Posuvný pohled (opakované klepnutí přidá takty) | `PracticeScreen.swift:350-420` | nic | N (mapa obrazovky) |
| Barvy úderů (správně / mimo / špatně) | `PracticeComponents.swift:11-19` | jen náznak v kartě 1 | T + N |
| Tón pásu (sytější blíž k cíli, záře vpravo = spěcháš, vlevo = zpožďuješ), barva Poslechu | `PracticeScreen.swift:899-908` (jen v Info o lekci) | nic | N |
| Verdikty taktů (čistě / napřed / pozadu / nerovnoměrně), výsledek a detail, „Znovu / Hrát dál / Další lekce“ | `PracticeComponents.swift:55`, `PracticeScreen.swift:820, 865` | nic | N |
| Z paměti v cvičení nedává hvězdy | `PracticeSession.swift:1145`, `StarStreak.swift:37` | neřečeno | T (1 věta) + N |
| Mizení patternu (1. průchod vidět, 2. mizí, od 3. skrytý), přepínač v Nastavení | `PatternField.swift:12-33`, `SettingsView.swift:161`, výchozí zapnuto `Persistence.swift:569` | ano, ale jiným názvem | N |
| Učení vs Výzva (sčítání vs „po sobě“) | `StarStreak.swift:2-10`, `SettingsView.swift:135-149` | nic | N (u Hvězd) |
| Počet průchodů na hvězdu (min. 16 úderů, max 4 průchody; Intro 3 pro 2. hvězdu) | `StarStreak.swift:66, 78-81` | jen v textu požadavku | N (1 řádek) |
| Hranice 70 % / Intro 80 % | `ScoringEngine.swift:184` | nic | N |
| Ikona hvězd = požadavky této lekce | `PracticeScreen.swift:1089-1115` | nic | T + N |
| Automatické zastavení po 2. a 3. hvězdě a po splněném opakování | `StarAward.swift:7`, `PracticeSession.swift:1080, 1174` | nic | N |
| Ruční tempo (okno −5/−1/+1/+5, Výchozí tempo), paměť tempa na lekci | `PracticeScreen.swift:927-937`, `PracticeSession.swift:275` | nepřesně | T + N |
| Krok automatického tempa 1/2/5/10, výchozí 5 | `Persistence.swift:127-135`, `SettingsView.swift:125`, `PracticeScreen.swift:1360` | nic | N |
| Smyčka taktů (procvičení části) bez hvězd | `PracticeScreen.swift:1406-1413` | nic | N |
| Rozvrh opakování 1/3/7/21, neúspěch = krok zpět a zítra, Upevněno | `ReviewScheduler.swift:10-18, 186-205` | nic | N |
| Vykřičník = zahráno, ale nezapočteno (důvody) | `TodayPlan.swift:13-28, 145-168` | jen ikona | N |
| Dnes: max. 2 opakování → nová lekce → Mix; bez opakování plán Dnes nevznikne | `TodayPlan.swift:97-104`, `TrainingScreen.swift:571-577` | 1 věta | N |
| Nová lekce v plánu Dnes se počítá od 80 % (ne 70 %) | `TodayPlan.swift:16`, `TodaySessionScreen.swift:639` | nic | otázka 3 |
| Trénink: kroky dne, přehled paměti, 7 dní dopředu, fronta, odložení | `TrainingScreen.swift:295-460, 605, 677, 826, 553` | 1 věta | N |
| Mix (2+ lekce se 2★, cílové tempo, „Nový mix“) | `TrainingScreen.swift:1104-1157`, `PracticeSession.swift:275` | 1 věta | N |
| Po mně (aplikace zahraje, ty zopakuješ, bez hvězd) | `TrainingScreen.swift:1193-1225`, `PracticeScreen.swift:279` | 1 věta | N |
| Knihovna: Cesta / Žánry / Techniky, hledání, filtry hvězd (3★/2★/1★/rozehrané/nezačaté), skrytí kategorie, „Zobrazit dokončené“ | `LibraryCatalog.swift:3-68`, `LibraryScreen.swift` | „Procházej a vybírej lekce“ | N |
| Odemykání etap: 2★ v min(½ etapy, 10) lekcích; Intro a rozšíření vždy otevřené; ruční odemčení s „Opravdu?“ a znovuzamčení; zamčená lekce skočí na banner | `Progression.swift:561-565`, `LibraryScreen.swift:862-905` | vágně v kartě 4 | N |
| „Další lekce z“ (Cesta / Žánr / Technika / Vše), „Skrýt dokončené“ | `SettingsView.swift:206-215`, `LibraryCatalog.swift:85-92` | nic | N (1 řádek) |
| Rozložení padů (malá mřížka svítí při úderu), 8 vs 16 padů, „Lekce vyžaduje 16 padů“ | `SettingsView.swift:159`, `ControllerSetupView.swift:304`, `PracticeScreen.swift:768` | nic | N |
| Dotykové pady (na výšku, zapnuté, profil 16 padů) | `PracticeScreen.swift:72`, `SettingsView.swift:160` | ano | N |
| Klávesnice (mapa 1234/QWER/ASDF/ZXCV, přepínač) | `KeyboardPadMapping.swift:5-10`, `SettingsView.swift:219-248` | bez mapy | N |
| Kontrolér: předvolby, MIDI learn, tlačítka kontroléru, knob tempa (jen když lekce stojí), monitor vstupu | `ControllerSetupView.swift`, `MIDIControl.swift:21-66` | nic | N |
| Kalibrace časování (zvlášť pro dotyk/klávesnici/kontrolér a výstup zvuku) | `CalibrationView.swift`, ticket 156 | jen nápis | N |
| Zvukové sady včetně „Automaticky“ a volby pro jednu lekci | `SettingsView.swift:85-96`, `SoundKitResolver.swift:32, 127-143`, `PracticeScreen.swift:1363` | nic | N |
| Hlasitosti metronomu, padů a patternu; zvuk patternu při Hře | `SettingsView.swift:102-118`, `PracticeScreen.swift:1354, 1374-1396` | nic | N |
| Záloha a obnovení postupu (soubor, nic se nepřepíše horším) | `SettingsView.swift:465-555` | nic | N (důležité, ztratil jsi tak postup) |
| Připomínka opakování | `SettingsView.swift:171-203` | nic | N (1 řádek u Opakování) |
| Vzhled, jazyk, nákup plné verze, odznaky | `SettingsView.swift:252-270`, `PurchasesView.swift`, `BadgesScreen.swift` | nic | — (popisuje se samo) |
| Pravidla Intro (ikona Pravidla) | `IntroScreen.swift:100` | nic | N (odkaz) |

## 4. Nepřesnosti

1. **Třetí hvězda „Z paměti“.** `HelpIllustration.swift:166` dává 3. hvězdě nadpis „From memory / Z paměti“, ale ve hře Z paměti ji nezískáš (`StarStreak.swift:37` vrací `false`). Získáš ji 2. úspěšným opakováním (`ReviewScheduler.swift:139-148`). Stejný název používá oznámení hvězdy (`PracticeScreen.swift:941`).
2. **„Dvě opakování v Tréninku“.** `StarRequirement.swift:53` (cs:668 „dvě opakování v Tréninku“) tvrdí, že se počítá jen Trénink. Od T158 se ale počítá i opakování spuštěné z Knihovny nebo z Domova. Nápověda (`help.stars.reviews`) mluví o „různých dnech“, takže hráč dostane dvě různé verze pravidla.
3. **Dva režimy místo tří.** Karta 2 ukazuje jen Poslech a Hru. Lekce má i Po mně (`PracticeComponents.swift:7`, `PracticeScreen.swift:331`) a karta 7 ho vydává za položku jen z Tréninku.
4. **„Při hře na klik získáš skóre.“** Hodnocení běží i s vypnutým metronomem (`PracticeScreen.swift:1356`, `PracticeSession.swift:926`). Navíc v Poslechu se také dá hrát a hvězdy tam nejsou. Věta směšuje metronom a hodnocení.
5. **Ovládání tempa na obrázku.** Karta 5 kreslí ⊖ hodnota ⊕ (`HelpIllustration.swift:217-220`). Skutečné ovládání je pole „80 → 100 BPM“ a po klepnutí okno s −5/−1/+1/+5 a „Výchozí tempo“ (`PracticeScreen.swift:927-937`).
6. **„Projdi dnešní plán.“** Plán Dnes vzniká jen tehdy, když je aspoň jedno opakování na řadě (`TodayPlan.swift:99`). V ostatní dny ho nahradí náhradní plán Tréninku (`TrainingScreen.swift:577`). Na iPadu je třeba ověřit, co v takový den ukazuje dlaždice Dnes na Domově.
7. **Nesoulad terminologie.** „Rozehrávka (při zapnutém blednutí not)“ (cs:876) vs přepínač „Nápověda zpaměti postupně mizí“ (cs:690). „Noty“ vs „pattern“ (cs:393 „Zvuk patternu“).
8. **Duplicitní klíč „Start“ v češtině.** `cs.lproj/Localizable.strings:434` „Začít“ a `:798` „Začátek“. Hodnotu použije tutoriál (`HelpIllustration.swift:121`) i tlačítko START (`PracticeComponents.swift:245`). Při duplicitě se zachová jen jedna hodnota, takže na iPadu je třeba ověřit, zda START neukazuje „Začátek“. Stejně je na tom EN (`en:435` a `:793`, tam je text shodný).
9. **80 % vs 70 % (mimo nápovědu, ale hráče to zmate).** Nová lekce v plánu Dnes je „splněná“ až od 80 % (`TodayPlan.swift:16`, `TodaySessionScreen.swift:639` „Aim for 80%…“). 1. hvězda se přitom dává od 70 % (`ScoringEngine.swift:184`), v Učení dokonce od 60 % s 85 % dobrých úderů (`StarStreak.swift:16-20`).
10. **Karta Hvězdy v tutoriálu** bere text požadavku z nastavení Učení/Výzva (`StarRequirement.swift:34-46`), jenže tento pojem tutoriál nikde nevysvětlí. Ukázka „Reach 100 BPM cleanly, 2 times“ je navíc vymyšlená lekce, ne ta, kterou hráč uvidí.

## 5. Návrh nové struktury

**Zásada:** hlavní UI zůstává bez dalšího textu. Za (?) může být na kartě nadpis, ilustrace **s popisky přímo v obrázku** (šipky, čísla 1–2–3) a **2–4 krátké řádky** začínající slovesem. Animace se má opakovat ve smyčce (při Omezení pohybu zůstane statická).

### Úvodní tutoriál (5 karet, cca 40 s)

| # | Účel | CZ | EN | Ilustrace |
|---|---|---|---|---|
| T1 Jak hrát lekci | Základ obrazovky | **Hraj, co jede v pásu.** · Každý řádek je jeden pad. · Čára ukazuje, kdy udeřit. · Stiskni START, po odpočtu hraj. | **Play what moves along the band.** · Each row is one pad. · The line shows when to hit. · Press START, play after the count-in. | Pás 2 taktů se šipkami „řádek = pad (HH)“, „čára = teď“, vpravo dole tlačítko START. Smyčka: čára dojede k notě a pad se rozsvítí. |
| T2 Barvy úderů | Zpětná vazba | **Barva ukáže, jak se ti úder povedl.** · Správně · Mimo rytmus · Špatný pad. | **Colour shows how each hit went.** · Right · Off time · Wrong pad. | Tři noty v pásu ve třech barvách, každá s popiskem. |
| T3 Tři režimy | Poslech / Hra / Po mně | **Poslech:** aplikace hraje, ty se můžeš přidat, bez hvězd. · **Hra:** hraješ ty s metronomem, sbíráš hvězdy. · **Po mně:** aplikace zahraje takt, ty ho zopakuješ, bez hvězd. | **Listen:** the app plays, join in, no stars. · **Play:** you play with the metronome and earn stars. · **After me:** the app plays a bar, you repeat it, no stars. | Tři klávesy režimů jako v liště, u každé ikona „hraje aplikace / ty“ a ★ nebo přeškrtnutá ★. |
| T4 Hvězdy a tempo | Cíl lekce | ★ Splň lekci. · ★★ Zahraj ji čistě v cílovém tempu (tempo samo roste o 5 BPM po každém čistém průchodu). · ★★★ Za pár dní ji zahraj zpaměti při opakování. · Požadavky lekce najdeš pod ikonou hvězd. | ★ Pass the lesson. · ★★ Play it cleanly at goal tempo (tempo rises 5 BPM after each clean pass). · ★★★ Play it from memory in reviews over the next days. · The star icon shows this lesson's requirements. | Tři řádky hvězd. U ★★ pole tempa 80 → 85 → … → 100. U ★★★ kalendář „zítra, za 3 dny“. Šipka na ikonu hvězd. |
| T5 Kam dál | Orientace | **Začni v Intru.** · Knihovna: všechny lekce. · Trénink a Dnes: opakování a denní plán. · Vše další najdeš pod (?). | **Start with Intro.** · Library: all lessons. · Training and Today: reviews and the daily plan. · Find everything else under (?). | Mini Domov se zvýrazněnými dlaždicemi Intro, Knihovna, Trénink, Dnes a ikonou (?). |

### Nápověda (rozcestník témat + karty)

První obrazovka je **seznam témat** (12 řádků). Z lekce se nápověda otevře rovnou na téma „Obrazovka lekce“. Dole zůstává „Zobrazit tutoriál“.

| # | Téma (CZ / EN) | Text CZ (EN analogicky) | Ilustrace |
|---|---|---|---|
| 1 | Obrazovka lekce / The lesson screen | Očíslovaná mapa: 1 Info o lekci · 2 Legenda zkratek · 3 Nápověda · 4 Další nástroje (takty, zvuk, smyčka) · 5 Z paměti · 6 Statický / posuvný pohled (opakované klepnutí přidá takty) · 7 Tempo · 8 Hvězdy · 9 START/STOP/RESTART. | Zmenšený snímek obrazovky lekce s čísly. |
| 2 | Režimy / Modes | Jako T3 + „Poslech nezvyšuje tempo. V Hře můžeš zapnout i zvuk patternu (Další nástroje).“ | Tři klávesy. |
| 3 | Barvy a ukazatele / Colours and signals | Barvy úderů · Pás sytější blíž k cíli · Záře vpravo = spěcháš, vlevo = zpožďuješ · Po běhu výsledek a detail po taktech. | Pás s barevnými údery a září na okraji, proužek výsledku. |
| 4 | Hvězdy / Stars | 3 řádky jako T4 · „Počet průchodů závisí na délce lekce (aspoň 16 úderů na hvězdu).“ · „Učení: dobré průchody se sčítají. Výzva: musí jít po sobě (Nastavení).“ · „Po 2. a 3. hvězdě se lekce sama zastaví.“ | Hvězdy + přepínač Učení/Výzva. |
| 5 | Tempo / Tempo | „Klepni na tempo, když lekce stojí: −5 −1 +1 +5, Výchozí tempo.“ · „V Hře tempo po čistém průchodu samo stoupne až k cíli. Krok nastavíš v Nastavení (1/2/5/10).“ · „Lekce si pamatuje tvoje tempo.“ | Skutečné okno tempa + banner „Tempo nahoru“. |
| 6 | Z paměti / From memory | „Zapni ikonou oka, pak START.“ · „1. průchod vidíš, 2. mizí, od 3. je pattern skrytý (Nastavení: Nápověda zpaměti postupně mizí).“ · „Hvězdy tu nezískáš, je to příprava na opakování.“ | Ikona oka → odpočet → tři pásy. |
| 7 | Opakování / Reviews | Osa „★★ → zítra → +3 → +7 → +21 dní = Upevněno“ · „Lekce se otevře připravená: zpaměti, cílové tempo.“ · „Počítají se 2 celé skryté průchody, každý ≥ 80 %. Pak se lekce zastaví.“ · „Nepovede se? Vrátí se zítra.“ · „Vykřičník = zahráno, nezapočteno.“ · „Druhé úspěšné opakování dá ★★★.“ | Časová osa + vykřičník. |
| 8 | Dnes a Trénink / Today and Training | „Dnes: až 2 opakování, pak nová lekce a Mix. Krok můžeš přeskočit.“ · „Trénink: fronta opakování, přehled paměti a 7 dní dopředu.“ · „Mix: naučené lekce (★★) za sebou v cílovém tempu.“ · „Po mně: bez not, bez hvězd.“ · „Připomínku zapneš v Nastavení.“ | Kroky 1–2–3 jako v Tréninku. |
| 9 | Knihovna / Library | „Řaď podle Cesty, Žánru nebo Techniky. Filtruj hvězdami, hledej.“ · „Další etapa Cesty se otevře, když máš ★★ v polovině lekcí té předchozí (nejvýš v 10).“ · „Etapu můžeš odemknout i ručně a zase zamknout, dokud nemá hvězdy.“ · „Intro a rozšíření jsou vždy otevřené.“ | Řádek etapy se zámkem a počítadlem. |
| 10 | Kontrolér / Controller | „Připoj MIDI kontrolér (USB nebo Bluetooth) v Nastavení → Ovladač a kalibrace.“ · „Vyber předvolbu 8/16 padů, nebo pady nauč pomocí MIDI learn.“ · „Tlačítka kontroléru: Start/stop, Restart, Poslech, Tempo ±, knob tempa.“ | Kontrolér 4×4 + tlačítka s popisky. |
| 11 | Dotyk a klávesnice / Touch and keyboard | „Dotykové pady: iPad na výšku, zapni v Nastavení, profil 16 padů.“ · „Klávesnice: řádky 1234 / QWER / ASDF / ZXCV = pady shora dolů.“ | Mřížka 4×4 s písmeny kláves. |
| 12 | Zvuk, kalibrace, záloha / Sound, timing, backup | „Zvuková sada: Automaticky vybere sadu podle lekce, pro lekci ji změníš v Dalších nástrojích.“ · „Hlasitost metronomu, padů a patternu zvlášť.“ · „Kalibrace srovná zpoždění zvuku, zvlášť pro dotyk, klávesnici a kontrolér.“ · „Zálohuj postup do souboru (Nastavení → Postup). Obnovení nic nepřepíše horším.“ | Tři ikony s popisky. |

Nové klíče: ~5 pro tutoriál po 3–4 řádcích a ~12 témat po 3–5 řádcích, celkem asi 70 řádků v každém jazyce. Kde to jde, použijí se existující klíče (názvy režimů a nastavení), aby nápověda mluvila stejnými slovy jako UI.

Doporučení pro zadání implementace: **Codex GPT-6.1 Sol, reasoning high.** Úkol je z velké části jen texty a ilustrace, ale ilustrace musí přesně odpovídat pravidlům. Texty nejdřív schválíš ty a teprve potom se kreslí.

## 6. Otevřené otázky pro majitele

1. Souhlasíš, aby karty za (?) měly 2–4 krátké řádky místo jedné věty? Hlavní UI se tím nemění.
2. Přejmenovat 3. hvězdu ze „Z paměti“ na „Opakování“ (nebo „Upevněno“) v celé aplikaci a opravit text „dvě opakování v Tréninku“ na „ve dvou různých dnech“?
3. Sjednotit hranici: nová lekce v Dnes „splněná“ od 80 %, ale 1. hvězda od 70 %. Má Dnes používat stejné pravidlo jako hvězda?
4. Tutoriál o 5 kartách, tedy přidat barvy úderů, tempo a „kam dál“ a vyřadit Z paměti a opakování do nápovědy. Vyhovuje ti to, nebo chceš zůstat u 4?
5. Má se nápověda otevírat přes seznam témat a z lekce rovnou na „Obrazovku lekce“, místo dnešních 8 karet za sebou?
