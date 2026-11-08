# AI panel — nezávislé hodnocení Smack-a-Pad třemi AI

Cíl: tři různé AI (ChatGPT, Claude, Gemini) nezávisle posoudí aplikaci z co nejvíce úhlů. Výstupy pak sloučíme do jednoho přehledu a z něj rozhodneš, co dál.

Jazyk: tento návod je česky (pro Jakuba). Zadání pro AI v `prompts/` jsou anglicky, protože tak AI odpovídají přesněji a výsledky jdou rovnou do anglické dokumentace.

## Jak to funguje (přehled)

1. **Balíček podkladů**: jeden popis aplikace, snímky obrazovek, krátká videa a kód. Všechny tři AI dostanou totéž.
2. **Kolo 1 – nezávislé hodnocení**: každá AI dostane stejné společné jádro otázek (aby šly odpovědi porovnat) a k tomu jiné role (aby se pokrylo co nejvíc úhlů). Role jsou rozdělené podle toho, v čem je která AI silná.
3. **Kolo 2 – křížová kontrola (volitelné, ale doporučené)**: každá AI dostane anonymně odpovědi těch dvou zbylých a má říct, s čím nesouhlasí a co přehlédly. Tím se odfiltrují vymyšlené nebo povrchní připomínky.
4. **Sloučení**: všech 3 (nebo 6) odpovědí dáš Claude Code tady v projektu. Udělá z nich jednu tabulku: na čem se shodují, kde se rozcházejí, co je jen názor jedné AI.
5. **Rozhodnutí**: ty vybereš, co bereš. Teprve pak vzniknou tickety.

## Kdo co hodnotí

| AI | Model a přemýšlení | Role (kromě společného jádra) | Proč |
|---|---|---|---|
| **Gemini** (Google AI Pro) | Nejnovější **Gemini Pro** (3.x Pro) s přemýšlením; Deep Think je jen v Ultra, není potřeba | Úplný začátečník · iPad UX a přístupnost · učitel finger drummingu | Nejlépe zvládá **videa**, uvidí, jak se aplikace opravdu hraje |
| **ChatGPT** (Plus) | Nejsilnější **GPT Thinking** model, úroveň přemýšlení **vysoká** (Extended/Heavy, co nabídka ukáže). Na trh zapnout **Deep Research** | Trh a konkurence · cena a obchod · riziko zamítnutí v App Store · ďáblův advokát | Nejsilnější hledání na webu a průzkum trhu |
| **Claude** (Pro) | **Claude Opus** (nejnovější, teď 5.5) se zapnutým **Extended thinking** | Kód a architektura · rizika údržby s AI agenty · věda o učení (opakování, hvězdy, zpětná vazba) | Nejlepší čtení velkého množství kódu přes GitHub |

Pokud se v nabídce model jmenuje jinak, vyber vždy **nejsilnější model s přemýšlením**, ne rychlou verzi (Flash, mini, Instant).

## Krok za krokem

### Krok 0 – připrav balíček (jednou)

1. Nech agenta udělat ticket `docs/tickets/2026-11-08-148-ai-panel-review-pack.md`. Vznikne z něj `pack/00-brief.md` (popis aplikace na 2–3 strany) a `pack/shot-list.md` (seznam snímků a videí, která máš udělat).
2. Na iPadu udělej snímky podle `shot-list.md` (v angličtině, světlý režim). Ulož je do `pack/screens/`.
3. Videa: tentokrát se nenatáčejí (nebyl čas). Zadání pro Gemini s tím počítá. Kdyby sis je později natočil, ulož je do `pack/videos/` a zadání pro Gemini vrať do původní podoby z gitu.
4. Kód: v ChatGPT, Claude i Gemini připoj **GitHub** (Nastavení → Connectors / Integrations, repozitář `alkofolik/SmackAPad-iPad`). Kde to nejde, nahraj ZIP vytvořený tímhle příkazem (obsahuje jen soubory z gitu, žádné sestavení):

```bash
cd ~/Developer/SmackAPad-iPad && git archive --format=zip -o ~/Desktop/SmackAPad-code.zip HEAD
```

### Krok 1 – kolo 1 (každá AI zvlášť)

Pro každou AI:

1. Otevři **nový chat** a **vypni paměť** (ChatGPT: Dočasný chat; Claude: anonymní/incognito chat; Gemini: vypnutá aktivita / dočasný chat). Paměť by do hodnocení zatáhla, co o tobě ví.
2. Vyber model a přemýšlení podle tabulky výše.
3. Nahraj `00-brief.md`, snímky a u Gemini i videa. Připoj repozitář nebo ZIP.
4. Vlož celý text příslušného souboru z `prompts/` (`round1-gemini.md`, `round1-chatgpt.md`, `round1-claude.md`).
5. Odpověď zkopíruj **celou** do souboru `results/round1-<ai>.md` (např. `results/round1-gemini.md`).

Pozor: v zadání úmyslně **neříkáš, že aplikace je tvoje**. AI jsou k autorovi příliš vlídné; k cizí aplikaci jsou upřímnější.

### Krok 2 – kolo 2 (křížová kontrola)

Ve **stejném chatu** jako kolo 1 pošli text z `prompts/round2-cross.md` a pod něj vlož odpovědi těch **dvou ostatních** AI. Označ je jen „Reviewer X“ a „Reviewer Y“, ne jménem. Odpověď ulož do `results/round2-<ai>.md`.

### Krok 3 – sloučení (Claude Code tady)

V novém chatu Claude Code napiš: *„Proveď syntézu podle `docs/reviews/ai-panel/prompts/synthesis.md`.“* Vznikne `results/synthesis.md`.

### Krok 4 – rozhodnutí

Projdi `synthesis.md`. U každého bodu napiš **beru / neberu / později**. Z bodů „beru“ pak nech vytvořit tickety.

## Jak číst výsledky

- **Shoda tří AI** = silný signál, ale ne důkaz. Všechny tři mohou opakovat stejný obecný názor („přidejte gamifikaci“).
- **Konkrétní důkaz je víc než sebejistota.** Připomínka s odkazem na konkrétní obrazovku nebo soubor platí víc než obecná rada.
- **Názory na trh a cenu jsou odhady.** Ověřují se jen na skutečných lidech (TestFlight testeři).
- **Nic z toho nenahradí 5 živých bubeníků.** AI panel je levný první filtr, ne náhrada testerů.

## Složky

```
docs/reviews/ai-panel/
├── README.md            (tento návod)
├── prompts/             (zadání pro AI – kopíruj celé)
├── pack/                (podklady – vznikne z ticketu 148)
└── results/             (odpovědi AI a syntéza)
```
