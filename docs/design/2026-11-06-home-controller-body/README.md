# Tělo kontroleru (Home background v2) — Návrh a HTML náhled

Zdroj: Jakubovo zadání (2026-11-06) po návrzích z ticketu 114:
> *Pady sedí v desce přišroubované v rozích šrouby (nápad z C zachovat). Kolem desky grafika imitující táhla (slidery / fadery) jako na kontroleru. Barva pozadí hrubá a zrnitá, imitující plast; vítána kombinace materiálů (např. zrnitý plast těla, hladší nebo kartáčovaný kov desky, kovové šrouby). Reálný kontroler ve světlé i tmavé verzi. Z C nechci ty dvě horizontální linky dělící obrazovku na zóny.*

---

## 1. O co jde (Co to je)

Jde o **jeden ucelený a vyladěný interaktivní offline náhled (`index.html`)**, který představuje domovskou obrazovku Smack-a-Pad jako **skutečné tělo fyzického MIDI kontroleru**.

Zachovává osvědčený vzhled padů (ticket 112, proposal A s dýchající světelnou lištou Tréninku a 8pt zaoblením) a středové logo fungující jako tlačítko O aplikaci (ticket 115). Celé okolí však dostalo hmatatelný, hardwarový charakter bez jakýchkoliv rušivých či generických prvků (žádné horizontální rýhy přes celý displej, žádné neonové záře, žádné skleněné efekty).

---

## 2. Na co se dívat a jak náhled zkoušet

Otevři soubor `index.html` v libovolném běžném prohlížeči (na Macu nebo přímo na iPadu — funguje zcela offline bez internetu).

V horní liště najdeš ovládací přepínače:

1. **Vzhled (Světlý / Tmavý)**:
   - *Světlý režim*: Tělo z teplého světle šedého / smetanového ABS plastu (`#F4EFE6` / `#EBE5DA`), saténová nebo kovová deska, matné nerezové šrouby.
   - *Tmavý režim*: Tělo z jemného teplého černého plastu (paleta ticketu 92, `#1F1D1A` / `#24221E`), černěná ocel, tlumený grafitový tisk stupnic.
2. **Orientace (Na šířku / Na výšku)**:
   - *Na šířku*: 2 vertikální fadery vlevo od desky (CH 01, 02) a 2 fadery vpravo (CH 03, 04). Rámování je dokonale vyvážené.
   - *Na výšku*: Všechny 4 kanály faderů se čistě přesunou pod desku s pady do vodorovné řady, kde vyplňují prostor nad spodním okrajem.
3. **Zrnitost těla (Jemné / Výrazné / Vypnuto)**:
   - *Jemné* (výchozí doporučené): Přirozený matný povrch ABS plastu s mikroskopickou texturou.
   - *Výrazné*: Hrubší, znatelnější struktura jako u robustních studiových mašin nebo rackových panelů.
   - *Vypnuto*: Zcela hladká plocha bez textury pro posouzení rozdílu.
4. **Fadery (ZAPNUTO / VYPNUTO)**:
   - Umožňuje okamžitě posoudit tělo kontroleru s ozdobnými táhly i čistě minimalistickou variantu pouze se šroubovanou deskou.
   - Kanál CH 03 nese na jezdci tenký oranžový akcent v barvě aplikace (`#FF6B00`).
5. **Materiál desky (Satén / Broušený kov)**:
   - *Satén*: Hladký, hedvábně matný polykarbonát / elox s jemným přechodem světla.
   - *Broušený kov*: Horizontální vlasové broušení (brushed aluminum / gunmetal) s kovovým leskem v hraně úkosu.
6. **Pozadí (ZAPNUTO / VYPNUTO)**:
   - Okamžité srovnání s dosavadním holým pozadím bez desky, šroubů i textur.
7. **Detaily šroubů v rozích**:
   - V rozích desky sedí 4 kovové šrouby. Každý je natočen pod jiným úhlem (–24°, 51°, 108°, –63°), takže nevypadají jako strojově nakopírované razítko, ale jako reálně utažené šrouby.
8. **MIDI simulace a odezva padů**:
   - Kliknutím přímo na pady nebo klávesami `1`–`8` na klávesnici (případně tlačítky MIDI v liště) vyzkoušíš fyzický stisk padu do lůžka, blesk a odskočení.

---

## 3. Recept na stavbu ve SwiftUI a náročnost (Asset sizes)

Celý návrh je promyšlený tak, aby šel ve SwiftUI implementovat mimořádně úsporně, s nulovou zátěží procesoru během hraní:

