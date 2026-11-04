# Smack-a-Pad — Home Screen Design Proposals (Ticket 60)

Status: proposals ready for Jakub's decision. Source: Jakub, 2026-11-03. Follow-up: ticket 61 (implementation) is written after Jakub chooses a proposal.

> [!NOTE]
> This ticket delivers **design proposals and interactive offline previews only**. No application code, asset catalogs, or project settings have been modified.

---

## 1. Quick Review Links

Open any of these files directly in your web browser locally (no web server, no network connection required; font is embedded, SVGs are self-contained):

| File | Concept | Tagline | Main Tradeoff & Character |
|---|---|---|---|
| [**index.html**](index.html) | **Srovnání & Přehled** | Comparative Workbench | Side-by-side parameter comparison and direct links to all three proposals. |
| [**proposal-a.html**](proposal-a.html) | **Návrh A / Padová matice** | "The logo is the menu" | The 4 pads of the logo expand to become the 4 main tactile buttons: Orange Smack Pad = Pokračovat/Začít, 3 Black Pads = Knihovna, Úvodní cvičení, Nastavení. |
| [**proposal-b.html**](proposal-b.html) | **Návrh B / Master řádky** | "Hardware Front Panel" | *(Recommended)* Industrial rack layout. Logo sits proud at the top; massive, left-aligned typographic action rows (height 94 pt and 74 pt) give immediate legibility from arm's length. |
| [**proposal-c.html**](proposal-c.html) | **Návrh C / Studio Console Split** | "Asymmetric Station & Dispatch" | Two-column split (40% Station / 60% Action Dispatch) in landscape; stacked in portrait. Dedicated MIDI controller hardware monitor with latency calibration. |

