# Ticket 32 – Nákupy v aplikaci (free / Full unlock / rozšíření)

Status: ready-for-ipad-test (2026-11-02).

**Repo:** ~/Developer/SmackAPad-iPad
**Závisí na:** dokončených ticketech 25A/25B (knihovna) a 28–31. Pokud ještě nejsou hotové, dělej tento ticket až po nich.
**Doporučený model:** Codex GPT-6.1 Sol, reasoning **High** (nákupy jsou citlivé na chyby, ale nejde o složitý algoritmus).

---

## Cíl

Aplikace je zdarma ke stažení. Část lekcí je volně dostupná, zbytek odemkne jednorázový nákup **Full unlock**. Později přibudou **rozšíření** (balíčky lekcí) jako samostatné jednorázové nákupy. Žádné předplatné, žádná reklama, žádný vlastní server.

## Technické řešení

- Použij **StoreKit 2** (`Product`, `Product.purchase()`, `Transaction.currentEntitlements`, `Transaction.updates`, `AppStore.sync()`).
- Všechny produkty jsou typu **Non-Consumable**.
- Vytvoř jednu centrální třídu `StoreManager` (`@MainActor`, `ObservableObject` nebo `@Observable` podle zbytku projektu). Zbytek aplikace se ptá jen jí: „je lekce X odemčená?“
- Při startu aplikace spusť naslouchání `Transaction.updates` (nákupy z jiného zařízení, schválené „Ask to Buy“ apod.) a načti `Transaction.currentEntitlements`.
- Přijímej jen ověřené transakce (`.verified`). Po zpracování vždy volej `transaction.finish()`.
- Aplikace musí fungovat **offline**: stav odemčení odvozuj z `currentEntitlements` (StoreKit ho drží v cache). Žádné vlastní ukládání „zakoupeno = true“ do UserDefaults jako jediného zdroje pravdy.

## Produkty

Bundle ID doplň podle projektu (`<bundle>`):

| Product ID | Typ | Co odemyká |
|---|---|---|
| `<bundle>.full` | Non-Consumable | všechny lekce základní knihovny |
| `<bundle>.pack.<nazev>` | Non-Consumable | lekce daného rozšíření (zatím žádné, jen připravit) |
| `<bundle>.bundle.all` | Non-Consumable | Full + všechna rozšíření (zatím jen připravit, vypnuté) |

Ceny se nastavují v App Store Connect, **ne v kódu**. Aplikace vždy zobrazuje `product.displayPrice` (lokální měna).

## Které lekce jsou zdarma

- Do metadat lekce přidej pole `access`: `free` | `full` | `pack:<id>`.
- Výchozí stav: **zdarma celá kategorie Intro + první stupeň (stage 1) cesty Path**. Ostatní `full`.
- Seznam musí jít změnit jen úpravou dat lekcí, bez zásahu do logiky.
- Nákup Full unlock nemění pravidla odemykání stupňů (hvězdičky, ticket 25). Zamčení nákupem a zamčení stupněm jsou **dvě různé věci** a v knihovně se musí lišit vzhledem:
  - zamčeno stupněm = jako dosud,
  - zamčeno nákupem = malý symbol (zámek) + po klepnutí nabídka nákupu.

## Obrazovka nákupu (paywall)

- Otevře se po klepnutí na zamčenou lekci nebo z Nastavení.
- Jednoduchá, ve stylu aplikace (jen oranžová/černá/bílá, světlý i tmavý režim), žádný „AI look“.
- Obsah: nadpis, 3 krátké body (počet lekcí, jednorázová platba, bez předplatného), velké tlačítko s cenou, malý odkaz **Restore Purchases**, zavírací křížek.
- Počet lekcí počítej z dat, nepiš ho natvrdo.
- Texty EN (výchozí) + CS (podle ticketu 15 – lokalizace).

## Nastavení

- Sekce **Purchases**: stav (Free / Full), tlačítko **Restore Purchases** (`AppStore.sync()`), u rozšíření seznam s cenou nebo „Owned“.
- Restore je povinný pro schválení v App Store, musí být viditelný.

## Chybové stavy

- Uživatel nákup zruší → nic nehlásit, jen zavřít načítání.
- Nákup čeká (Ask to Buy) → krátká zpráva „Purchase pending approval“.
- Chyba sítě / produkty se nenačtou → zpráva + možnost zkusit znovu; volné lekce fungují dál.
- Restore nic nenašel → zpráva „No previous purchases found“.

## Testování

1. Vytvoř **StoreKit Configuration File** (`Products.storekit`) se všemi produkty výše a nastav ho ve schématu (Edit Scheme → Run → Options → StoreKit Configuration). Díky tomu jde nákup zkoušet bez App Store Connect.
2. Otestuj: nákup, zrušení, Ask to Buy, chybu, restore, start aplikace offline po nákupu.
3. Pozor: lokální testovací transakce se smažou se smazáním aplikace – restore po přeinstalaci testuj až v Sandboxu/TestFlightu.
4. Do repa přidej krátký návod `docs/2026-11-02-iap-testing.md`: jak spustit test nákupu, jak vymazat testovací nákupy (Debug → StoreKit → Manage Transactions).

## Hotovo, když

- [ ] Volné lekce jdou hrát bez nákupu, placené ukazují zámek a nabídku nákupu.
- [ ] Nákup Full unlock okamžitě odemkne všechny `full` lekce bez restartu.
- [ ] Odemčení přežije restart aplikace i režim letadlo.
- [ ] Restore funguje a je v Nastavení i na paywallu.
- [ ] Ceny se zobrazují z App Store, ne z kódu.
- [ ] Rozšíření jsou připravená v datech i kódu, zatím skrytá.
- [ ] Vzhled odpovídá zbytku aplikace (tři barvy, světlý/tmavý režim).
- [ ] Žádné změny pravidel hvězdiček ani odemykání stupňů.

## Nedělat

- Předplatné, reklamy, vlastní server, analytiku, slevové kódy v kódu (slevy se dělají v App Store Connect).

## Po dokončení

Napiš seznam změněných a nových souborů a co je potřeba ručně nastavit v App Store Connect (produkty, ceny, Paid Apps Agreement).

## Implementation (2026-11-02)

- Added the central observable StoreKit 2 manager, verified entitlement loading at launch/foreground, transaction updates, purchase and explicit restore. Ownership is never persisted in UserDefaults. Product prices come from StoreKit.
- Added access metadata to all 587 bundled lesson records: 58 free (25 Intro exercises plus the non-Intro members of Path stage 1), 529 Full. The existing Jersey/Footwork extension group remains in the base library. Pack discovery is data-driven; no pack is offered today and the all-content bundle is disabled.
- Added the English/Czech purchase sheet, Settings purchases section, separate purchase-lock affordance and guarded lesson entry including Play next. Stage and star policies remain unchanged.
- Added the shared scheme's local StoreKit configuration with Full and hidden pack/bundle placeholders. See `docs/2026-11-02-iap-testing.md` for the changed-file list, manual acceptance checklist and App Store Connect setup.
- Runtime purchase, cancellation, Ask to Buy, failure, restore, revocation and offline checks remain for Jakub on iPad / Sandbox. No additional automated tests were added or run.

- Validation: English/Czech catalogs and project file passed `plutil -lint`; `git diff --check` passed before the build. The first simulator build succeeded with `xcodebuild build -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ticket-32/app CODE_SIGNING_ALLOWED=NO 'OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox'`. No tests or further builds after success.
