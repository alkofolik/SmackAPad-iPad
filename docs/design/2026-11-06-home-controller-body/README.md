# Tělo kontroleru (Home background v2) — Návrh a opravený HTML náhled

Zdroj: Jakubovo zadání po revizi screenshotů (Ticket 118, 2026-11-06):
> *1. Textury jsou naopak: tělo má být žebrované (drážkovaný plast) a deska pod pady hladká.*
> *2. Nic není vycentrované; deska je menší než mřížka padů a šrouby jsou schované pod pady; titulek zasahuje do desky.*
> *3. Režim na výšku přetéká přes viewport a řeže se; fadery leží pod pady.*
> *4. Žádná trojtečka „…“ na padech; číslo „01“ na oranžovém padu musí mít vyšší kontrast.*
> *5. Přidat přepínač vodítek (show guides) a zapsat přesná čísla layoutu pro SwiftUI.*

---

## 1. Co se změnilo oproti v1 (Ticket 117 → 118)

1. **Prohození textur (tělo žebrované, deska hladká)**:
   - **Tělo kontroleru**: Nyní nese jemné plastové drážkování (jemné rovnoběžné žebrování s roztečí 4 pt, se světelnou hranou shora a stínem drážky zdola), napodobující lisované šasi studiových mašin. Na pozadí zůstává velmi lehký matný speckle.
   - **Přepínač „Žebrování těla“**: Přepíná stavy `Jemné` (výchozí) → `Výrazné` → `Vypnuto`.
   - **Deska pod pady**: Je nyní **hladká**. Saténová varianta je dokonale čistá hedvábná plocha s jemným světelným přechodem. Varianta broušeného kovu má pouze mikroskopické vlasové linky o tloušťce 1 pt, nikoliv hrubé žebrování.
2. **Jeden matematicky vycentrovaný layout**:
   - Deska pod pady i mřížka padů sdílejí **stejný střed (50 % X, 50 % Y)** jako samotné šasi.
   - **Deska je větší než mřížka padů**: Má rovnoměrný padding **36 pt na všech 4 stranách**. Pady nikdy nepřesahují desku.
   - **4 rohové kovové šrouby** (průměr 18 pt) sedí s rezervou 9 pt od vnější hrany desky a 9 pt od padů. Žádný pad je nezakrývá ani se jich nedotýká.
   - **Titulek SMACK-A-PAD** sedí ve vlastním vyhrazeném horním pruhu nad deskou s velkorysou vůlí na všechny strany.
3. **Plná funkčnost na výšku (Portrait) i na šířku (Landscape)**:
   - Náhled obsahuje responzivní auto-scaler, který celý kontroler proporcionálně přizpůsobí jakémukoliv oknu prohlížeče. **Nic nepřetéká, stránka neroluje, nic se neřeže.**
   - Lze přímo přepínat mezi rozměry **iPad Pro 11″** (1194×834 / 834×1194), **iPad mini 6** (1133×744 / 744×1133) i **iPad 10.9″** (1180×820 / 820×1180).
4. **Symetrické a zrcadlené fadery**:
   - **Na šířku**: 2 fadery vlevo (CH 01, 02) a 2 fadery vpravo (CH 03, 04) jsou **zrcadlené** (vlevo stupnice vně, vpravo stupnice vně) a vertikálně vycentrované přesně na středovou osu desky (Y = 50 %).
   - **Na výšku**: Všechny 4 fadery tvoří jeden vodorovný řádek pod deskou, vycentrovaný horizontálně (X = 50 %) i vertikálně ve spodním pruhu.
5. **Texty a kontrast padů (Ticket 116)**:
   - Odstraněna trojtečka „…“ u podtitulku hero padu (`2 cvičení · pak nová lekce` se přirozeně zalamuje na 2 řádky).
   - Číslo padu `01` na oranžovém padu má plné krytí a barvu `#1F1D1A` s kontrastem **5,89 : 1** (bezpečně splňuje WCAG AA).
6. **Přepínač „Vodítka“ (Show guides)**:
   - Klávesa `G` nebo tlačítko v liště vykreslí středové osy X/Y (azurová), ohraničení desky a 36pt padding (purpurová), kříže středů šroubů, ohraničení mřížky padů (zelená) a vyhrazené zóny pro titulek a fadery (žlutá).

---

## 2. Přesná čísla layoutu pro SwiftUI implementaci

Všechna čísla jsou uvedena v logických bodech (pt), které 1:1 odpovídají souřadnicovému systému ve SwiftUI:

