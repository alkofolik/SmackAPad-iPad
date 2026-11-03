# Portrait Practice Screen Layout — Phase A Proposals

**Date:** 2026-11-03  
**Status:** Design proposals for Jakub's decision (Ticket 40 Phase A). No Swift code implemented in this phase.  
**Scope:** Portrait practice screen layout with playable 4×4 touch pads. Landscape practice layout is completely unchanged.

---

## 1. Context & Architectural Goals

The iPad app currently assumes players have an external MIDI pad controller connected, using a small, non-interactive `PadLayoutGrid` in the footer. To allow any iPad owner to practice without hardware, **portrait orientation transforms the pad grid into a primary, playable 4×4 touch surface**.

### Standing Design Constraints
1. **Three-Colour System:** Pure orange (`#FF6B00`), black (`#000000`), and white (`#FFFFFF`) with neutral system surface/secondary grays. Zero generic AI styling, zero gradients, zero skeuomorphic 3D pad buttons.
2. **Typography:** IBM Plex Sans (ticket 39) only. Bold for actions/titles, Regular for controls/data.
3. **Dominant Pattern Band:** The orange Cut Tape band remains the visual anchor of the screen, using **Band v2 Variant B** (individually rounded orange cut strips per used pad).
4. **Pad Aesthetics & Feedback:**
   - 4×4 grid in the lower reachable thumb/finger zone.
   - Each pad clearly displays its voice abbreviation (`HH`, `SN`, `KD`, `CP`, etc.).
   - Pads used in the active lesson feature an unmistakable outline (2 pt ink border).
   - Pad strike feedback uses the exact `PadFlash` mechanism (active pad illuminates in orange/verdict color and decays smoothly). No stressful per-hit micro-timing shapes.
5. **Transport & Instruments:** START / STOP / RESTART remain large (min touch height 56–64 pt) and easily reachable. Compact tempo tile from rounds 6/7.
6. **One-Touch Navigation:** Library, Listen/Play mode, From memory, view switches, legend, info, and settings remain one tap away without nested menus.
7. **Orientation Detection:** Controlled geometrically (`height > width`), automatically supporting iPadOS Stage Manager and Split View windows.

---

## 2. The Core Layout Dilemma: Pad Geometry vs Screen Height

On an iPad 11" in portrait (834 × 1194 pt):
- Inside standard page padding (24 pt), available content width is **786 pt**.
- If a 4×4 grid spans full width with 8 pt gaps, each pad is **190.5 pt wide**.
- If pads were strictly 1:1 square across that full width, the grid alone would require **786 pt in height**.
- Adding the header (~50 pt), tempo tile (~56 pt), feedback bar (~44 pt), transport (~64 pt), and layout spacing (~80 pt) would consume **1080 pt**, leaving **less than 114 pt for the pattern band**! On a 4-pad lesson, each strip would shrink below 20 pt, destroying notation legibility.

Therefore, two distinct, viable design solutions emerge:
- **Proposal 1 (Deck First):** Full-width rectangular strike pads (~1.4 : 1 aspect ratio) anchored at the very bottom edge, with the transport bar positioned above the pad grid as an ergonomic divider.
- **Proposal 2 (MPC Console):** True 1:1 square pads with lateral resting gutters, transport controls docked at the very bottom edge.

---

## 3. Proposal 1 — "Deck First" (Full-Width Playing Deck)

### Concept
The 4×4 pad deck spans the full comfortable width of the iPad display and is anchored at the very bottom edge of the screen (above the home indicator safe area). This maximizes the physical strike surface for finger drumming (index/middle fingers or thumbs).

To prevent accidental STOP presses while drumming with the palms or thumbs near the bottom edge, the **Transport Bar (START / STOP / RESTART) is positioned *above* the pad grid**, acting as a clear physical and visual boundary between the reading deck (pattern band) and the playing deck (touch pads).

### ASCII Wireframe (iPad 11" Portrait)

