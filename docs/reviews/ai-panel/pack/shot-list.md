# Seznam snímků a videí pro nezávislé hodnocení AI panelem (Shot list)

Ahoj Jakube,  
tento seznam slouží jako přesný návod, jaké snímky obrazovek a videonahrávky pořídit na iPadu. Všechny tři recenzní modely (ChatGPT, Claude, Gemini) uvidí pouze to, co jim poskytneme. Snímky a videa jim umožní posoudit vizuální hierarchii, přehlednost při hraní na stole, přesnost zpětné vazby i pedagogický rytmus aplikace.

---

## 1. Technické pokyny pro pořizování

1. **Jazyk aplikace**: V Nastavení (`Settings`) přepni jazyk na **angličtinu (`English`)**. Všechny recenzní AI pracují v angličtině, aby terminologie přesně seděla na dokumentaci a kód.
2. **Režim vzhledu**: **Světlý režim (`Light mode`)**. (Světlý režim je základní referenční zobrazení; volitelně je v seznamu jeden snímek tmavého režimu pro srovnání).
3. **Orientace iPadu**: **Na šířku (`Landscape`)**, což je primární režim na stojánku vedle kontroléru. Pokud je u konkrétního snímku výslovně uvedeno *Portrait*, otoč iPad na výšku.
4. **Umístění souborů**:
   - Snímky obrazovek ukládej do složky: `docs/reviews/ai-panel/pack/screens/`
   - Videa ukládej do složky: `docs/reviews/ai-panel/pack/videos/` (videa nepatří do gitu/GitHubu, slouží pouze pro nahrání do chatů AI).
5. **Názvy souborů**: Použij přesně níže uvedené názvy souborů (např. `01-home-screen.png`), aby se na ně hodnotitelé mohli ve svých zprávách jednoznačně odkazovat.

---

## 2. Seznam snímků obrazovek (Screenshots)

### Hlavní obrazovka (Home)
1. `01-home-screen.png`  
   - **Obrazovka**: Hlavní obrazovka v klidovém stavu na šířku.  
   - **Co zachytit**: Mřížka 3×3 hardwarových padů s centrálním oranžovým logem, horní nápis Smack-a-Pad, faderové lišty a popisky tlačítek (*Today / Continue*, *Library*, *Training*, *Intro*, *Controller*, *Badges*, *Full Version*, *Settings*).
2. `02-home-dark-mode.png`  
   - **Obrazovka**: Hlavní obrazovka přepnutá do tmavého režimu (*Dark mode*).  
   - **Co zachytit**: Kontrast a podání textury černého plastu a šedého kartáčovaného kovu v tmavém stylu.

### Knihovna lekcí (Library)
3. `03-library-path.png`  
   - **Obrazovka**: Knihovna, záložka **Path**.  
   - **Co zachytit**: Stupně řazené podle úrovní a technik (Stage), řádky lekcí s názvy, žánrem, tempem, hvězdičkami a zámkem u vyšších úrovní.
4. `04-library-soft-unlock-dialog.png`  
   - **Obrazovka**: Dialog ručního odemčení stupně (*Soft unlock*).  
   - **Co zachytit**: Klepnutí na zamčený banner stupně a otevřený potvrzovací dialog s otázkou na odemčení (*Unlock stage?*).
5. `05-library-genres.png`  
   - **Obrazovka**: Knihovna, záložka **Genres**.  
   - **Co zachytit**: Rozdělení lekcí do hudebních žánrů (*Rock & punk*, *Funk & soul*, *Jazz*, *Hip hop*, *Latin & world*, *Electronic*, *Pop*).
6. `06-library-techniques.png`  
   - **Obrazovka**: Knihovna, záložka **Techniques**.  
   - **Co zachytit**: Rozdělení lekcí podle bubenických technik (*Basic groove*, *Sixteenths*, *Ghost notes*, *Swing & shuffle*, *Fills & toms*).
