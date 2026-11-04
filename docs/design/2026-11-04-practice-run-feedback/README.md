# Practice: Run Countdown, Per-Run Result & Star Moment — Design Proposals (Ticket 64)

Status: Design proposals ready for Jakub's decision. Source: Jakub, 2026-11-04. Follow-up: Implementation ticket after Jakub selects a proposal.

> [!NOTE]
> This deliverable contains **design proposals, interactive offline previews, and technical specifications only**. No application source code has been altered.

---

## 1. Quick Review Links

Open these self-contained HTML files directly in any desktop browser or Safari on iPad (100% offline, embedded IBM Plex Sans font, no server or network required):

| File | Concept | Character & Peripheral Ergonomics |
|---|---|---|
| [**index.html**](index.html) | **Srovnávací přehled** | Interactive workbench with comparative matrix and in-page proposal switcher. |
| [**proposal-a.html**](proposal-a.html) | **Návrh A / Blokové LED segmenty** | Hardware LED bar meter in the instrument row replacing the "2/4" text, paired with chained star sockets. |
| [**proposal-b.html**](proposal-b.html) | **Návrh B / Pravítko na horní hraně pásu** | *(Recommended)* Integrated 8 pt ruler embedded directly along the top rim of the orange cut-tape band. Zero eye travel away from the notation. |
| [**proposal-c.html**](proposal-c.html) | **Návrh C / Hardwarová 4-padová matice** | Silicone MPC pad cluster with the signature orange Smack Pad 4 acting as the unmistakable final bar alert. |

Every preview includes:
- **Landscape (1194×834)** vs **Portrait (834×1194)** layout switcher (with full playable 4×4 touch deck in portrait).
- **Light (`#FFFFFF`)** vs **Dark (`#000000`)** appearance.
- **Standard Motion** vs **Reduce Motion** (fill/opacity only, zero spatial animation).
- **Learning Mode** (keeps banked progress on a weak run) vs **Challenge Mode** (breaks streak and resets to 0).
- **Intro Lesson (needs 3 runs)** vs **Standard Lesson (needs 1 run)**.
- **Speed Switcher (1×, 1.5×, 2×)** for rapid simulation testing.
- **Sound Toggle** (synthesized Web Audio metronome clicks and drum hits).
- **Replay Button** to restart from the 4-beat count-in.

---

## 2. Proposals: Concept & Anatomy

### Proposal A: Segmented Meter Blocks & Chained Star Rail
Návrh A umísťuje odpočet i hvězdný pokrok do nástrojového řádku vpravo od zrychlovacího banneru, kde dříve sídlil malý text „2/4“ a „1/3“. Odpočet tvoří čtyři masivní horizontální segmenty v matném rámečku; jak jednotlivé takty probíhají, segmenty se plynule plní temným inkoustem nebo oranžovou výplní. Čtvrtý segment (poslední takt kola) má od počátku zřetelný dvojitý rámeček a jemné diagonální šrafování; jakmile 3. takt dosáhne doby 3.5, rámeček čtvrtého bloku se rozsvítí sytým oranžovo-bílým pulzem, takže periferní vidění hráče spolehlivě registruje blížící se finále ještě před jeho spuštěním. Po skončení kola indikuje klidná svislá značka výsledek (zelená pro čistý, červená pro nečistý průchod) a předá impuls do pásu hvězdných soklů: v režimu **Learning** mají sokly tvar samostatných akumulátorových článků, kde se po slabém průchodu kredit 1. kola bezpečně uchová, zatímco v režimu **Challenge** jsou sokly propojeny svítícím řetězem, který se při chybě s krátkým 200 ms zábleskem rozpojí a vyprázdní zpět na nulu.

### Proposal B: Pattern Band Top Spine & Ledger Vault *(RECOMMENDED)*
Návrh B řeší periferní čtení z pohledu reality finger-drummingu: hráč se dívá na fyzické pady kontroleru a na iPad hází pouze kradmé pohledy, přičemž jeho zrak automaticky sklouzává k dominantnímu oranžovému pásu s notací. Odpočet kola je proto integrován přímo do horní 8 pt hrany oranžového pásu jako přesné hardware pravítko rozdělené do 4 sektorů, jimiž plynule projíždí kontrastní bílá stopa souběžně s přehrávací hlavou. Čtvrtý sektor má na své náběhové hraně zkosený trojúhelníkový zub s vysokým černobílým kontrastem, který se na konci 3. taktu výrazně rozsvítí a upozorní hráče na poslední takt bez nutnosti těkat očima do záhlaví. Hned nad pásem (nebo v pravém rohu lišty) je umístěn kompaktní mechanický „Trezor kol“: v režimu **Learning** se každé úspěšné kolo mechanicky orazítkuje těžkým temným štítkem, který nelze smazat, zatímco v režimu **Challenge** spočívají štítky na napnutém pružném lanku, které při nečistém průchodu s mechanickým rázem odskočí a vrátí stav do nuly.