### A. Rozměry desky a mřížky padů (společné pro všechny orientace)
- **Buňka padu**: `146 × 146 pt`, vnitřní poloměr zaoblení padu `8 pt`, lůžko padu `10 pt`.
- **Mezera mezi pady**: `15 pt`.
- **Mřížka 3×3 padů**: `468 × 468 pt` ($3 \times 146 + 2 \times 15 = 468$).
- **Padding desky kolem mřížky**: rovnoměrně **`36 pt`** ze všech 4 stran (nahoře, dole, vlevo, vpravo).
- **Celkový rozměr desky (Plate)**: **`540 × 540 pt`** ($468 + 2 \times 36 = 540$).
- **Poloměr rohů desky**: `16 pt`.
- **Rohové šrouby**: průměr `18 pt`. Střed šroubu je umístěn `18 pt` od okrajů desky:
  - Odstup vnější hrany šroubu k hraně desky: `9 pt`.
  - Odstup vnitřní hrany šroubu k okraji mřížky padů: `9 pt`.
  - Šrouby jsou natočeny pod úhly: TL: –24°, TR: +51°, BL: +108°, BR: –63°.
- **Umístění desky v těle**: Přesně na střed: `X = 50 %`, `Y = 50 %`.

---

### B. Rozvržení na šířku — iPad Pro 11″ (1194 × 834 pt)
- **Šasi**: šířka `1194 pt`, výška `834 pt`.
- **Deska (540×540 pt)**:
  - Horní hrana: `y = 147 pt`, spodní hrana: `y = 687 pt`.
  - Levá hrana: `x = 327 pt`, pravá hrana: `x = 867 pt`.
  - Střed: `x = 597 pt` (50 %), `y = 417 pt` (50 %).
- **Pruh pro titulek (nahoře)**:
  - Zóna: od `y = 0` do `y = 147 pt` (výška `147 pt`).
  - Wordmark: šířka `292 pt`, výška `44 pt`.
  - Vycentrován: `x = 597 pt`, `y = 73,5 pt`.
  - Vertikální odstup k horní hraně šasi: `51,5 pt`.
  - Vertikální odstup ke spodní hraně pruhu (k desce): `51,5 pt` (nedotýká se desky!).
- **Fadery po stranách (zrcadlené)**:
  - Levá volná zóna: šířka `327 pt`. Pravá volná zóna: šířka `327 pt`.
  - Šířka dvojice faderů: `134 pt` (2 kanály po 56 pt + mezera 22 pt).
  - Horizontální odstup vlevo i vpravo: $(327 - 134) / 2 =$ **`96,5 pt`** k okraji šasi i k hraně desky.
  - Vertikální střed faderů: `y = 417 pt` (přesně na středové ose desky Y = 50 %).
  - Výška drážky: `200 pt`.
  - Uspořádání: CH 01 a 02 vlevo `[Stupnice | Drážka]`; CH 03 a 04 vpravo `[Drážka | Stupnice]` (zrcadleno).

---

### C. Rozvržení na výšku — iPad Pro 11″ (834 × 1194 pt)
- **Šasi**: šířka `834 pt`, výška `1194 pt`.
- **Deska (540×540 pt)**:
  - Levá hrana: `x = 147 pt`, pravá hrana: `x = 687 pt`.
  - Horní hrana: `y = 327 pt`, spodní hrana: `y = 867 pt`.
  - Střed: `x = 417 pt` (50 %), `y = 597 pt` (50 %).
- **Pruh pro titulek (nahoře)**:
  - Zóna: od `y = 0` do `y = 327 pt` (výška `327 pt`).
  - Wordmark: šířka `332 pt`, výška `50 pt`.
  - Vycentrován: `x = 417 pt`, `y = 163,5 pt`.
  - Vertikální odstup k horní hraně šasi i k desce: **`138,5 pt`**.
- **Fadery pod deskou (v jedné řadě)**:
  - Spodní volná zóna: od `y = 867 pt` do `y = 1194 pt` (výška `327 pt`).
  - Celková výška fader kanálu: `142 pt` (dráha 125 pt, popisek 9 pt, mezera 8 pt).
  - Vertikální odstup ke spodní hraně desky: $(327 - 142) / 2 =$ **`92,5 pt`**.
  - Vertikální odstup ke spodní hraně těla kontroleru: **`92,5 pt`**.
  - Šířka sestavy 4 faderů: `316 pt` ($4 \times 52 + 3 \times 36 = 316$).
  - Horizontální vycentrování: `x = 417 pt` (50 %). Boční odstup k okrajům: **`259 pt`**.

---

### D. Rozvržení pro iPad mini 6 (1133 × 744 pt landscape / 744 × 1133 pt portrait)
- **Na šířku (1133 × 744 pt)**:
  - Horní pruh pro titulek: výška `102 pt`, wordmark výška `36 pt` (svislá vůle `33 pt` k okraji i k desce).
  - Boční zóny pro fadery: šířka `296,5 pt`, fader sestava `134 pt`, boční vůle `81 pt`.
- **Na výšku (744 × 1133 pt)**:
  - Horní pruh pro titulek: výška `296,5 pt`, vůle `124 pt`.
  - Spodní zóna pro fadery: výška `296,5 pt`, svislá vůle `77 pt` k desce i k okraji šasi. Boční vůle `214 pt`.

---