7. `07-library-star-filter.png`  
   - **Obrazovka**: Knihovna s aktivním filtrem hvězd.  
   - **Co zachytit**: Vybraný filtr v horní liště (např. čipy `2★` nebo `In progress`), který filtruje zobrazené lekce.

### Základní průprava (Intro)
8. `08-intro-exercises.png`  
   - **Obrazovka**: Obrazovka úvodních cvičení (*Intro exercises*).  
   - **Co zachytit**: Seznam 25 základních průpravných cvičení pro koordinaci rukou, všechny bez zámků a otevřené pro začátečníky.

### Cvičební obrazovka (Practice)
9. `09-practice-play-running.png`  
   - **Obrazovka**: Obrazovka cvičení během aktivního hraní v režimu **Play**.  
   - **Co zachytit**: Oranžový pás s notovou mřížkou, značky počítání `1 e & a`, bílé a černé buňky pro levou/pravou ruku, zvýrazněný aktuální krok a klidné slovní hodnocení taktu v záhlaví (*clean*, *ahead*, *behind*).
10. `10-practice-static-view.png`  
    - **Obrazovka**: Cvičení v režimu statického zobrazení celého taktu (**Static view**).  
    - **Co zachytit**: Celý 1–2taktový vzor zobrazený pevně na šířku obrazovky s pohybujícím se ukazatelem aktuální pozice.
11. `11-practice-scrolling-view.png`  
    - **Obrazovka**: Cvičení v režimu posuvného pásu (**Scrolling view**).  
    - **Co zachytit**: Pás not ubíhající zprava doleva vstříc pevné svislé ose zásahu.
12. `12-practice-listen-mode.png`  
    - **Obrazovka**: Cvičení v režimu poslechu (**Listen**).  
    - **Co zachytit**: Zelenavě podbarvený pás poslechu, aktivní tlačítko *Listen*, přehrávání zvuku aplikací bez bodování.
13. `13-practice-from-memory.png`  
    - **Obrazovka**: Cvičení v režimu zpaměti (**From memory**).  
    - **Co zachytit**: Aktivní ikona přeškrtnutého oka, prázdný oranžový pás bez zobrazených not (hráč hraje čistě po paměti).
14. `14-practice-run-result.png`  
    - **Obrazovka**: Výsledková karta po odehraném průchodu.  
    - **Co zachytit**: Velké procentuální skóre, počet zásahů a chyb, banner s automatickým zvýšením tempa (*+5 BPM*) a podrobný rozpad přesnosti časování (*perfect*, *good*, *off*).
15. `15-practice-tools-popover.png`  
    - **Obrazovka**: Otevřená nabídka nástrojů v záhlaví cvičení (*More tools*).  
    - **Co zachytit**: Plovoucí okno s přepínačem zobrazení padů (*Show pads*), volbou bicí sady a odkazem na MIDI nastavení.
16. `16-practice-touch-pads-landscape.png`  
    - **Obrazovka**: Cvičení se zobrazenými dotykovými pady na displeji (Landscape).  
    - **Co zachytit**: Zmenšená mřížka dotykových padů integrovaná na cvičební obrazovce pro hraní bez kontroléru.
17. `17-practice-touch-pads-portrait.png`  
    - **Obrazovka**: Cvičení na výšku (**Portrait mode**).  
    - **Co zachytit**: Obrazovka při otočení iPadu na výšku, kde je nahoře notový pás a dole velká dotyková plocha padů.

### Trénink a opakování (Training)
18. `18-training-main.png`  
    - **Obrazovka**: Hlavní přehled Tréninku na šířku.  
    - **Co zachytit**: Oranžový pás denní relace *Today*, kruhový ukazatel *Memory meter* a 7denní kalendářní předpověď opakování *Next 7 days*.
19. `19-training-due-now.png`  
    - **Obrazovka**: Seznam lekcí na řadě (**Due now**).  
    - **Co zachytit**: Prvních 5 řádků lekcí čekajících na dnešní opakování, výběrové čipy kroků (*All*, *Step 1*, *Step 2*...) a tlačítko *Show all*.
