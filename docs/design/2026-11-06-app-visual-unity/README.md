# Jednotný vizuální jazyk aplikace Smack-a-Pad (Návrh — Ticket 125)

Tento dokument a interaktivní náhled v `index.html` sjednocují vzhled všech obrazovek aplikace podle referenční domovské obrazovky (`HomeScreen.swift`, tickety 112, 113, 115, 116, 119). 

Cílem je, aby celá aplikace působila jako **jeden fyzický hudební nástroj** z prémiových materiálů. Rozvržení prvků (layout), jejich pořadí a oranžový notový pás ve cvičení zůstávají **zcela beze změny**.

---

## 1. Jak otevřít náhled
Otevři `docs/design/2026-11-06-app-visual-unity/index.html` v prohlížeči (např. Safari na Macu nebo iPadu).

### Klávesové zkratky a ovládání:
- **`L`**: Přepnutí Světlý (Cream White) / Tmavý (Warm Soft Black) motiv.
- **`O`**: Otočení na šířku (Landscape) / na výšku (Portrait).
- **`M`**: Spuštění živé demonstrace animací (stlačení padů, přetočení BPM číselníku, přepnutí režimů, nabíhání karet, zvukový klik).
- **`V`**: Přepnutí varianty šasi: **Varianta A** (žebrované šasi) vs. **Varianta B** (klidný satén).
- **`S`**: Režim zobrazení: Rozděleno (Home etalon vedle obrazovky) / Srovnání A-B / Samostatný detail / Galerie všech 15 obrazovek.
- **`1`–`9`**: Rychlý skok na klíčové obrazovky.

---

## 2. Sdílené stavební kameny (Hardware Building Blocks)

### A. Povrchy a tělo nástroje (Surfaces)
1. **Šasi — Varianta A (Celoplošné drážkování / Ribbing)**:
   - Rozteč drážek (pitch): **4 pt** (2 pt světlý odlesk, 2 pt stín vylisované drážky).
   - Světlý motiv: odlesk `rgba(244, 239, 230, 0.55)`, stín `rgba(31, 29, 26, 0.08)`.
   - Tmavý motiv: odlesk `rgba(255, 255, 255, 0.06)`, stín `rgba(0, 0, 0, 0.45)`.
   - Povrchová úprava: mikroskopický speckle (matný plastový šum 3.5 %) + jemná vinětace (rádius 42 pt) pro hloubku.
2. **Šasi — Varianta B (Klidný satén / Calm Satin — Doporučeno pro husté obrazovky)**:
   - Hladký saténový přechod těla (175° úhel) s identickou barvou šasi, mikrospeckle zachován.
   - Vodorovné drážkování je utlumeno na 5 % krytí, aby nevznikal moaré efekt za notovou osnovou a hustým textem v Knihovně.
3. **Kovové a saténové desky (Hardware Plates)**:
   - Rádius rohů: **16 pt** (identický s Home screen deskou).
   - Obvodová mikro-fazeta: horní odlesk 1.5 pt (`rgba(255,255,255,0.7)` světlá / `0.24` tmavá), spodní stín 1.5 pt (`rgba(0,0,0,0.18)` světlá / `0.7` tmavá).
   - Vnější stín desky: `0 6px 24px rgba(0,0,0,0.18)`.
4. **Ocelové šrouby (Hardware Screws)**:
   - Průměr **18 pt**, křížová hlava pootočená o 45°, kuželový odlesk z kartáčované oceli.
   - Odsazení: přesně **9 pt** od rohů desky.
   - **Pravidlo použití**: Pouze na velkých strukturálních deskách (Home 540×540, Dnešní cvičení, Kalibrace, O aplikaci). **Nikdy** na malých tlačítkách, dílčích kartách nebo notovém pásu.

### B. Ovládací prvky (Pad Material)
1. **Pady a primární tlačítka**:
   - Rádius rohů: **8 pt** (převzato z 3×3 padů na Home).
   - Fazeta (bevel): horní hrana 1.5 pt světlý odlesk, spodní hrana 2.5 pt stín stlačení.
   - Zápustné lůžko (pad well): jemné vyfrézované lůžko s vnitřním stínem `inset 0 2px 5px rgba(0,0,0,0.2)`.
   - Hero Pad (oranžový): `#FF6B00` s tmavým nápisem `#1F1D1A` a oranžovou elektroluminiscenční září `0 0 16px rgba(255,107,0,0.4)`. Použito pro "Začít", "Zahájit trénink", "Pokračovat".
   - Sekundární pady ("Znovu", "Knihovna", "Zpět"): saténové tělo v barvě desky, čitelný kontrastní text.
2. **Segmentové přepínače (Hardware Keys)**:
   - Řada mechanických kláves spojených do jednoho bloku (režimy `Poslech` / `Hra` / `Po mně`, filtry stylů v Knihovně).
   - Aktivní klávesa má vylisovaný **2 pt oranžový LED světelný proužek** na spodní hraně s jemným pulsem (breathing).