### Proposal C: Hardware 4-Pad Cluster & Star Pod Circuit
Návrh C čerpá stoprocentně z vlastní vizuální identity Smack-a-Pad a hardware jazyka bicích kontrolerů: odpočet kola tvoří miniaturní sekvencér 1×4 silikonových padů (24×24 pt) v nástrojovém řádku. Pady 1, 2 a 3 jsou neutrální tmavé čtverce s drobnou LED diodou, zatímco **Pad 4 je trvale zhotoven v signaturní oranžové barvě jako ikonický „Smack Pad“** z loga aplikace. Protože je 4. pad jediný zářivě oranžový, periferní vidění hráče má absolutní přehled o poloze konce kola; na 3. době 3. taktu navíc pad 4 začne pulzovat z 40 % na 100 % jasu, což dává jasný signál „připrav se na finální Smack úder“. Výsledek kola způsobuje fyzický odskok padu a nabití hvězdných podů: v režimu **Learning** fungují pody jako trvalé kondenzátory držící náboj, v režimu **Challenge** jsou zapojeny v sériovém obvodu s tavnou pojistkou, která se při chybě přeruší a pody vyhasnou.

---

## 3. Storyboard of the Star Moment with Timings

Získání 1. hvězdy nastává **za nepřerušeného chodu lekce** (při t = 0.00 s dalšího taktu).
Animace nesmí posunout layout, nesmí zakrýt notový pás a musí skončit do cca 0.85 s:

### Proposal A: "Energy Fusion & Ejection" (Total duration: 0.80 s)
| Čas (s) | Prvek | Vizuální a pohybová akce | Zvuk / VoiceOver |
|---|---|---|---|
| **0.00 s** | Sokly hvězd | Bar 4 skončil. 3. sokl se naplní; všechny 3 sokly zazáří sytým oranžovým přepětím (`#FF6B00`). Další kolo začíná okamžitě bez prodlevy! | Metronom běží, downbeat nového kola |
| **0.15 s** | Hvězdný glyf | Ze soklu vyskočí ostrý vektorový glyf hvězdy (32 pt), expanduje na `scale(1.22)` a stoupá o 8 pt vzhůru. | VoiceOver: *„1. hvězda získána: Úspěšně splněno.“* |
| **0.40 s** | Usazení | Hvězda plynule dosedá (`scale 1.22 → 1.0`, `opacity 1.0 → 0.0`) a předává světlo stálé 1. hvězdě v záhlaví obrazovky. | Takt 1 nového kola běží |
| **0.80 s** | Klid | Všechny přechodové efekty ukončeny. 1. hvězda v záhlaví svítí trvale oranžově. | — |

*Při zapnutém Reduce Motion*: 0.00–0.25 s klidný přechod výplně bez změny měřítka či posunu.

---

### Proposal B: "Laser Ribbon Sweep & Vault Seal" (Total duration: 0.70 s)
| Čas (s) | Prvek | Vizuální a pohybová akce | Zvuk / VoiceOver |
|---|---|---|---|
| **0.00 s** | Trezor kol | 3. štítek zapadne; pečeť trezoru se rozsvítí oranžovým zlatem. Kolo 5 okamžitě začíná na novém taktu. | Metronom běží, downbeat nového kola |
| **0.10 s** | Horní lišta pásu | Po 8 pt liště na horní hraně oranžového pásu přeběhne zleva doprava úzký laserový světelný paprsek (šířka 20 %, trvání 0.45 s). Noty pod lištou jsou zcela netknuté. | VoiceOver: *„1. hvězda získána: Úspěšně splněno.“* |
| **0.40 s** | Pečeť trezoru | Zapečetěná hvězda na trezoru jemně pulzuje (`scale 1.15 → 1.0`) a rozsvěcí 1. hvězdu v záhlaví lekce. | Takt 1 nového kola běží |
| **0.70 s** | Klid | Paprsek dojel na konec lišty a vytratil se. Pás i trezor v klidovém stavu, lekce pokračuje vyšším tempem. | — |

*Při zapnutém Reduce Motion*: Žádný laserový přelet; okamžité plynulé rozsvícení pečeti a hvězdy v záhlaví za 0.20 s.

---

