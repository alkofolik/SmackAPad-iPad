# 131 — Návrh: Jednotný systém tlačítek pro celou aplikaci (Button System Proposal)

Tento dokument a doprovodný interaktivní offline náhled v `docs/design/2026-11-07-button-system/index.html` představují ucelený systém tlačítek pro Smack-a-Pad. 

Cílem návrhu je vyřešit vizuální nesourodost a vychýlení tlačítek po zavedení saténového skinu v ticketech 126–129 a navrhnout **dvě čisté, hapticky věrné varianty** (A a B), které respektují tělo nástroje ("Klidný satén" & Home MPC controller) a striktní pravidla minimální dotykové plochy bez jakýchkoliv změn v rozvržení obrazovek (layoutu).

---

## 1. Jak otevřít interaktivní náhled

Otevřete soubor v Safari nebo jiném prohlížeči (funguje zcela offline):
```bash
open docs/design/2026-11-07-button-system/index.html
```

### Klávesové zkratky a ovládání:
- **`L`**: Přepnutí Světlý (Cream White) / Tmavý (Warm Soft Black) motiv.
- **`V`**: Přepnutí varianty tlačítek: **Varianta A** (Haptický hardware) vs. **Varianta B** (Akustický minimalismus).
- **`M`**: Zapnutí / vypnutí šetření pohybu (Reduce Motion).
- **Zvukový klik**: Každé stisknutí tlačítka generuje autentický tichý mechanický zvuk (Web Audio API syntetizér).

---

## 2. Inventář stávajícího stavu tlačítek (Inventory Table)

Při read-only auditu všech souborů v `SmackAPad/Sources/UI/` bylo identifikováno 9 odlišných funkčních typů tlačítek. Níže uvedená tabulka dokumentuje jejich současný stav, velikost, problémy a referenční snímky pořízené na simulátoru iPad Pro 11″ (M5).

| Typ tlačítka | Obrazovky | Současný styl v kódu | Současná velikost | Co působí špatně / rozbitě | Referenční snímek |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Toolbar tlačítko (Home/Zpět)** | Knihovna, Trénink, Dnešní cvičení, Cvičení | `PadSecondaryButtonStyle` | `minHeight: 48pt`, padding v labelu | Působí jako plovoucí gumová kostka s těžkým stínem; v navigační liště vizuálně soutěží s nadpisem obrazovky; nízký kontrast vůči šasi. | [Snímek](screenshots/library_landscape_light.png) |
| **2. Primární akce (Hero Pad)** | Knihovna ("Hrát další"), Cvičení ("Start"), Trénink ("Zahájit"), Nákupy | `PadPrimaryButtonStyle` | Oranžový podklad `#FF6B00`, černý text | Masivní 1.5pt horní bílá a 2.5pt spodní černá fazeta působí jako vytažená pryž; bílý 38% flash při stisku vypadá jako blesk fotoaparátu; rozostřená oranžová záře. | [Snímek](screenshots/practice_landscape_light.png) |
| **3. Sekundární akce** | Cvičení ("Znovu", "Od začátku"), Trénink ("Dnes ne"), Nákupy ("Obnovit") | `PadSecondaryButtonStyle` | `surface` `#EBE5DA` / `#2A2824` | Ve světlém režimu barva povrchu splývá se saténovou deskou; v dialozích a formulářích mají tlačítka nekonzistentní poměry stran. | [Snímek](screenshots/today_portrait_light.png) |
| **4. Ikona tlačítka (Icon Button)** | Knihovna (Ozubené kolo), Cvičení (Nástroj, Rozložení padů), Nákupy (Zavřít) | `PadIconButtonStyle` | Pevný čtverec 48×48 pt | Ikona uvnitř 48pt těžkého padu s fazetami působí humpolácky; oranžová LED lišta ve vybraném stavu nehezky ořezává spodní rádius. | [Snímek](screenshots/library_portrait_light.png) |
| **5. Přepínač režimů (Segmented)** | Cvičení (Poslech / Hra / Po mně), Nastavení, MIDI Learn | `HardwareKeyButtonStyle` / `PlexSegmentedPicker` | Segmenty spojené či dělené | V Cvičení plavou jednotlivá tlačítka s mezerami namísto souvislé klávesnice; v Nastavení se používá systémový `UISegmentedControl`, který neladí se saténem. | [Snímek](screenshots/practice_portrait_light.png) |
| **6. Filtrační štítky (Filter Chips)** | Knihovna (Vše, Základ, Funk, Rock...) | `HardwareKeyButtonStyle(isSelected:)` | Horizontální řada štítků | Používaly `HardwareKeyButtonStyle`, takže aktivní filtr měl vylisovanou LED lištu na spodku! Čip je filtrační štítek, nikoliv mechanická transportní klávesa. | [Snímek](screenshots/library_landscape_light.png) |
| **7. Řádek lekce v seznamu** | Knihovna (`LibraryLessonRow` / `ListRow`) | `ListRow` + `.satinPlate()` | Výška &ge; 68 pt | Každý řádek má dvě vrstvy stínů a mikrofazet; v rolovacím seznamu vzniká obrovský vizuální šum a compete o pozornost s tlačítky. | [Snímek](screenshots/library_landscape_dark.png) |
| **8. Destruktivní akce** | Nastavení ovladače ("Smazat profil"), potvrzovací dialog | `Button(role: .destructive)` | Běžný text / červená ikona | Chybí dedikovaný hardware styl; výchozí systémová červená bije do očí a neladí s teplou paletou soft black & cream. | [Snímek](screenshots/controller_landscape_light.png) |
| **9. Vypnuté tlačítko (Disabled)** | Odemknout nákupy, Uložit před dokončením učení | Pouze `opacity: 0.45` | Poloprůhledný podklad | 45% průhledná oranžová barva vypadá jako vybledlá broskev; reálný hardware má vypnuté podsvícení, ne průhledný plast, kterým prosvítá podklad. | [Snímek](screenshots/purchases_landscape_light.png) |

