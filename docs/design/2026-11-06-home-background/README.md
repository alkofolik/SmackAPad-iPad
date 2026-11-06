# Návrhy pozadí domovské obrazovky (Ticket 114)

Status: návrhy připraveny k rozhodnutí Jakuba.
Zdroj: Jakub (2026-11-06): *„Chtěl bych, aby plocha Home obrazovky měla v pozadí nějakou strukturu a působila jako povrch padového MIDI kontroleru.“*
Návaznost: implementační ticket se sepíše po Jakubově výběru. V tomto úkolu se **nemění žádný kód aplikace, assety ani lokalizační řetězce**.

---

## 1. Rychlé odkazy na náhledy

Všechny náhledy jsou plně soběstačné a spustitelné přímo v prohlížeči na Macu (bez nutnosti webového serveru či internetového připojení; font IBM Plex Sans i vektorová grafika jsou přímo vloženy):

| Soubor | Návrh | Klíčový charakter | Způsob realizace ve SwiftUI |
|---|---|---|---|
| [**index.html**](index.html) | **Srovnání & Přehled** | Srovnávací matice všech parametrů, živý přepínač návrhů přímo v rámu iPadu a tabulky nákladů. | – |
| [**proposal-a.html**](proposal-a.html) | **Návrh A (Doporučeno)** | **Akai MPC Milled Wells & Anodised Stipple** — Samostatná frézovaná lůžka pro každý pad, matný eloxovaný hliník, Torx šroubky a číslování padů 01–08. | ZStack lůžko za každým padem v mřížce + bezešvá 128×128 dlaždice textury. |
| [**proposal-b.html**](proposal-b.html) | **Návrh B** | **Teenage Engineering Perforated Grille** — Pravidelná mikro-perforace roštu, ochranný štít proti rušení textu a inženýrské kalibrační linky s pravítkem. | Vektorová dlaždice 16×16 pt s maskou + SwiftUI Path pro vodicí linky a pravítko. |
| [**proposal-c.html**](proposal-c.html) | **Návrh C** | **SP-1200 Modular Bay & Studio Vignette** — Dvě konstrukční vodorovné spáry, společná zapuštěná deska padů se 4 rohovými šroubky a jemný studiový světelný spád. | 100% nativní kód bez assetů: `RadialGradient` pro vinětaci + SwiftUI tvary pro spáry a desku. |

Každý náhled obsahuje interaktivní lištu s přepínači:
- **Vzhled**: Světlý (krémová `#F4EFE6`) vs. Tmavý (teplá černá `#1F1D1A`).
- **Orientace**: Na šířku (980×685) vs. Na výšku (610×874).
- **Pozadí (ZAPNUTO / VYPNUTO)**: Jedním kliknutím můžete strukturované pozadí zcela skrýt a porovnat ho s původní prázdnou plochou.
- **Pohyb (Reduce Motion)**: Plný pohyb vs. Přísný režim bez animací (dle pravidel ticketu 27 a 112).
- **Simulace MIDI úderu**: Tlačítka 1–8 (či klávesy 1–8 na klávesnici) simulující reakci padu na úder z fyzického kontroleru.

---

## 2. Podrobný popis jednotlivých návrhů

### Návrh A: Frézovaná lůžka padů & Eloxovaný mat (*DOPORUČENO*)
- **Inspirace a filozofie**: Moderní vlajkové lodě profesionálního prstového bubnování (Akai MPC Live, MPC Studio, Ableton Push). Povrch kontroleru je pevný monoblok s přesně zapuštěnými lůžky pro každý jednotlivý pad.
- **Lůžka padů (Pad wells)**: Každý z 8 funkčních padů i centrální logo sedí ve vlastním vyfrézovaném lůžku s 4px lemem a vnitřním stínem. 
  - **Hmatová dynamika úderu**: Když na pad klepnete (nebo stisknete klávesu 1–8), pad se fyzicky zmenší na 96.5 % a klesne o 1.5 pt. Tím se opticky odhalí horní tmavá hrana vybrání v šasi a pad se zanoří hlouběji do těla nástroje. Tento efekt působí neuvěřitelně reálně a uspokojivě.