### Proposal C: "Pad Smack Impulse & Shockwave Ring" (Total duration: 0.85 s)
| Čas (s) | Prvek | Vizuální a pohybová akce | Zvuk / VoiceOver |
|---|---|---|---|
| **0.00 s** | Smack Pad 4 | Poslední úder 4. taktu: Pad 4 provede mechanický odskok (`scale 0.94 → 1.05`) a předá elektrický impuls do 3. podu. | Úder bicích + metronom |
| **0.15 s** | Hvězdné pody | Všechny 3 pody se rozsvítí bílo-oranžovým zábleskem; z centrálního podu vyrazí jemný kruhový prstenec rázové vlny (rádius 12 → 36 pt). | VoiceOver: *„1. hvězda získána: Úspěšně splněno.“* |
| **0.50 s** | Rozpad vlny | Prstenec se rozplývá (`opacity → 0`), stálá 1. hvězda v záhlaví se rozsvěcí sytou oranžovou barvou. | Takt 1 nového kola běží |
| **0.85 s** | Klid | Obvod zklidněn, sekvencér 4 padů odpočítává nový takt. | — |

*Při zapnutém Reduce Motion*: Odskok a rázová vlna vypnuty; čisté přebliknutí podů za 0.20 s.

---

## 4. How Each Maps to SwiftUI (One Line Each)

- **Proposal A**:
  ```swift
  // Instrument row embeds RunMeterBlocksView(currentBar:progress:) next to StarRailView(streak:mode:earned:)
  ```
- **Proposal B**:
  ```swift
  // PatternField overlays BandTopSpineRuler(position:bars:) along its top rim; instrument row hosts LedgerVaultView(streak:mode:)
  ```
- **Proposal C**:
  ```swift
  // Instrument row embeds MiniPadSequencerView(activePad:primed:) linked to StarPodCircuitView(pods:isBroken:)
  ```

---

## 5. Recommendation for Jakub

**Jednoznačně doporučujeme Návrh B (Pravítko na horní hraně pásu).**

### Důvody:
1. **Přirozená ergonomie zraku (Peripheral Glance):** Při hraní na kontroleru má hráč zrak fixovaný na fyzické pady a iPad sleduje periferně. Když se podívá na iPad, jeho oči míří **přímo na oranžový pás s notací a přehrávací hlavou**, nikoliv do záhlaví či nástrojových řádků. Umístění 8 pt pravítka přímo na horní hranu pásu znamená, že hráč vidí odpočet kola i blížící se finální 4. takt na stejném místě, kde čte noty — bez jediného pohybu očí navíc.
2. **Klidný a nevtíravý charakter:** Horní lišta je tenká (8 pt), elegantní a střídmá. Nezabírá žádné drahocenné vertikální místo na obrazovce a nezahušťuje nástrojový řádek.
3. **Působivý, ale bezpečný hvězdný moment:** Laserový přelet světelného bodu po 8 pt horní liště trvá jen 0.45 s, vypadá vysoce prémiově a profesionálně jako na high-end studiovém racku, a přitom **ani na milimetr nezasáhne do notových bloků pod ním**.
4. **Čitelný kontrast Learning vs Challenge:** Mechanická razítka v „Trezoru kol“ poskytují jasnou fyzickou metaforu — v Learningu jsou razítka zapečetěná a nelze je vzít zpět, v Challenge visí na pružném lanku, které při chybě okamžitě odskočí.

*(Pokud by Jakub preferoval mít všechny stavové ukazatele striktně soustředěné v nástrojovém řádku a nezasahovat do oranžového pole, je druhou nejlepší volbou **Návrh A**).*

---

## 6. Open Questions for Jakub

1. **Umístění odpočtu (na pásu vs v řádku):** Vyhovuje ti integrované pravítko přímo na horní hraně oranžového pásu (Návrh B), nebo dáváš přednost soustředění všech čítačů do nástrojového řádku vedle tempa (Návrh A / C)?
2. **Časování varování před 4. taktem:** V náhledech je varovný signál (pulzování rámečku / zubu / Smack Padu) nastaven na **dobu 3.5 ve 3. taktu** (tedy 2 šestnáctiny před začátkem 4. taktu). Je tento předstih z pohledu bubnování akorát, nebo bys uvítal varování již od začátku 3. taktu?
3. **Značka nečistého průchodu v Learningu:** Když v režimu Learning hráč zahraje slabé kolo, kredit se mu nesmaže. Přeješ si v UI zanechat drobnou tichou značku nečistého kola (např. tmavě červený bod či zářez vedle trezoru/soklu), aby hráč věděl, že toto konkrétní kolo nebylo uznáno, nebo má indikátor zůstat zcela netečný?
