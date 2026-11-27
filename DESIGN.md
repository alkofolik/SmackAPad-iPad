# SmackAPad-iPad — Hardware UI Design System (`DESIGN.md`)

Tato specifikace je závazná pro všechny obrazovky v `SmackAPad/Sources/UI/`. Cílem je jednotný, dospělý a hmatatelný styl studiového hardwaru bez nativního iOS chromu a bez rušivého blikání během hraní.

## 1. Zásady a zákazy
- **Žádný nativní iOS `Form` / `.insetGrouped`:** Nastavení, Ovladač, Kalibrace i Fronta opakování se skládají z `HardwareCard` a `HardwareRow` v `ScrollView`.
- **Žádné nativní iOS kapsle a ovládače:** Nikde nepoužívat systémový `Toggle`, systémový `Slider` ani zakulacený `SegmentedPicker`. Vždy použít komponenty z `UI/Shared/`.
- **Jeden tvar pro ovládací prvky:** Všechna tlačítka, ikony, filtry i zpětné šipky mají jednotný poloměr `6pt` a `1pt` hardwarovou linku.
- **Lokalizace všude:** Žádné natvrdo zapsané anglické štítky v navigaci (`PATH | STUDIO RIG | LIBRARY` se lokalizují podle `SettingsManager`).
- **Oba režimy (Tmavý i Světlý):** Každá barva musí jít přes sémantické tokeny v `Theme.swift` (nikdy natvrdo `.black` / `.white` kromě vědomého kontrastu na oranžovém CTA).

## 2. Barevné tokeny (`Theme.swift`)

| Token | Tmavý režim (Matte Black Studio) | Světlý režim (Brushed Silver Studio) | Použití |
|---|---|---|---|
| `chassis` | `#0C0C0E` | `#E6E6E2` | Hlavní pozadí obrazovek a šasi |
| `surface` | `#141417` | `#F4F4F0` | Karty, panely, sidebar, řádky |
| `surfaceElevated` | `#1B1B1F` | `#FFFFFF` | Aktivní/vyvýšené tlačítko, hlavička karty |
| `recessed` | `#09090B` | `#DADAD4` | Zapuštěný OLED displej, drážka faderu, segment track |
| `hairline` | `#26262B` | `#C8C8C0` | `1pt` ohraničení panelů, tlačítek a oddělovače |
| `ink` | `#F4F4F2` | `#141417` | Primární text a ikony |
| `secondary` | `#8E8E93` | `#5C5C62` | Sekundární text, metadata, neaktivní štítky |
| `accent` | `#FF6B00` → `#E04E00` | `#F25C00` → `#D44500` | Podsvícený stav, primární CTA, LED indikátor, aktivní prvek |
| `accentGlow` | `#FF6B00` (opacity 0.28) | `#F25C00` (opacity 0.16) | Jemný podsvit u aktivních padů, LED a získaných odznaků |
| `ledOff` | `#232328` | `#CBCBC4` | Zhasnutý segment LED / neaktivní krok patternu |

## 3. Geometrie, typografie a hierarchie
- **Poloměry (`Theme.Radius`):**
  - `control = 6pt` (tlačítka, `BackButton`, filtry, ikonová tlačítka, segmenty)
  - `panel = 10pt` (karty, panely nastavení, řádkové skupiny, náhledy)
  - `sheet = 12pt` (modální okna, popovery, šasi bloky)
- **Ohraničení:** Standardně `1pt` `Theme.hairline`. Aktivní/vybraný prvek `1.5pt` `Theme.accent`.
- **Typografie:**
  - Nadpisy obrazovek: výrazný display/bold (`Theme.screenTitle`), zarovnané do jednotné horní lišty.
  - Čísla (BPM, dB, hvězdy, počty lekcí, milisekundový offset): vždy `.monospacedDigit()`.
  - Hardwarové štítky (pod přepínači, nad sekcemi): uppercase, tracking `+0.8`, `11–12pt` semibold `Theme.secondary`.
- **Horní navigační lišta (`ScreenTopBar`):**
  - Vlevo: `HardwareBackButton` (`40×40`, `6pt` radius, `1pt` linka) + případné sekundární `40×40` tlačítko (např. toggle sidebaru).
  - Uprostřed: `PlexSegmentedPicker` (pokud je to hlavní obrazovka) nebo titulek.
  - Vpravo: globální `Nastavení` vždy pevně v pravém rohu — nikdy vpravo od něj nedávat lokální filtry (jako ikonu oka v Intro).

## 4. Sdílené komponenty (`SmackAPad/Sources/UI/Shared/`)
1. **`HardwareBackButton` & `HardwareIconButton` (`ScreenChrome.swift`):** `40×40` (nebo `36×36` kompaktní), `6pt` radius, povrch `surfaceElevated`, `1pt` `hairline`. Nahrazuje všechny kulaté/squircle šedé šipky `<`, `?` i kulatý toggle sidebaru.
2. **`PlexSegmentedPicker` (`PlexSegmentedPicker.swift`):** Jediný přepínač v celé aplikaci. Dvě velikosti: `.regular` (hlavní navigace `Cesta | Studio Rig | Knihovna`) a `.compact` (lokální filtry: `Cesta | Žánry | Techniky`, `Vše | Trénink`).
3. **`HardwareCard` & `HardwareRow` (`HardwareSurfaces.swift`):** Kontejner `10pt` radius, `surface`, `1pt` `hairline`. Oddělovače `1pt` `hairline` jen mezi interaktivními řádky (vysvětlující text patří mimo řádek jako čistý popisek pod/nad skupinou).
4. **`HardwareSlider` & `HardwareToggle` (`HardwareControls.swift`):**
   - `HardwareSlider`: horizontální studiový fader (zapuštěná drážka `recessed`, aktivní oranžová stopa, tmavý/kovový hmatník se středovou ryskou, hodnota vpravo v `.monospacedDigit()`).
   - `HardwareToggle`: `6pt` hardwarové tlačítko se svítící/zhasnutou oranžovou LED tečkou.
5. **`LessonRow` (`LessonRow.swift`):** Jedna společná komponenta řádku lekce pro `LibraryScreen`, `IntroScreen` i `ReviewQueue` (stavová LED ryska / číslo, název + volitelná pedagogická poznámka, volitelný kompaktní `▶` + `LessonPatternStrip`, hvězdy a info).
6. **`BadgeTile` (`BadgeTile.swift`):** Získaný odznak má tmavý/kovový rámeček (`hairline`) + oranžový vnitřní LED akcent a jemný `accentGlow` — **žádný tlustý bílý prstenec**. Rozpracovaný odznak má tenkou `2pt` oranžovou kruhovou linku a procenta; nedotčený odznak `0 %` skrývá. K ikoně se přidává drobný štítek milníku (`1`, `10`, `50`…), aby celá řada nepůsobila identicky.

## 5. Produktový rozsah pro `release-polish`
- **Zachovat:** Tmavý i světlý režim (`VZHLED` na `HomeScreen`), `Review queue` (pročištěná — skrývat prázdné kroky s `0` lekcemi, bez duplicitního nadpisu).
- **Vyřadit v této verzi:** `MixLineupScreen` (`MixFlowScreen`), `DaySummaryView`, bloky `Extra mix` / `Play after me` v `TrainingScreen` a nedosažitelné Mix odznaky (`Shuffle`, `Blind mix`, `Juggler`).
- **Uvolněný pad `07` na `HomeScreen`:** Po odemknutí plné verze slouží jako přímý vstup do **`STUDIO RIG`**.