20. `20-training-waiting-boxes.png`  
    - **Obrazovka**: Sekce čekajících lekcí (**Waiting**).  
    - **Co zachytit**: Rozbalený box (např. *Tomorrow* nebo *In 2–3 days*) se seznamem lekcí, které ještě čekají na svůj plánovaný den opakování.
21. `21-training-settled-box.png`  
    - **Obrazovka**: Sekce upevněných lekcí (**Settled**).  
    - **Co zachytit**: Rozbalený spodní box s lekcemi, které úspěšně prošly všemi fázemi opakování a jsou trvale upevněné.
22. `22-training-empty-state.png`  
    - **Obrazovka**: Trénink ve stavu, kdy je pro dnešek hotovo.  
    - **Co zachytit**: Zpráva o dokončení dnešního tréninku, žádné lekce v sekci *Due now*.

### Denní relace (Today Session)
23. `23-today-session-step-review.png`  
    - **Obrazovka**: Průvodce denní relací – Krok 1 (opakování lekce na řadě).  
    - **Co zachytit**: Karta úvodního opakování ze spaced repetition před spuštěním cvičení.
24. `24-today-session-summary.png`  
    - **Obrazovka**: Závěrečná karta denní relace (*Today session summary*).  
    - **Co zachytit**: Souhrn dokončené 10–15minutové relace (splněná opakování, nová lekce, celkové skóre).

### Úspěchy a odznaky (Badges)
25. `25-badges-gallery.png`  
    - **Obrazovka**: Galerie odznaků (**Badges**).  
    - **Co zachytit**: Mřížka odznaků rozdělených do kategorií (splněné lekce, tempa, paměť, žánry, trénink) s odlišením získaných a uzamčených odznaků.

### Nastavení a hardware (Settings, Controller, Calibration)
26. `26-settings-screen.png`  
    - **Obrazovka**: Obrazovka Nastavení (**Settings**).  
    - **Co zachytit**: Volba bicí sady (výběr z 8 kitů), krok zrychlení tempa (1/2/5/10 BPM), volba profilu kontroléru, přepínač jazyka a vzhledu.
27. `27-controller-setup.png`  
    - **Obrazovka**: Obrazovka nastavení kontroléru (**Controller setup**).  
    - **Co zachytit**: Seznam detekovaných MIDI vstupů, volba profilu, přepínač režimu 16 padů vs. 8 padů a odkaz na párování Bluetooth.
28. `28-controller-midi-learn.png`  
    - **Obrazovka**: Průvodce učením kontroléru (**MIDI learn**).  
    - **Co zachytit**: Interaktivní obrazovka s očíslovanými pady, instrukce pro stisknutí fyzického padu na kontroléru a zobrazená přiřazená MIDI čísla not.
29. `29-controller-bluetooth-pairing.png`  
    - **Obrazovka**: Systémový dialog Bluetooth MIDI.  
    - **Co zachytit**: Otevřené systémové okno pro vyhledání a připojení bezdrátového BLE MIDI kontroléru.
30. `30-calibration-guided.png`  
    - **Obrazovka**: Obrazovka kalibrace latence (**Calibration**).  
    - **Co zachytit**: Průvodce s 10 metronomovými údery, plocha pro poklepání a výsledný vypočtený časový posun v milisekundách (offset).

### Obchod a informace (Purchases & About)
31. `31-purchases-sheet.png`  
    - **Obrazovka**: Modální okno nákupu plné verze (**Full Version**).  
    - **Co zachytit**: Přehled výhod (529 plných lekcí, všechny žánry, neomezený trénink), reálné tlačítko s cenou z App Store a možnost *Restore purchases*.
32. `32-about-credits.png`  
    - **Obrazovka**: Obrazovka O aplikaci (**About**).  
    - **Co zachytit**: Číslo verze, stručný popis, licenční poděkování a kredity za použité zvukové vzorky (Creative Commons / AVL Drumkits).

---

## 3. Seznam obrazových nahrávek (Screen Recordings)

Natoč 3 krátká videa přímo z iPadu (každé **pod 2 minuty**). Hraj na fyzickém MIDI kontroléru položeném před iPadem.