```
+-----------------------------------------------------------------------+  0 pt (Safe Area Top 24)
| [<- Library]  Basic 8th Rock · LEVEL 1        [Play|Listen] [*] [i]   |  Header & Tools (48 pt)
|                                                                       |
| [ 90 BPM -> 100 ] [Tempo Up Banner / Star Progress 2/3]               |  Tempo & Progress (56 pt)
+-----------------------------------------------------------------------+
|  ORANGE CUT TAPE BAND (Band v2 Variant B)                             |
|  +-----------------------------------------------------------------+  |  Pattern Band (280 pt)
|  | (1)  .   .   .  (2)  .   .   .  (3)  .   .   .  (4)  .   .   .   |  |  - Prominent orange
|  | [ HH ]          [ HH ]          [ HH ]          [ HH ]          |  |  - Separate strip
|  +-----------------------------------------------------------------+  |    for each used pad
|  +-----------------------------------------------------------------+  |  - Fixed playhead
|  |                 [ SN ]                          [ SN ]          |  |  - White hit tiles
|  +-----------------------------------------------------------------+  |  - Dynamic edge light
|  +-----------------------------------------------------------------+  |
|  | [ KD ]                          [ KD ]          [ KD ]          |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
|  [|||||||||||||||||||||||||||||||||o||||||||||||||||||||||||||||||||]  |  Timing Bar / Result (44 pt)
+-----------------------------------------------------------------------+
|  [            START / STOP (60%)           ] [  RESTART (40%)      ]  |  Transport Bar (64 pt)
+-----------------------------------------------------------------------+
|  +-------------+  +-------------+  +-------------+  +-------------+   |  4x4 Pad Grid (544 pt)
|  |     13      |  |     14      |  |     15      |  |     16      |   |  - Wide rectangular
|  |    tomHi    |  |    tomLo    |  |    crash    |  |    ride     |   |    pads (190.5 x 130 pt)
|  +-------------+  +-------------+  +-------------+  +-------------+   |  - Outline on used pads
|  +-------------+  +-------------+  +-------------+  +-------------+   |  - PadFlash illumination
|  |      9      |  |     10      |  |     11      |  |     12      |   |  - 8 pt spacing
|  |   shaker    |  |    wood     |  |   cowbell   |  |   openHat   |   |
|  +-------------+  +-------------+  +-------------+  +-------------+   |
|  +=============+  +-------------+  +-------------+  +=============+   |
|  |#     5     #|  |      6      |  |      7      |  |#     8     #|   |
|  |#   hat L   #|  |    clap     |  |     rim     |  |#   hat R   #|   |
|  +=============+  +-------------+  +-------------+  +=============+   |
|  +=============+  +=============+  +=============+  +=============+   |
|  |#     1     #|  |#     2     #|  |#     3     #|  |#     4     #|   |
|  |#  kick L   #|  |#  snare L  #|  |#  snare R  #|  |#  kick R   #|   |
|  +=============+  +=============+  +=============+  +=============+   |
+-----------------------------------------------------------------------+ 1194 pt (Safe Area Bottom 20)
```

### Vertical Space Allocation (Proposal 1)

| UI Region | iPad 11" (834 × 1194 pt) | iPad 13" (1024 × 1366 pt) | Visual & Interaction Notes |
| :--- | :---: | :---: | :--- |
| **Top Safe Margin & Padding** | 24 pt | 24 pt | Top bar breathing room |
| **Header & Quick Tools** | 48 pt | 52 pt | Library back button, lesson title, single-tap tools |
| **Instrument Row (Tempo)** | 56 pt | 60 pt | Compact TempoTile (`90 → 100 BPM`), progress counter |
| **Orange Pattern Band (v2B)** | **280 pt** | **340 pt** | Flexible height; easily accommodates 1 to 4+ strips |
| **Hit Timing / Result Bar** | 44 pt | 48 pt | Live timing bar during play; compact ResultCard on finish |
| **Transport Bar** | 64 pt | 72 pt | START/STOP + RESTART spanning full width as a boundary |
| **4×4 Touch Pad Grid** | **544 pt** | **624 pt** | 4 rows; pads are 190.5 × 130 pt (11") / 238 × 150 pt (13") |
| **Bottom Safe Margin** | 20 pt | 20 pt | Home indicator clear zone |
| **Vertical Spacing & Rules** | ~94 pt (6 × 16 pt) | ~106 pt (6 × 18 pt) | Clean separation between major blocks |
| **Total Height** | **1174 pt** / 1194 pt | **1346 pt** / 1366 pt | **Fits with 20 pt headroom. Zero scrolling.** |

---

## 4. Proposal 2 — "MPC Console" (True 1:1 Square Pads & Chassis Gutters)

### Concept
Hardware pad controllers (Akai MPD218/226, NI Maschine, Ableton Push) strictly employ **1:1 square pads**. Proposal 2 replicates this exact geometric feel by centering a 1:1 square 4×4 grid.