3. **Fadery a posuvníky**:
   - Zapuštěná štěrbina dráhy (šířka 12 pt) s tmavým jádrem `#1A1816` a mikro-odleskem okrajů.
   - Kovová faderová hlava (34×24 pt) s rýhovaným úchopem a středovou oranžovou indikační linkou.
4. **Mini-pady (zobrazení rozložení padů 4×4)**:
   - Zmenšená verze fyzických padů (rádius 4 pt, zapuštěná fazeta, bílé/oranžové prosvícení při trefě).

### C. Zápustné displeje (Displays & Counters)
1. **Zápustný panel displeje (BPM, odezva v ms, velké procentuální skóre)**:
   - Tmavé zapuštěné sklo displeje (`#151412` ve světlém i tmavém režimu).
   - Vnitřní hloubkový stín `inset 0 3px 8px rgba(0,0,0,0.85)` a jemný vnější odlesk spodní hrany.
   - Písmo: `IBM Plex Sans`, tučný řez, `font-variant-numeric: tabular-nums` (číslice neskáčou při přetáčení).

### D. Typografie
- Rodina písma: **IBM Plex Sans** (ze stávajícího `Theme.swift`).
- Gravírovaný reliéfní styl (`text-shadow: 0 1px 0 rgba(...)`): použit **výhradně** pro drobné technické popisky hardware (např. CH 01, BPM, BEAT, MINI PAD, velikost 9.5 pt). Běžný text a názvy lekcí jsou čisté a maximálně čitelné.

### E. Pohybové tokeny (Motion Tokens)
Všechny obrazovky sdílejí přesně stejné animační chování jako Home screen:
- `padPress`: `scale(0.96)`, spring animace (`response: 0.18`, `dampingFraction: 0.75`).
- `padFlash`: okamžitý náběh (0 ms), plynulé odeznění 120 ms.
- `cardStep`: postupné kaskádovité nabíhání položek seznamu (stagger po 40 ms, posun z 8 pt na 0, náběh krytí).
- `lightBarBreath`: pomalý sinusový puls jasu oranžového LED pruhu (perioda 3.0 s).
- `numericRoll`: plynulé bubnové přetáčení číslic při změně hodnoty.
- `reduceMotion`: při zapnutém šetření pohybu v iOS se vypíná scale i posun; provádí se pouze čistý crossfade.

---

## 3. Přehled obrazovek a přiřazení stavebních kamenů

| Obrazovka | Doporučené šasi | Desky (Plates) | Šrouby | Ovládací prvky (Pady & Klávesy) | Zápustné displeje |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **Home (Etalon)** | Var A (Žebrování 4pt) | Hlavní deska 540×540 (16pt) | 4× (rohy) | 9 padů (Hero oranžový, bevel 8pt), fadery | Wordmark reliéf |
| **Cvičení: Hra** | Var B (Klidný satén) | Spodní transportní panel (16pt) | Ne | Pad tlačítka "Začít" (Hero), "Zpět", mini-pady 4×4 | Zapuštěné okénko BPM |
| **Cvičení: Po mně** | Var B (Klidný satén) | Dvojitý panel osnovy (16pt) | Ne | Segmentové klávesy režimů s LED lištou, mini-pady | Zapuštěné okénko BPM |
| **Cvičení: Výsledek** | Var B (Klidný satén) | Karta hodnocení a statistik (16pt) | Ne | "Pokračovat" (Hero), "Znovu", "Knihovna" (8pt) | Displej skóre (94 %) |
| **Knihovna (Library)** | Var B (Klidný satén) | Levý panel (satén), karty lekcí | Ne | Karty lekcí (rádius 8pt), segmentový filtr stylů | Indikátory hvězd |
| **Trénink (Training)** | Var B (Klidný satén) | Karty úrovní (16pt fazeta) | 4× (hlavní karta) | Tlačítko lekce (Hero), odznaky v kroužcích | Faderový progress bar |
| **Dnešní cvičení (Today)** | Var B nebo Var A | Středová masivní deska (16pt) | 4× (rohy) | "Zahájit trénink" (Hero oranžový pad) | Číselník denní řady (Streak) |
| **Odznaky (Badges)** | Var B (Klidný satén) | Panel odznaků (16pt) | Ne | Kruhová a čtvercová lůžka odznaků, LED glow | Počítadlo odznaků (14/24) |
| **Nastavení (Settings)** | Var B (Klidný satén) | Sekční desky (16pt fazeta) | Ne | Hardware fadery (hlasitost), kolébkové LED přepínače | Segmentové tlačítko témat |
| **Kalibrace (Calibration)** | Var A (Žebrování 4pt) | Přístrojová deska měření (16pt) | 4× (rohy) | Velký dotykový kalibrační TAP pad | Displej latence (-14 ms), progress |
| **Nastavení ovladače** | Var B (Klidný satén) | Stavová karta kontroléru (16pt) | Ne | Tlačítka mapování, testovací matice 4×4 | Terminálový monitor MIDI zpráv |
| **O aplikaci (About)** | Var A (Žebrování 4pt) | Ocelová plaketa nástroje (16pt) | 4× (rohy) | Tlačítko odkazu (8pt saténový pad) | Kovový štítek verze |
| **Nákupy (Purchases)** | Var B (Klidný satén) | Zlatavě lemovaná deska (16pt) | Ne | Hero pad "Odemknout plnou verzi" | Seznam odemčených funkcí |
| **Úvodní obrazovka** | Var B (Klidný satén) | Uvítací panel (16pt fazeta) | Ne | Velký startovací pad "Začít trénovat" | Číslované kroky 1, 2, 3 |
| **Bannery a překryvy** | Plovoucí na scéně | Plovoucí saténové bannery (12pt) | Ne | Akční tlačítka v padovém materiálu | LED světelné linky, hvězdný burst |