## 3. Recept na stavbu ve SwiftUI a náročnost (Asset sizes)

| Vrstva | Způsob implementace ve SwiftUI | Assety & Velikost | Výpočetní náročnost |
|---|---|---|---|
| **1. Plastové tělo + vinětace** | Základní `LinearGradient` a `RadialGradient` z barev v `Theme.swift`. | 0 KB (čistý kód) | Zanedbatelná (statické) |
| **2. Žebrování těla (moulded ribbing)** | Opakovaný přechod `repeating-linear-gradient` vykreslený jednorázově do `Canvas` nebo 1 malá PNG textura 4×4 pt (`Image(..., resizingMode: .tile)`). | **1 PNG dlaždice cca 1 KB** (nebo 0 KB přes Canvas) | 0 % CPU/GPU per frame (statická vrstva) |
| **3. Matný speckle plastu** | Jedna malá bezešvá dlaždice šumu 128×128 px dlaždicovaná přes `Image(..., resizingMode: .tile)`. | **1 PNG dlaždice cca 10–12 KB** | 0 % CPU/GPU per frame |
| **4. Centrální deska (hladká)** | `RoundedRectangle(cornerRadius: 16)` s výplní `LinearGradient`, okrajem `strokeBorder` a statickým stínem `.shadow()`. Pro broušený kov jemný 1pt pattern. | 0 KB (satén) až 4 KB (kov) | 0 % CPU/GPU per frame |
| **5. Kovové šrouby (4 ks)** | Vektorový asset (SF Symbol nebo `Path`) vykreslený 4× v rozích s daným `.rotationEffect`. | **1 vektorový asset cca 1 KB** | Statické |
| **6. Fadery a stupnice** | Statické SwiftUI tvary: `Capsule` (drážka), `Rectangle` (jezdec), `VStack` s textem popisek a dílků stupnice. | 0 KB (čisté SwiftUI tvary) | Statické |
| **Celkem za všechny vrstvy** | — | **cca 11–18 KB celkem** | Žádné per-frame animace pozadí, plně statické. |

---

## 4. Ověření kontrastu textů (WCAG AA & AAA)

- **Světlý režim (Light / Cream)**:
  - Běžný titulek padu (`#1F1D1A` na ploše `#EBE5DA`): **13,41 : 1** (norma AAA).
  - Běžný podtitulek padu (`#5E5950` na ploše `#EBE5DA`): **5,55 : 1** (norma AA).
  - Titulek oranžového padu Pokračovat (`#1F1D1A` na `#FF6B00`): **5,89 : 1** (norma AA).
  - Podtitulek oranžového padu Pokračovat (`#1F1D1A` na `#FF6B00`): **5,89 : 1** (norma AA).
  - Číslo padu `01` na oranžovém padu (`#1F1D1A` na `#FF6B00`): **5,89 : 1** (norma AA).
  - Titulek SMACK-A-PAD na žebrovaném těle (`#1F1D1A` na `#F4EFE6`): **13,41 : 1** (norma AAA).
- **Tmavý režim (Dark / Soft Black)**:
  - Běžný titulek padu (`#F4EFE6` na ploše `#2A2824`): **12,85 : 1** (norma AAA).
  - Běžný podtitulek padu (`#B3ADA2` na ploše `#2A2824`): **6,60 : 1** (norma AA).
  - Titulek oranžového padu Pokračovat (`#1F1D1A` na `#FF6B00`): **5,89 : 1** (norma AA).
  - Číslo padu `01` na oranžovém padu (`#1F1D1A` na `#FF6B00`): **5,89 : 1** (norma AA).
  - Titulek SMACK-A-PAD na žebrovaném těle (`#F4EFE6` na `#1F1D1A`): **12,85 : 1** (norma AAA).

---

## 5. Jak náhled vyzkoušet

Otevři soubor `docs/design/2026-11-06-home-controller-body/index.html` v libovolném prohlížeči (Safari, Chrome) na Macu nebo na iPadu:
- Klávesa **`G`**: Zapne / vypne **Vodítka** (zobrazí středové osy, padding desky a kříže šroubů).
- Klávesa **`O`**: Přepne **Orientaci** (Na šířku / Na výšku).
- Klávesa **`L`**: Přepne **Vzhled** (Světlý / Tmavý).
- Klávesa **`T`**: Přepne **Žebrování těla** (Jemné / Výrazné / Vypnuto).
- Klávesa **`P`**: Přepne **Materiál desky** (Satén / Broušený kov).
- Klávesa **`F`**: Zapne / vypne **Fadery**.
- Klávesa **`B`**: Zapne / vypne **Pozadí** (srovnání s holou plochou).
- Tlačítko **Zařízení** v horní liště: Přepíná velikosti mezi **iPad 11″**, **iPad mini** a **iPad 10.9″**.
- Klávesy **`1`–`8`**: Simulují úder z fyzického MIDI kontroleru (hmatový stisk padu do lůžka, blesk a odskočení).
