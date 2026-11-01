# Hvězdy během cvičení (2026-11-01)

Stav: implementováno; závěrečné sestavení uspělo a všech 59 testů prošlo. Kontrola na iPadu zbývá Jakubovi.

## Rozhodnutí

- Po dokončeném průchodu se porovná jeho výsledek s dosavadním uloženým postupem lekce. Pořadí hvězd je Splněno, Cílové tempo, Z paměti. Pravidla udělování a ukládání hvězd zůstávají stejná.
- Panel ukazuje všechny tři hvězdy přibližně dvě sekundy. Dřívější jsou plné, nezískané mají obrys a všechny právě získané hvězdy současně vyskočí a zaplní se. Opakovaně získané hvězdy panel nevyvolají.
- Po první nové hvězdě hraní pokračuje. Panel je vpravo nahoře v oranžovém poli, má hvězdy 28 bodů, oranžové pozadí, černý rámeček 2 body a hranaté rohy. Pattern se nezatmívá a panel neblokuje dotyky.
- Nová druhá nebo třetí hvězda ukončí běh. Panel je vystředěný s hvězdami 56 bodů a běžný souhrn ukáže poslední dokončený průchod a hvězdy získané během běhu.
- Následující rozjetý průchod se zahodí a do souhrnu ani postupu nepřispěje. Zastavení probíhá až po návratu z vyhodnocení; nevolá se rekurzivně. Při ručním STOPu se stále započítají pouze dokončené průchody.
- Smyčka části lekce hvězdy nepřiděluje. Poslech se nevyhodnocuje. Tyto režimy nové automatické zastavení nevyvolávají.
- Při zapnutém Omezit pohyb se panel a nové výplně pouze prolnou, bez změny velikosti. VoiceOver oznámí názvy nových hvězd česky nebo anglicky podle jazyka aplikace.
- START i RESTART vyčistí předchozí událost. Změna události nebo opuštění obrazovky zruší čekání původního panelu.

## Ověření

- Přidáno osm jednotkových testů `StarAward`: první získání každé hvězdy, opakované získání, dvě a tři hvězdy najednou, zachování starých hvězd při horším výsledku a průchod bez hvězdy.
- Úplná sada na simulátoru iPad Air 11-inch (M4): 59 testů, 0 chyb (51 dosavadních a 8 nových). Úspěšné testy se znovu nespouštěly.
- První pokus v omezeném prostředí neměl přístup ke službě simulátoru; testy se v něm nespustily. Po spuštění s potřebným přístupem celá sada prošla.
- Závěrečné sestavení pro `generic/platform=iOS Simulator` s `CODE_SIGNING_ALLOWED=NO` a výstupem v `build/stars`: **BUILD SUCCEEDED**. Po úspěšném sestavení se další ověřování nespouštělo.

## Soubory

Nové:

- `SmackAPad/Sources/UI/StarAward.swift`: porovnání hvězd a rozhodnutí o zastavení.
- `SmackAPad/Sources/UI/StarBurst.swift`: krátký panel, animace a oznámení pro VoiceOver.
- `SmackAPadTests/StarAwardTests.swift`: osm testů porovnání hvězd.
- `docs/design/2026-11-01-star-feedback.md`: tento záznam.

Upravené:

- `SmackAPad/Sources/UI/PracticeSession.swift`: událost nové hvězdy a ukončení běhu po vyhodnocení.
- `SmackAPad/Sources/UI/PracticeScreen.swift`: umístění panelu a české i anglické názvy hvězd.

## Co zkontrolovat na iPadu

1. U lekce bez hvězd získat Splněno pod cílovým tempem: malý panel zmizí asi za dvě sekundy, pattern a jeho barvy zůstanou čitelné a hraní i zvyšování tempa pokračuje.
2. Poprvé získat Cílové tempo: běh i naplánovaný zvuk se zastaví, ukáže se velký panel a souhrn; rozjetý další průchod se nezapočítá.
3. Poprvé získat Z paměti: běh se zastaví a pattern se znovu ukáže. Zkusit také dvě nebo tři nové hvězdy najednou.
4. Opakovat dříve získané hvězdy: žádná nová animace ani automatické zastavení. Po návratu do lekce zkontrolovat, že hvězdy zůstaly uložené.
5. Zkusit Poslech a smyčku části vícetaktové lekce: žádné nové hvězdy ani automatické zastavení.
6. Zkusit ruční STOP a rychlý RESTART během malého panelu: souhrn zůstane běžný, nový běh nemá starou animaci.
7. Zapnout Omezit pohyb a VoiceOver: pouze prolnutí, správná oznámení nových hvězd v češtině i angličtině. Zkontrolovat světlý a tmavý vzhled i oba pohledy patternu.