---

## 3. Představení dvou variant systému (Variant A & B)

Obě varianty striktně vycházejí z palety ticketu 92 a saténových tokenů ticketu 126. Oranžová `#FF6B00` zůstává jedinou primární barvou.

### Varianta A: "Haptický hardware" (Akai MPC Tactile)
- **Charakter:** Přímé rozšíření domovské obrazovky. Tlačítka působí jako precision-molded silikonové klávesy usazené ve vyfrézovaných lůžkách na těle přístroje.
- **Rádius rohů:** **8 pt** jednotně pro všechny běžné ovládací prvky (odvozeno z 3×3 bicích padů na Home).
- **Hloubka:** Jemné vyfrézované lůžko se stínem `0 2px 4px rgba(0,0,0,0.12)`, horní odlesk fazety 1.5 pt a spodní stín stlačení 2.0 pt (2.5 pt u Hero padu).
- **Hero Pad:** Zářivý oranžový satén `#FF6B00` s tmavým nápisem `#1F1D1A` a teplou oranžovou elektroluminiscenční září `0 0 16px rgba(255,107,0,0.35)`.
- **Segmentové klávesy:** Jednolitý blok kláves usazený v zapuštěné drážce. Aktivní klávesa má vylisovanou **2 pt oranžovou LED lištu** na spodní hraně s pomalým dýcháním (3.0 s perioda).
- **Filtrační čipy:** Tvar zaoblené kapsle (8 pt), vybraný čip má oranžový rámeček a sytý text (bez LED lišty).
- **Odezva při stlačení:** Fyzické stlačení `scale(0.965)`, posun dolů o 1.5 pt a rychlý bílý záblesk podsvícení (120 ms).