| Vrstva | Způsob implementace ve SwiftUI | Assety & Velikost | Výpočetní náročnost |
|---|---|---|---|
| **1. Plastové tělo + vinětace** | Základní `LinearGradient` a `RadialGradient` z barev v `Theme.swift`. | 0 KB (čistý kód) | Zanedbatelná (statické) |
| **2. Zrnitost plastu (speckle/grain)** | Jedna malá bezešvá dlaždice šumu 128×128 px dlaždicovaná přes `Image(..., resizingMode: .tile)` nebo jednorázový render do bitmapy přes `Canvas`. | **1 PNG dlaždice cca 10–12 KB** | 0 % CPU/GPU per frame (statická texturová vrstva) |
| **3. Centrální deska (bay plate)** | `RoundedRectangle(cornerRadius: 16)` s výplní `LinearGradient`, okrajem `strokeBorder` a statickým stínem `.shadow()`. Pro broušený kov jednoduchý opakovaný přechod nebo tenká textura (~8 KB). | 0 KB (satén) až 8 KB (kov) | 0 % CPU/GPU per frame |
| **4. Kovové šrouby (4 ks)** | Jeden vektorový asset (SVG nebo SwiftUI `Path` / SF Symbol) vykreslený 4× v rozích s různým `.rotationEffect(.degrees(...))`. | **1 vektorový asset cca 1 KB** | Statické |
| **5. Fadery a stupnice** | Statické SwiftUI tvary: `Capsule` (drážka), `Rectangle` s jemným stínováním (jezdec), `VStack` s textem popisek a dílků stupnice. | 0 KB (čisté SwiftUI tvary a texty) | Statické |
| **Celkem za všechny vrstvy** | — | **cca 11–20 KB celkem** | Žádné per-frame animace pozadí, plně kompatibilní s Reduce Motion. |

---

## 4. Ověření kontrastu textů (WCAG AA & AAA)

Žádný z grafických prvků pozadí nezasahuje pod texty na padech. Pady mají vlastní neprůhledná lůžka i těla. Přesto jsme změřili a ověřili kontrast všech textů na padech v obou režimech:

- **Světlý režim (Light / Cream)**:
  - Běžný titulek padu (`#1F1D1A` na ploše `#EBE5DA`): **13,41 : 1** (vysoko nad přísnou normou AAA 7,0:1).
  - Běžný podtitulek padu (`#5E5950` na ploše `#EBE5DA`): **5,55 : 1** (překračuje normu AA 4,5:1).
  - Titulek oranžového padu Pokračovat (`#1F1D1A` na `#FF6B00`): **5,89 : 1** (překračuje AA 4,5:1 i normu pro velký text 3,0:1).
  - Podtitulek oranžového padu Pokračovat (`#1F1D1A` s krytím 85 % na `#FF6B00`): **4,73 : 1** (překračuje normu AA 4,5:1).
  - *Nejslabší kontrast v celém světlém režimu je 4,73 : 1, což bezpečně splňuje WCAG AA.*

- **Tmavý režim (Dark / Soft Black)**:
  - Běžný titulek padu (`#F4EFE6` na ploše `#2A2824`): **12,85 : 1** (vysoko nad normou AAA 7,0:1).
  - Běžný podtitulek padu (`#B3ADA2` na ploše `#2A2824`): **6,60 : 1** (výrazně nad normou AA 4,5:1).
  - Titulek oranžového padu Pokračovat (`#1F1D1A` na `#FF6B00`): **5,89 : 1** (překračuje AA 4,5:1).
  - Podtitulek oranžového padu Pokračovat (`#1F1D1A` s krytím 85 % na `#FF6B00`): **4,73 : 1** (překračuje AA 4,5:1).
  - *Nejslabší kontrast v celém tmavém režimu je 4,73 : 1, což rovněž bezpečně splňuje WCAG AA.*

---

## 5. Otevřené otázky pro Jakuba

1. **Materiál desky**: Vyhovuje ti více saténový eloxovaný polykarbonát (klidnější, čistší), nebo broušený kov (výraznější hardware charakter s lehkými vlasovými linkami)?
2. **Rozložení faderů**: Působí rozvržení 2 vlevo + 2 vpravo na šířku a 4 pod deskou na výšku přirozeně a vyváženě?
3. **Síla zrnitosti těla**: Vyhovuje výchozí jemné zrno, nebo bys preferoval výraznější texturu ABS plastu?
