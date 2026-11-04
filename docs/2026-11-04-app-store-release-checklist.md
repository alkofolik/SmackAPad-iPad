# Smack-a-Pad 1.0 — postup vydání na App Store (iPadOS)

Stav k 2026-11-04: nákupy (ticket 32) hotové v kódu — `cz.kju.SmackAPad.full` (non-consumable), Obnovit nákupy v Nastavení i v nákupním okně, balíčky připravené a skryté. 58 lekcí zdarma, 529 v Full. Ikona a název „Smack-a-Pad“ hotové. Chybí: privacy manifest, klíč pro export šifrování, viditelné kredity zvuků (CC BY-SA), odkazy podpora/soukromí, web, snímky, texty. Tickety vydání 79–83 jsou odložené (nejsou v pořadí).

## A. Právo a podnikání (nejdřív — může vše zastavit)
- [ ] Ověřit, že vedlejší podnikání nekoliduje s funkcí soudního komisaře / zaměstnáním u notáře
- [ ] Živnostenské oprávnění (volná živnost – software), přihláška OSVČ na FÚ, ČSSZ, ZP (vedlejší činnost)
- [ ] DPH: s daňovým poradcem ověřit registraci jako identifikovaná osoba (služba Applu do Irska)
- [ ] Bankovní účet pro výplaty od Applu
- [ ] Kontaktní e‑mail pro podporu (nový, ne osobní)

## B. App Store Connect – smlouvy a účet
- [ ] Business → Paid Apps Agreement přijmout, vyplnit banku a daňové formuláře
- [ ] Status obchodníka (DSA) – vyplnit adresu, telefon, e‑mail (budou veřejné v EU)
- [ ] Přihláška do Small Business Programu (15 %)
- [ ] Vytvořit aplikaci: bundle ID `cz.kju.SmackAPad`, název, primární jazyk angličtina, SKU
- [ ] Vytvořit nákup `cz.kju.SmackAPad.full` (Non-Consumable): cena, název a popis EN/CS, snímek pro kontrolu
- [ ] Users and Access → Sandbox → testovací účet

## C. Kód před vydáním
- [ ] Dokončit rozpracované funkční tickety a zmrazit funkce pro 1.0
- [ ] Ticket 79 – privacy manifest, šifrování, kontrola Release buildu → test
- [ ] Ticket 81 – web podpory a zásad soukromí → zveřejnit, získat URL
- [ ] Ticket 80 – O aplikaci + kredity + odkazy (vložit URL z 81) → test

## D. Testování
- [ ] Lokální test nákupů podle `docs/2026-11-02-iap-testing.md`
- [ ] Product → Archive → Distribute → TestFlight (interní)
- [ ] Sandbox: koupě, smazání a reinstalace, Obnovit nákupy, offline start
- [ ] Externí TestFlight: 3–10 testerů, 1–2 týdny, sbírat chyby
- [ ] Projít kontrolní seznam níže

## E. Stránka v obchodě
- [ ] Ticket 83 – texty EN/CS + poznámky pro kontrolu
- [ ] Ticket 82 – snímky 13″ iPad EN/CS
- [ ] App Privacy: Data Not Collected
- [ ] Věkové hodnocení, kategorie (Music / Education), cena aplikace Free, země dostupnosti
- [ ] URL podpory a zásad soukromí
- [ ] Content Rights: potvrdit práva k obsahu třetích stran (zvukové samply – kredity hotové v tiketu 80; lekce jsou vlastní)

## F. Odeslání a vydání
- [ ] K verzi 1.0 přiložit build a nákup Full (In-App Purchases → vybrat)
- [ ] Vydání: ručně (Manually release)
- [ ] Odeslat ke kontrole; při zamítnutí odpovědět v Resolution Center
- [ ] Vydat, sledovat pády (Xcode → Organizer → Crashes) a hodnocení
- [ ] Později: balíčky (nové produkty `cz.kju.SmackAPad.pack.<id>`, v datech `access: pack:<id>`)

## Kontrolní seznam testů (před odesláním)

### Nákupy
- [ ] Čistá instalace: zdarma jen Intro + Path stupeň 1, ostatní lekce mají zámek nákupu
- [ ] Cena se zobrazuje v Kč z obchodu (žádná pevná cena v textu)
- [ ] Koupě Full: zámky zmizí hned, bez restartu
- [ ] Zrušení nákupu: žádná chyba, nic se netočí donekonečna
- [ ] Ask to Buy: hláška „čeká na schválení“, po schválení se odemkne samo
- [ ] Obnovit nákupy bez nákupu → „nenalezeny“; s nákupem → „obnoveno“; obě místa (Nastavení, nákupní okno)
- [ ] Smazat aplikaci, nainstalovat z TestFlightu, Obnovit → Full zpět
- [ ] Režim letadlo + restart → Full zůstává
- [ ] Refundace (Manage Transactions) → zámky se vrátí
- [ ] Hlášky nákupu česky i anglicky

### Release build
- [ ] V Nastavení není „Import from legacy backup“ ani diagnostika
- [ ] V aplikaci Soubory → Na iPadu → Smack-a-Pad jen to, co tam má být
- [ ] Organizer → Generate Privacy Report: UserDefaults, System Boot Time, File Timestamp
- [ ] Upload do TestFlightu bez dotazu na šifrování

### Hraní bez kontroléru (tak bude testovat Apple)
- [ ] První spuštění bez MIDI: jde hrát dotykovými pady na výšku
- [ ] Hardwarová klávesnice hraje
- [ ] Žádost o Bluetooth má srozumitelný text a odmítnutí nic nerozbije

### Robustnost
- [ ] Odpojit / připojit kontrolér během běhu (USB i Bluetooth)
- [ ] Sluchátka odpojit / připojit během běhu
- [ ] Odchod do pozadí a návrat během běhu; Ovládací centrum; budík / hovor FaceTime
- [ ] Otočení iPadu během běhu (na šířku / na výšku)
- [ ] Nejstarší dostupný iPad (min. iPadOS 17): plynulost pásu, teplota, baterie
- [ ] Zaplněná paměť iPadu (málo místa) – ukládání postupu nespadne

### Vzhled a texty
- [ ] Všechny obrazovky EN i CS, světlý i tmavý režim, žádný oříznutý text
- [ ] Ikona, spouštěcí animace, název pod ikonou
- [ ] O aplikaci: verze, odkazy fungují, kredity úplné (AVL CC BY-SA)