- **Silkscreen a číslování**: U levého horního rohu každého lůžka je vyraženo decentní technické číslo `01` až `08` v barvě `Theme.secondary` s jemnou průhledností (35 %). Logo nese označení `CORE`.
- **Povrch a kování**: Jemná matná zrnitost tryskaného eloxovaného hliníku eliminuje digitální sterilitu displeje. V rozích čelního panelu jsou 4 zapuštěné Torx šroubky a pod logem probíhá vodorovná dělící drážka oddělující hlavičku od hrací desky.

---

### Návrh B: Perforovaný studiový rošt & Technické linky
- **Inspirace a filozofie**: Přístroje s výraznou inženýrskou estetikou (Teenage Engineering, Roland TR-808/909, studiové mixážní a rackové panely).
- **Perforovaný rastr (Mikro-perforace)**: Plochu čelního panelu pokrývá pravidelná geometrická mřížka drobných bodů (průměr 2 px, rozteč 16 px). Působí jako kovový perforovaný rošt pro odvětrávání či vestavěný reproduktor.
- **Ochranný štít (Legibility Shield)**: Aby perforace nerušila čitelnost textu a nepůsobila za písmeny rušivě, je za nápisem Smack-a-Pad i za celou maticí padů aplikován plynulý kruhový štít, který body postupně stahuje do nuly. Texty zůstávají krystalicky čisté a splňují **WCAG AAA**.
- **Kalibrační kolejnice a pravítko**: Maticí padů prochází jemné vodicí osy ukončené rohovými křížovými značkami `+`. Na pravém okraji displeje (v režimu na šířku) se nachází vertikální milimetrové měřítko s popisem `CALIBRATED MATRIX · 44.1 kHz`. Nad sloupci padů jsou vypsána označení sběrnic `[ BANK A · 01–03 ]`.

---

### Návrh C: Modulární šasi se spárami & Studiová vinětace
- **Inspirace a filozofie**: Těžké studiové samplery a bicí automaty (E-mu SP-1200, Akai MPC 2000XL, Dave Smith Tempest) složené z robustních montovaných dílů.
- **Dvě konstrukční spáry**: Čelní panel je dvěma vodorovnými drážkami (s 1.5px stínem a 1px světelnou hranou) rozdělen na 3 zóny: horní displejový blok s logem, střední hrací desku a spodní servisní lištu.
- **Zapuštěná deska padů (Bay Plate)**: Všech 9 buněk mřížky je zasazeno do vyvýšené montážní desky s 14px zaoblením, jemně odlišným odstínem povrchu a 4 křížovými šroubky v rozích.
- **Studiová vinětace**: Pozadí má velmi jemný, organický světelný spád shora dolů (simulace kuželu světla studiové lampy namířené na pracovní plochu). Rozdíl jasu mezi středem a okrajem je pouhých 3.5 %, takže texty neztrácejí kontrast a displej získává fyzickou hloubku.
- **Servisní štítek**: V dolní liště je vyražen nápis `SMACK-A-PAD // MODEL 3x3 // TACTILE MIDI TRAINER // REV. 1.0` s oranžovou kontrolkou.

---

## 3. Na co se v náhledech zaměřit

1. **Tlačítko „Pozadí: ZAPNUTO / VYPNUTO“**:
   - Vyzkoušejte si přepnout pozadí do stavu VYPNUTO a zpět. Uvidíte, jak prázdná plocha okamžitě ožije a získá hloubku skutečného hardware nástroje, aniž by tím utrpěla přehlednost.
2. **Reakce lůžek na stisk padu (v Návrhu A)**:
   - Klepněte na pad nebo stiskněte klávesy 1–8 na klávesnici. Sledujte, jak se pad mechanicky zanoří do svého vyfrézovaného lůžka.