### DŮLEŽITÉ: Jak nahrát čistý zvuk aplikace bez šumu z místnosti
1. Otevři **Ovládací centrum** (potažením z pravého horního rohu iPadu dolů).
2. **Dlouze podrž** prst na ikonce **Záznam obrazovky** (dvě soustředná kolečka).
3. Ve spodní části zkontroluj ikonku **Mikrofon**:
   - Musí být **VYPNUTÝ** (šedá/bílá ikona, text *Mikrofon vypnutý* / *Microphone Off*).
   - **Proč**: Když je mikrofon vypnutý, iPad zaznamená krystalicky čistý vnitřní zvuk aplikace (zvuky bicích, metronom, odezvu) a do videa se vůbec nenahraje šum místnosti ani mechanické klepání prstů do plastových padů kontroléru.
4. Klepni na *Zahájit záznam*.

---

### Video 1: První spuštění a první dokončená lekce
- **Název souboru**: `video-01-first-launch-and-lesson.mp4`
- **Délka**: cca 1:15 – 1:45 min
- **Co natočit**:
  1. Spuštění aplikace: proběhne startovní animace loga a usazení do 3×3 hardwarové mřížky na Home.
  2. Klepnutí na pad *Intro* (nebo první doporučené cvičení).
  3. Otevření první lekce v Practice:
     - 1–2 takty v režimu *Listen* (poslech vzoru).
     - Přepnutí na *Play* a odehrání 1–2 čistých průchodů na kontroléru.
  4. Ukázka vyhodnocení taktu (*clean*) v záhlaví.
  5. Dokončení cvičení, zobrazení výsledkové karty s první hvězdou (Star 1 / Passed) a návrat na Home.

### Video 2: Trénink v Play se zrychlováním tempa a výsledkem
- **Název souboru**: `video-02-play-tempo-rise.mp4`
- **Délka**: cca 1:30 – 1:50 min
- **Co natočit**:
  1. Vstup do *Library* $\rightarrow$ výběr běžného groovu (např. Level 1 nebo 2 Rock/Funk) s výchozím tempem pod cílovým tempem.
  2. Spuštění cvičení v režimu *Play*.
  3. Odehrání čistého průchodu na kontroléru.
  4. Ukázka okamžiku, kdy se objeví banner s automatickým navýšením tempa (*+5 BPM*) a plynulý přechod do dalšího průchodu ve vyšší rychlosti.
  5. Dosažení cílového tempa (Target BPM), zastavení a podrobná prohlídka výsledkové karty (skóre, timing feedback: *perfect / good / off*, čistota úderů).

### Video 3: Tréninkové opakování (Review) a hraní zpaměti
- **Název souboru**: `video-03-training-review-memory.mp4`
- **Délka**: cca 1:30 – 1:50 min
- **Co natočit**:
  1. Otevření obrazovky *Training* z Home.
  2. Ukázka seznamu *Due now* a výběr lekce čekající na opakování.
  3. Spuštění opakování: automatický start v režimu *From memory* v cílovém tempu se skrytými notami.
  4. Odehrání vzoru na kontroléru čistě po paměti.
  5. Zobrazení výsledku: uznání úspěšného opakování, slavnostní animace udělení 3. hvězdy (*Star 3* za dvě úspěšná opakování v Tréninku).
  6. Návrat do Tréninku a ukázka, jak se lekce přesunula do čekajících (*Waiting*) nebo upevněných (*Settled*).

---

## 4. Rychlý kontrolní seznam před odesláním AI panelu

- [ ] Všechny snímky pořízeny v angličtině (EN) a ve světlém režimu (Light mode).
- [ ] Všechny soubory uloženy s přesnými názvy v `docs/reviews/ai-panel/pack/screens/`.
- [ ] Všechna 3 videa natočena s vypnutým mikrofonem (čistý vnitřní zvuk) a uložena v `docs/reviews/ai-panel/pack/videos/`.
- [ ] Žádné video nepřesahuje 2 minuty.