To provide sufficient vertical height for the dominant pattern band without crowding, the pads are sized to **140 × 140 pt** (11") and **170 × 170 pt** (13"). This leaves **101 pt lateral gutters** on iPad 11" and **133 pt lateral gutters** on iPad 13". These side margins function as natural "chassis palm rests", allowing players to anchor their wrists/palms on the iPad frame without causing stray touches.

Transport controls (START / STOP / RESTART) are docked at the **bottom edge**, preserving muscle memory from the landscape layout.

### ASCII Wireframe (iPad 11" Portrait)

```
+-----------------------------------------------------------------------+  0 pt (Safe Area Top 24)
| [<- Library]  Basic 8th Rock · LEVEL 1        [Play|Listen] [*] [i]   |  Header & Tools (48 pt)
|                                                                       |
| [ 90 BPM -> 100 ] [Tempo Up Banner / Star Progress 2/3]               |  Tempo & Progress (56 pt)
+-----------------------------------------------------------------------+
|  ORANGE CUT TAPE BAND (Band v2 Variant B)                             |
|  +-----------------------------------------------------------------+  |  Pattern Band (270 pt)
|  | (1)  .   .   .  (2)  .   .   .  (3)  .   .   .  (4)  .   .   .   |  |  - Prominent orange
|  | [ HH ]          [ HH ]          [ HH ]          [ HH ]          |  |  - Strip per used pad
|  +-----------------------------------------------------------------+  |  - Fixed playhead
|  +-----------------------------------------------------------------+  |
|  |                 [ SN ]                          [ SN ]          |  |
|  +-----------------------------------------------------------------+  |
|  +-----------------------------------------------------------------+  |
|  | [ KD ]                          [ KD ]          [ KD ]          |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
|  [|||||||||||||||||||||||||||||||||o||||||||||||||||||||||||||||||||]  |  Timing Bar / Result (44 pt)
+-----------------------------------------------------------------------+
| Palm Rest     +----------+ +----------+ +----------+ +----------+     |  4x4 Square Grid (584 pt)
| Gutter        | 13 tomHi | | 14 tomLo | | 15 crash | | 16 ride  |     |  - Strictly 1:1 square
| (~101 pt)     +----------+ +----------+ +----------+ +----------+     |    (140 x 140 pt on 11")
|               +----------+ +----------+ +----------+ +----------+     |  - Centered controller
|               |  9 shake | | 10 wood  | | 11 cowbl | | 12 opnHt |     |    deck
|               +----------+ +----------+ +----------+ +----------+     |  - Side gutters provide
|               +==========+ +----------+ +----------+ +==========+     |    rest areas for hands
|               |# 5 hat L#| |  6 clap  | |  7 rim   | |# 8 hat R#|     |
|               +==========+ +----------+ +----------+ +==========+     |
|               +==========+ +==========+ +==========+ +==========+     |
|               |# 1 kickL#| |# 2 snarL#| |# 3 snarR#| |# 4 kickR#|     |
|               +==========+ +==========+ +==========+ +==========+     |
+-----------------------------------------------------------------------+
|  [            START / STOP (60%)           ] [  RESTART (40%)      ]  |  Transport Bar (64 pt)
+-----------------------------------------------------------------------+ 1194 pt (Safe Area Bottom 20)
```

### Vertical Space Allocation (Proposal 2)

| UI Region | iPad 11" (834 × 1194 pt) | iPad 13" (1024 × 1366 pt) | Visual & Interaction Notes |
| :--- | :---: | :---: | :--- |
| **Top Safe Margin & Padding** | 24 pt | 24 pt | Top bar breathing room |
| **Header & Quick Tools** | 48 pt | 52 pt | Library, lesson title, tools |
| **Instrument Row (Tempo)** | 56 pt | 60 pt | Compact TempoTile and streak readout |
| **Orange Pattern Band (v2B)** | **270 pt** | **330 pt** | Dominant Cut Tape band (1–4+ strips) |
| **Hit Timing / Result Bar** | 44 pt | 48 pt | Timing bar during play; ResultCard on finish |
| **4×4 Touch Pad Grid (1:1)** | **584 pt** | **710 pt** | 1:1 Square pads: 140 × 140 pt (11") / 170 × 170 pt (13") |
| **Transport Bar (Bottom)** | 64 pt | 70 pt | Docked at bottom edge (familiar position) |
| **Bottom Safe Margin** | 20 pt | 20 pt | Home indicator clear zone |
| **Vertical Spacing & Rules** | ~64 pt (4 × 16 pt) | ~72 pt (4 × 18 pt) | Clean structure |
| **Total Height** | **1174 pt** / 1194 pt | **1350 pt** / 1366 pt | **Fits with 16–20 pt headroom. Zero scrolling.** |