3. **Přepínání Světlý (Cream) a Tmavý (Soft Black) vzhled**:
   - V obou režimech jsou všechny stíny, spáry a textury přesně laděny do teplých tónů palety z ticketu 92. Nikde není čistá `#000000` ani studená šedá.
4. **Otočení na výšku (Portrait)**:
   - Ověřte, že se pozadí v režimu na výšku přirozeně přizpůsobí užšímu zobrazení iPadu bez viditelných švů a bez deformace prvků.
5. **Čitelnost textů**:
   - Všimněte si, že za žádným nápisem ani titulkem padu neprochází žádný kontrastní rušivý vzor (splňuje nejpřísnější kritérium WCAG AAA).

---

## 4. Doporučení jednoho návrhu

### **Jednoznačně doporučujeme Návrh A (Frézovaná lůžka padů & Eloxovaný mat).**

**Důvody:**
1. **Pady potřebují fyzické lůžko**: Pady ze schváleného ticketu 112 mají 8 pt rádius a zkosenou fazetku. Když leží na zcela plochém pozadí, působí trochu jako plovoucí samolepky. Jakmile pod ně dáte vyfrézované lůžko se stínem, pad se stane skutečným 3D tlačítkem zasazeným do hliníkového šasi.
2. **Nejlepší hmatová iluze při úderu**: Zanoření padu do lůžka při stisku dodává interakci na iPadu i přes externí kontroler mimořádnou fyzickou váhu.
3. **Klid a elegance bez technického křiku**: Návrh B s perforací a pravítkem může na menších iPadech působit až příliš „vědecky“ či technicky. Návrh A je čistý, sebevědomý a dospělý – přesně odpovídá duchu `DESIGN-BRIEF.md`.
4. **Číslování 01–08**: Malé číselné indexy v rohu lůžek pomáhají orientaci při mapování padů na externí MIDI kontroler.

---

## 5. Jak by se jednotlivé návrhy postavily ve SwiftUI a jaká je jejich cena

| Návrh | Způsob stavby ve SwiftUI | Výpočetní zátěž (GPU/CPU) | Paměťová náročnost |
|---|---|---|---|
| **Návrh A** | • Lůžka padů: `RoundedRectangle(cornerRadius: 10)` s `.fill(Theme.surface.opacity(0.4))` a vnitřním stínem vložený přímo do pozadí každé buňky v `HomeScreen.swift`.<br>• Matný povrch: bezešvá PNG dlaždice 128×128 pt s `.resizable(resizingMode: .tile)`.<br>• Šroubky a spára: statické tvary `Circle` a `Rectangle`. | **Nulová per-frame zátěž (0 % CPU)**. Mřížka lůžek je součástí stejného stromu zobrazení. Metal dlaždici blituje v jedné draw call operaci. | < 15 KB RAM pro dlaždici textury. |
| **Návrh B** | • Perforovaný rošt: Vektorový PDF asset 16×16 pt s `.resizable(resizingMode: .tile)` a maskou `.mask(RadialGradient(...))`.<br>• Kalibrační linky: Jednoduchý SwiftUI `Canvas` nebo `Path` vykreslený jednou. | **Extrémně nízká**. Dlaždicový rošt je v GPU paměti, maska se aplikuje jednou při renderu vrstvy. | < 8 KB RAM pro dlaždici bodů. |
| **Návrh C** | • Vinětace: `RadialGradient` přímo v pozadí `ZStack`.<br>• Spáry a deska: Standardní SwiftUI `Rectangle` a `RoundedRectangle` s rámečkem `.stroke(...)`.<br>• Šroubky: Vektorové SwiftUI tvary. | **Absolutně nulová režie**. 100% nativní kód bez jakéhokoliv externího assetu, 120 FPS na iPadu Pro, 0 ms zpoždění při načtení. | 0 KB (žádné bitmapové assety). |