Every preview includes:
- **Landscape (1194×834)**, **Portrait (834×1194)**, and **Side-by-Side (Obě)** orientation switcher.
- **Returning Player** (Pokračovat · 04 · Funk 16ths · ★★★ · Akai MPD218) vs **First Run** (Začít · 01 · První úder · Připoj ovladač).
- **Light (Cream #F2F0EA)** vs **Dark (Black #111111)** appearance switcher.
- **Reduce Motion** toggle (smooth 0.25 s crossfade, zero motion).
- **Replay** button to re-run cold start sequence from the empty cream launch screen.
- **Tap anywhere on screen to skip** immediately to the settled home screen.
- **Tactile feedback toasts** when tapping any button, showing what action is triggered in the app.

---

## 2. Storyboards with Timings

Total animation time until the menu is fully usable is **3.1–3.2 s** (stretched calmly from ticket 46's 1.6 s). Menu items become tappable as soon as they appear.

### Universal Launch Sequence (First 1.5 s)

All three proposals share the exact cold-start build sequence established in ticket 46, ensuring brand continuity from the solid cream `#F2F0EA` launch screen:

| Time | Action | Visual details |
|---|---|---|
| **0.00–0.05 s** | Static start | Empty cream screen `#F2F0EA` (matches static launch screen, zero flash). |
| **0.05–0.45 s** | Three black pads pop | Pad 1 (top-left) pops at 0.05 s, Pad 2 (bottom-left) at 0.21 s, Pad 3 (bottom-right) at 0.37 s. Spring scale 0.4 → 1.0, opacity 0 → 1. |
| **0.65–0.78 s** | Orange pad smacks in | Orange pad drops from above (`offsetY: -50px`, scale 1.35 → 1.0) and settles at 12° with one slight overshoot. |
| **0.78–0.91 s** | Impact bounce | Three black pads give a subtle 2 pt downward bounce upon impact and settle back. |
| **1.10–1.45 s** | Wordmark rises | The outlined vector wordmark "Smack-a-Pad" fades in and rises 12 pt into place below the pads. |

---

### Proposal-Specific Settling & Menu Reveal (1.50–3.10 s)

#### Proposal A: Padová matice (Pad Matrix)
| Time | What happens |
|---|---|
| **1.50–2.20 s** | The 4 pads of the logo expand smoothly in place into large tactile touch pads (180×180 pt each). |
| **2.20–2.70 s** | Labels stagger onto the pads (0.08 s apart): Hero orange pad reveals "POKRAČOVAT" (or "ZAČÍT") + lesson title + stars; top-left reveals "KNIHOVNA"; bottom-left reveals "ÚVODNÍ CVIČENÍ"; bottom-right reveals "NASTAVENÍ". Each is immediately tappable! |
| **2.70–3.10 s** | Top status bar (Controller chip with green LED, Progress chip) and bottom bar (Calibration shortcut, About line) fade in. |
| **3.10 s** | Home screen completely settled. |

#### Proposal B: Master řádky panelu (Hardware Front Panel)
| Time | What happens |
|---|---|
| **1.50–2.00 s** | The assembled logo glides upward and anchors into the top-left brand position, scaling slightly to 0.85. |
| **2.00–2.60 s** | Master action rows slide up from below with crisp ease-out (0.10 s stagger): Row 1 ("POKRAČOVAT", height 94 pt) at 2.00 s; Row 2 ("KNIHOVNA", height 74 pt) at 2.12 s; Row 3 ("ÚVODNÍ CVIČENÍ" & "NASTAVENÍ", height 70 pt) at 2.24 s. |
| **2.60–3.10 s** | Hardware cluster (Controller chip with live LED dot, Latency calibration shortcut, Progress ratio) settles in the header. |
| **3.10 s** | Home screen completely settled. |

#### Proposal C: Studio Console Split
| Time | What happens |
|---|---|
| **1.50–2.10 s** | In landscape: Logo shifts leftward to anchor the Station Column (40% width). In portrait: Shifts upward into top header. |
| **2.10–2.80 s** | Right Action Dispatch column elements slide in from the right: Giant Hero Practice Card (height 150 pt) at 2.10 s; Library and Intro tiles at 2.25 s. |
| **2.60–3.20 s** | Hardware monitor card (Controller status, channel info, calibration button) and Progress card fade in on the Station side. |
| **3.20 s** | Home screen completely settled. |

*Reduce Motion for all proposals*: 0.00–0.25 s smooth opacity crossfade directly from cream to the settled home screen. Zero position or scale movement.

---

## 3. Proposal Profiles & Secondary Items

### Proposal A: Padová matice ("The logo is the menu")
- **Concept**: Maximum brand cohesion. The four pads of the logo are the menu.
- **Secondary items kept**:
  - **Úvodní cvičení**: Elevated to one of the 4 primary pads (bottom-left). Warm-up shortcut for returning players; essential starting point for new players.
  - **Ovladač**: Dedicated tactile chip in top header (`[● AKAI MPD218]` with green LED, or `[○ Připoj ovladač]` with amber LED), height 48 pt. Tapping opens Settings (Hardware section).
  - **Kalibrace**: Direct shortcut chip in bottom bar (`⏱ Kalibrace latence (1.2 ms)`), height 48 pt.
  - **Pokrok**: Quiet stat line in top bar (`★ 42 / 216`).
  - **Plná verze**: Optional chip in bottom utility strip if locked content exists.
  - **O aplikaci**: Quiet one-line footer at bottom right.
- **SwiftUI mapping**:
  ```swift
  // LaunchAnimationView pads morph with matchedGeometryEffect(id:in:) directly into PadButton views
  ```

### Proposal B: Master řádky panelu ("Hardware Front Panel") — *RECOMMENDED*
- **Concept**: Typographic industrial instrument front plate (inspired by Roland, vintage Akai, and Braun). Ultra-clean hierarchy, zero decorative fluff.
- **Secondary items kept**:
  - **Úvodní cvičení**: Integrated as an equal tactile action row alongside Nastavení (height 70 pt).
  - **Ovladač**: Pinned directly beside the brand anchor as a hardware monitor chip with green/amber LED dot.
  - **Kalibrace**: Direct button right next to the controller chip (`⏱ Kalibrace (1.2 ms)`), solving the problem of calibration being buried.
  - **Pokrok**: Progress chip in header (`★ 42 / 216`) plus total completed lessons in footer (`14 z 72 lekcí hotovo`).
  - **Plná verze**: Banner / chip when locked content exists.
  - **O aplikaci**: Subtle footer line at the bottom.
- **SwiftUI mapping**:
  ```swift
  // HomeScreen animates the logo to .topLeading via matchedGeometryEffect, while MasterRow components stagger in via VStack with offset/opacity transitions
  ```

### Proposal C: Studio Console Split ("Asymmetric Station & Dispatch")
- **Concept**: Professional audio workstation layout (similar to Ableton Push or standalone MPC). Distinct zones: "My Station & Setup" on the left vs "Practice & Play Dispatch" on the right.
- **Secondary items kept**:
  - **Úvodní cvičení**: Large dedicated action tile in the dispatch column (height 110 pt).
  - **Ovladač**: Full Hardware Monitor card with device name, connection protocol (USB/Bluetooth), MIDI channel, and embedded calibration button.
  - **Kalibrace**: Prominent button inside the Hardware Monitor card.
  - **Pokrok**: Dedicated card in the Station column with large score (`42 / 216 ★`).
  - **Nastavení**: Dedicated full-width button in the Station column.
  - **O aplikaci**: Footer in the station column.
- **SwiftUI mapping**:
  ```swift
  // Responsive container (HStack in landscape, VStack in portrait) with matchedTransition and spring-animated column reveals
  ```

---

## 4. Background Recommendation: Cream in Both Appearances

Ticket 60 asks to decide and show what the home background is:
1. **Cream in both appearances (`#F2F0EA`)** *(Recommended)*
2. **Adaptive: Cream in light, Black (`#111111`) in dark**

### Why we recommend Cream in both appearances:
1. **Zero-flash continuity from launch**: The static launch screen required by ticket 46 is solid cream `#F2F0EA` in both light and dark modes (to prevent iOS system flashes). The launch animation runs on cream. If the Home screen is cream, the animation settles **seamlessly with zero background shift or crossfade**.
2. **Physical instrument chassis feel**: Vintage and modern hardware instruments (Akai MPC 2000XL, E-mu SP-1200, Roland TR-808) have a distinct physical casing color (cream/beige/grey) with high-contrast pads and orange triggers. The home screen feels like the instrument itself sitting on your desk.
3. **Intentional contrast between "Instrument Home" and "Practice Arena"**: Entering a lesson transitions into the focused dark/light practice arena with the vivid orange playband. This creates an unmistakable psychological shift between app navigation and active playing.
4. **Adaptive Dark Mode is still fully supported**: For users who play on dark stages or in dim studios and prefer a fully dark home screen, the dark variant (deep `#111111` background, cream pads `#F2F0EA`, orange smack pad) is completely designed and functional in all our previews (toggle with the "Vzhled" switch).

---

## 5. Recommendation of One Proposal

### **We recommend Proposal B (Master řádky panelu / Hardware Front Panel)**.

**Reasons**:
1. **Ergonomics at arm's length**: The iPad sits on a stand or table beside an external MIDI drum controller. The player's eyes are mostly on the physical drum pads. Proposal B's large, full-width typographic master rows (height 94 pt and 74 pt) are instantly recognizable and operable with a casual glance from 1.5 to 2 meters away.
2. **Unmistakable primary call to action**: The orange "POKRAČOVAT" row is impossible to miss. It clearly presents the next lesson name ("04 · Funk 16ths"), the user's star rating (`★★★`), and tempo (`96 BPM`). On first launch, it seamlessly shifts to "ZAČÍT" ("01 · První úder").
3. **Tactile hardware aesthetic without gimmicks**: Adheres 100% to the anti-slop rules of `DESIGN-BRIEF.md`. No purple glow, no blur cards, no fake 3D, no generic icons. Pure typographic precision using the app's bundled IBM Plex Sans font.
4. **Hardware status clarity**: A finger drummer needs to know immediately whether their MIDI controller is connected. Proposal B places a high-visibility LED chip (`● AKAI MPD218` in green, or `○ Připoj ovladač` in amber) right next to the brand anchor, along with a direct one-tap shortcut to latency calibration.

*Alternative*: If Jakub wants the most playful, iconic brand expression, **Proposal A** is the runner-up because tapping the physical smack pad of the logo to launch practice is uniquely satisfying.

---

## 6. Open Questions for Jakub

1. **Background appearance**: Do you agree with keeping the cream background `#F2F0EA` in both Light and Dark modes on the Home screen (for seamless continuity with the static launch screen and a physical instrument chassis feel), or do you want the Home screen to turn deep black (`#111111`) when dark mode is enabled?
2. **Proposal preference**: Do you prefer the bold typographic rows of **Proposal B**, the direct pad interactivity of **Proposal A**, or the two-column workstation split of **Proposal C**?
3. **Latency calibration shortcut**: All three proposals elevate Latency Calibration to a direct shortcut on the home screen (previously buried in Settings → Hardware). Do you want it always visible, or only when an external controller is connected?
4. **Haptic feedback (iPad)**: When tapping the primary "Pokračovat" or "Začít" button on iPad, should we trigger a tactile impact haptic (`UIImpactFeedbackGenerator(style: .medium)`)?