---

## 5. Architectural & Ergonomic Comparison

| Attribute | Proposal 1: Deck First (Wide Pads) | Proposal 2: MPC Console (Square Pads) |
| :--- | :--- | :--- |
| **Pad Aspect Ratio** | Rectangular (~1.4 : 1, wide) | Strict Square (1 : 1) |
| **Pad Size on iPad 11"** | 190.5 × 130 pt (Area: 24,765 pt²) | 140 × 140 pt (Area: 19,600 pt²) |
| **Pad Size on iPad 13"** | 238 × 150 pt (Area: 35,700 pt²) | 170 × 170 pt (Area: 28,900 pt²) |
| **Hit Target Tolerance** | **+26% larger surface**. Very forgiving for fast multi-finger taps. | Matches hardware pad ergonomics (MPD/Maschine). |
| **Palm Rest Ergonomics** | Fingers rest directly at bottom edge; table/lap posture. | Dedicated 101–133 pt lateral gutters act as palm rests. |
| **Accidental Transport Hits** | **Impossible**: Transport is tucked *above* the pad deck. | Possible if palm rests heavily on the bottom START button. |
| **Pattern Band Dominance** | **Very Strong (280–340 pt)** | **Strong (270–330 pt)** |
| **Result Card Transition** | Seamlessly slots above transport without moving pads. | Slots between band and pads; transport stays pinned at bottom. |

---

## 6. Accessibility & Dynamic Type Behavior

Under iPadOS Accessibility Dynamic Type (from standard sizes up to **AX5**):

1. **Instrument Playing Surface Invariance:**
   - As established in SPEC §5 and `Theme.swift`, **musical performance elements do not expand infinitely with Dynamic Type**. If pad abbreviations (`HH`, `SN`, `KD`) grew to AX5 body sizes (50+ pt), they would overflow the pads.
   - Pad voice labels scale proportionally with pad canvas dimensions (`Theme.canvasDisplay` / `Theme.canvasText`), guaranteeing they remain crisp, perfectly centered, and never clipped.
   - VoiceOver accessibility labels independently announce the complete unclipped text (e.g. *"Bass drum, pad 1, used in lesson"*).

2. **Header and Toolbar Adaptability:**
   - At Dynamic Type > `.large`, the header switches to its existing compact two-line flow (`PracticeScreen.swift:35`).
   - The tools group flows into a single clean horizontal scroll if needed, preventing vertical layout blowout.

3. **Window Overflow Protection (The Ticket 38 Rule):**
   - If a user enables extreme accessibility sizes (AX3–AX5) where the Header and ResultCard grow substantially:
     - **The Pad Grid never shrinks below its playable size** (min pad height 100 pt).
     - **The Pad Grid never scrolls away while playing**: When total content exceeds the screen height, only the *reading section* (Header + Pattern Band + Result Card) scrolls gracefully inside a `ScrollView`, while the **Pad Grid and Transport remain pinned at the bottom**. The player never loses their physical drumming surface.

---

## 7. Recommendation for Jakub

**We recommend Proposal 1 ("Deck First").**

### Reasons:
1. **Superior Drumming Ergonomics on Glass:** Tapping a flat glass surface without tactile tactile feedback is much harder than hitting physical rubber pads. The **26% wider hit area (190.5 × 130 pt)** makes two-finger rolls (e.g. alternating index and middle fingers on the snare or hi-hat) significantly more reliable and forgiving.
2. **Accidental Press Immunity:** Placing the Transport Bar *above* the pad deck creates a natural buffer. When playing bottom-row kicks and snares, the player's palms rest naturally along the bottom bezel or table surface without any risk of accidentally slapping STOP.
3. **Visual Balance:** The screen cleanly divides into two equal functional halves: the **Upper Visual Half** (Header, Cut Tape Band, Timing feedback) and the **Lower Physical Half** (Transport boundary + 4×4 Playing Deck). Everything fits natively on both 11" and 13" iPads without any vertical compression or scrolling.