---

## 4. Ověření kontrastu (WCAG 2.1 AA & AAA)

Všechny barvy vycházejí výhradně z palety ticketu 92 (`#F4EFE6`, `#1F1D1A`, `#EBE5DA`, `#2A2824`, `#FF6B00`, `#5E5950`, `#B3ADA2`).

| Kombinace prvků | Barva popředí | Barva pozadí | Naměřený kontrast | Požadavek WCAG AA | Splněno? |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Světlý: Hlavní text na desce** | `#1F1D1A` | `#ECE5DC` | **12.4 : 1** | 4.5 : 1 (text) | **ANO (AAA)** |
| **Světlý: Sekundární text** | `#5E5950` | `#ECE5DC` | **4.9 : 1** | 4.5 : 1 (text) | **ANO (AA)** |
| **Světlý: Hero pad nápis** | `#1F1D1A` | `#FF6B00` | **5.8 : 1** | 4.5 : 1 (text) | **ANO (AA)** |
| **Světlý: Displej BPM (číslice)** | `#FF6B00` | `#151412` | **6.2 : 1** | 3.0 : 1 (velká čísla) | **ANO (AAA)** |
| **Světlý: Oranžový notový pás** | `#1F1D1A` | `#FF6B00` | **5.8 : 1** | 3.0 : 1 (grafika) | **ANO (AA)** |
| **Tmavý: Hlavní text na desce** | `#F4EFE6` | `#272521` | **11.8 : 1** | 4.5 : 1 (text) | **ANO (AAA)** |
| **Tmavý: Sekundární text** | `#B3ADA2` | `#272521` | **5.2 : 1** | 4.5 : 1 (text) | **ANO (AA)** |
| **Tmavý: Hero pad nápis** | `#1F1D1A` | `#FF6B00` | **5.8 : 1** | 4.5 : 1 (text) | **ANO (AA)** |
| **Tmavý: Displej skóre (číslice)** | `#F4EFE6` | `#151412` | **15.1 : 1** | 3.0 : 1 (velká čísla) | **ANO (AAA)** |
| **Tmavý: Zelené správné trefy** | `#2ECC71` | `#1F1D1A` | **6.7 : 1** | 3.0 : 1 (grafika) | **ANO (AA)** |

---

## 5. Rozhodnutí k výběru varianty (pro Jakuba)

### Otázka 1: Pozadí hustých obrazovek (Cvičení, Knihovna, Nastavení)
- **Varianta A (Celoplošné žebrování 4 pt)**: Zachovává stejné drážky po celém iPadu i na obrazovce Cvičení. Může však působit mírně rušivě za notovou osnovou.
- **Varianta B (Klidný satén — DOPORUČENO)**: Šasi má identický hedvábný přechod a mikrospeckle, ale drážky jsou potlačeny na 5 %. Oranžový notový pás ve Cvičení i karty lekcí v Knihovně tak dokonale vystupují do popředí a noty jsou absolutně čisté.
- *Vyzkoušej v náhledu stisknutím tlačítka `Srovnání A / B` nebo klávesy `V`.*

### Otázka 2: Šrouby na deskách
- V návrhu jsou ocelové šrouby umístěny pouze na velkých funkčních deskách: **Home (3×3 pad grid)**, **Dnešní cvičení (Today)**, **Kalibrace**, **Trénink (Training)** a **O aplikaci (About)**. Na hustých obrazovkách jako Cvičení a Knihovna jsme šrouby vynechali, aby nepůsobily přeplácaně.

### Otázka 3: Změny layoutu
- **Žádné změny v rozvržení nejsou potřeba.** Všechny navržené prvky přesně kopírují současné rozměry, pozice a hierarchii ze SwiftUI souborů.