### Varianta B: "Akustický minimalismus" (Studio Console / Braun Precision)
- **Charakter:** Styl špičkových studiových pultů a přístrojů Dietera Ramse (Braun). Eliminuje masivní plastické fazety ve prospěch precizních 1 px obvodových linek a plochého saténu.
- **Rádius rohů:** **6 pt** pro všechna funkční tlačítka v aplikaci. Vytváří jasnou hierarchii: 8 pt rádius patří velkým hracím padům na Home screenu, zatímco 6 pt patří precizním ovládacím prvkům.
- **Hloubka:** Žádné tlusté fazety; pouze ostrá 1 px obvodová linka `Theme.hairline` a spodní mechanická hrana `0 1.5px 0 rgba(0,0,0,0.22)`, která dává pocit fyzického mikrospínače.
- **Hero Pad:** Čistý oranžový satén s lehkým ambientním stínem `0 2px 8px rgba(255,107,0,0.25)`.
- **Toolbar tlačítka:** Vzdušná tlačítka s 1 px linkou, která v klidovém stavu neruší název obrazovky.
- **Filtrační čipy:** Plochý štítek (6 pt), aktivní stav má plné tělo v barvě inkoustu s 6 pt oranžovým indikačním bodem.
- **Odezva při stlačení:** Mikroskopický zdvih dolů o 1.0 pt a `scale(0.985)`, okamžité ztmavení oranžové na sytý odstín `#E55A00` bez rušivého bílého blesku.

---

## 4. Pravidla systému tlačítek (Rules)

Následující pravidla jsou závazná pro budoucí implementační ticket:

1. **Minimální dotyková plocha (Min Touch Size &ge; 44 pt):** Všechna tlačítka v aplikaci musí garantovat dotykovou plochu minimálně **48 × 48 pt** (respektive 44 pt u kompaktních toolbar prvků).
2. **Padding uvnitř padu:** Vnitřní odsazení (`padding`) musí být vždy uvnitř label closure tlačítka, aby viditelný pad přesně odpovídal ploše reagující na dotyk.
3. **Jeden rádius rohů:** Buď striktně 8 pt (Varianta A), nebo 6 pt pro ovládací prvky (Varianta B). Žádné náhodné poloměry 4, 10 nebo 14 pt na tlačítkách.
4. **Světelná LED lišta:** Vyhrazena **pouze pro přepínač režimů** (Poslech/Hra/Po mně) a notový pás. Nikdy na filtrech ani ikonách.
5. **Chování při Reduce Motion:** Při zapnutém šetření pohybu v iOS se vypíná jakýkoliv `scale` i `offset`. Tlačítko reaguje výhradně 12% ztmavením povrchu. LED lišta svítí stabilně bez dýchání.
6. **Toolbar tlačítko vs. tlačítko v ploše:** Toolbar tlačítka musí být opticky lehčí (výška 44 pt, jemná linka), aby nepotlačovala titulek stránky.
7. **Řádek lekce vs. tlačítko:** Řádek lekce je strukturální karta/deska se seznamem informací, nikoliv mačkací pryžový pad. Akční prvky uvnitř řádku (hvězdičky, zámek) mají vlastní oddělenou dotykovou geometrii.
8. **Žádná změna layoutu:** Pozice, šířky, pořadí a rozvržení obrazovek zůstávají zachovány.

---

## 5. Otevřené otázky pro Jakuba (max 3)

1. **Volba charakteru: Varianta A (Haptický hardware / MPC) nebo Varianta B (Akustický minimalismus / Braun)?**
   - *Varianta A* přináší plný pocit gumových padů z Home screenu i do zbytku aplikace s výraznými fazetami a 8 pt rádiusem.
   - *Varianta B* působí dospěleji, čistěji a lehčeji díky 6 pt rádiusu a precizním 1 px linkám bez těžkých stínů.
2. **Podoba Toolbar tlačítek (Domů / Zpět):**
   - Vyhovuje vám, aby tlačítko "Domů" v liště bylo decentní nízkoprofilové tlačítko s jemnou linkou, nebo má mít plné tělo saténového padu jako na domovské obrazovce?
3. **Odezva při stisku (Press Feedback):**
   - Preferujete haptický bílý záblesk podsvícení padu (Varianta A — MPC styl), nebo čisté mechanické ztmavení barvy bez záblesku (Varianta B — studiový mikrospínač)?
