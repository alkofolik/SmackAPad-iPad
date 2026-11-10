# Practice Screen: Timing Cue, Run Progress & Focus Mode — Design Proposal (Ticket 164)

**Status:** Design proposal ready for Jakub's decision. Approved for design phase on 2026-11-10.  
**Deliverable:** Design document and visual previews in `docs/design/previews/164/`.  
**Next step:** Jakub picks the preferred variants for Timing Cue (B) and Run Progress (C), and approves the Focus Mode rules (D). Implementation follows as **Ticket 165** (zero Swift app code modified in this ticket).

---

## 1. Executive Summary & Design Goals

During live finger-drumming practice on the iPad, the player’s visual attention must remain anchored to two physical focal planes:
1. **The physical MIDI drum pads** under their fingers.
2. **The orange rhythm band** displaying oncoming sixteenth-note hits, active voice lanes, and the audio-locked playhead.

Feedback from Jakub identified four friction points in the current practice screen:
- **Problem 1 (`HitTimingBar`):** The thin live line with per-hit tick marks above the band (`PracticeScreen.swift` ~515) is completely useless during drumming. The player cannot and does not look at microsecond ticks while playing.
- **Problem 2 (Timing tendency readout):** The rushing/dragging indication is valuable, and its position is good. However, displaying numeric text (`Early 25 ms` / `Late 15 ms`) is visually loud, uncalm, and outdated. A modern, discreet visual motion cue is needed.
- **Problem 3 (Run progress & star rules):** The current `LapVaultView` (`PracticeInstruments.swift` 486) sits in the right place, but during a session the drummer does not know: which star is currently being pursued, how many qualifying runs are required vs. banked, how far along the current run is, or how Learning vs. Challenge mode behaves when a pass succeeds or fails.
- **Problem 4 (Screen clutter):** Static chrome (back-to-library, title/subtitle, playback mode switch, static/scrolling tools, info, legend, settings, and large stopped tempo button) crowds the screen during drumming, competing for visual priority.

### Core Design Solutions
- **A. Remove `HitTimingBar`** from the practice screen entirely. Retain `HitTimingPlot` exclusively in the post-run "Detail" sheet for calm post-mortem diagnostic analysis.
- **B. Modern Timing Cue:** A calm, spring-damped micro-indicator (no numbers, smoothed over a 6–8 strike rolling window) showing whether the groove is rushing (ahead / left), centered (on time), or dragging (behind / right).
- **C. Segmented Star Progress HUD:** A crystal-clear hardware-inspired progress track showing the target star (`★ 1` or `★ 2`), banked runs, live filling of the active run, and unambiguous mode behavior (Learning holds banked runs on error; Challenge breaks the chain and empties all segments).
- **D. Drumming Focus Mode:** Upon pressing START (as the 4-beat count-in begins), all non-drumming chrome smoothly fades out (0.25 s ease-out). The band remains **100% stationary** (no layout jump), anchored between the live Performance HUD (BPM + Timing Cue + Run Progress) and the essential drumming controls (Pad Flash Grid + STOP/RESTART).

---

## 2. Part A: Removal of `HitTimingBar` & Purpose of `HitTimingPlot`

### Decision on `HitTimingBar`
- **Removal from `PracticeScreen.swift`:**
  - `HitTimingBar` is eliminated from the active practice screen.
  - *Why:* Live drumming at 60–180 BPM demands peripheral pattern recognition. Per-hit ticks produce rapid optical flicker that creates cognitive fatigue without delivering actionable guidance. Removing it cleans up the middle screen zone, simplifies SwiftUI layout evaluation, and eliminates visual noise.

### Retention of `HitTimingPlot` in Detail View
- **Retained in `sessionResultsView(summary)` (`PracticeScreen.swift:1128`):**
  - *Purpose:* When the run stops, the player enters an analytical mindset. `HitTimingPlot` plots the last 32 hits on a static coordinate canvas (error in milliseconds vs. chronological hit index, framed by the target timing window).
  - *Diagnostic Value:* It answers questions that cannot be processed while drumming:
    - *"Was I consistently rushing the snare on beats 2 and 4?"*
    - *"Did my timing drift late when the tempo stepped up from 90 to 100 BPM?"*
    - *"Were my errors random jitters or a systematic bias?"*
  - Because it is viewed only after playback has stopped, it provides deep pedagogical value with zero live distraction.

---

## 3. Part B: Timing Cue Proposals (Rushing / Dragging)

### Architectural Alignment: Timing Cue vs. `BandEdgeGlow`
Currently, `BandEdgeGlow` (`PatternField.swift:190`) renders a white gradient on the band edge (right edge for rushing, left edge for dragging).
- **The Conflict:** On standard timelines, tuners, and coordinate systems, early/ahead is negative time delta ($\Delta t < 0$, to the **left** of zero), while late/behind is positive time delta ($\Delta t > 0$, to the **right** of zero). Having the right edge of the band glow for early is counter-intuitive. Furthermore, having two separate indicators (an edge glow and a HUD cue) divides peripheral attention.
- **Recommendation:** **Retire `BandEdgeGlow` as the primary indicator.** Let the new calm Timing Cue in the top HUD be the single, authoritative source of groove tendency. (If desired, `BandEdgeGlow` can remain an opt-in ambient setting in Settings > Display, but by default it is turned off to keep the orange pattern field completely pure).

---

### Timing Cue Variants

```
                AHEAD (Rushing)          ON TIME (Centred)         BEHIND (Dragging)
                 Left (-ms)                  Center (0)                Right (+ms)

Variant B1:     [  ●    |       ]        [      |●|      ]        [       |    ●  ]
(Gliding Pip)

Variant B2:     [ ═══|          ]        [       |       ]        [          |═══ ]
(Whisper Bar)

Variant B3:        ▼                       ▼                           ▼
(Rim Pip)       ━━━━━━━━|━━━━━━━━        ━━━━━━━━|━━━━━━━━        ━━━━━━━━|━━━━━━━━
                [ Orange Band ]          [ Orange Band ]          [ Orange Band ]
```

#### Variant B1: The Gliding Horizon Pip *(Recommended)*
- **Anatomy:** A 88×16 pt recessed surface capsule (`Theme.surface`) with a fine 1.5×10 pt center notch and a subtle ±12 ms deadband guide. A 8×10 pt capsule pip glides smoothly left and right.
- **Temporal Convention:**
  - **Ahead / Rushing ($\Delta t < 0$):** Pip glides softly to the **left** of the center notch.
  - **On Time (within ±12 ms / 40% of good window):** Pip settles dead-center over the notch and displays `Theme.orange` (or steady `Theme.ink`).
  - **Behind / Dragging ($\Delta t > 0$):** Pip glides softly to the **right** of the center notch.
- **Damping & Filtering:** Uses the median error from `session.timingHistory` over the last 6–8 strikes with an exponential moving average and a soft spring (`response: 0.35, dampingFraction: 0.78`). Zero per-hit flicker; it floats with the drummer's pocket.
- **Why it works:** Resembles precision synthesizer pitch-wheel centers and hardware groove checkers (e.g. Roland TD-series Time Check). Completely intuitive.

#### Variant B2: The Split Whisper Bar (Bipolar Balance Wing)
- **Anatomy:** A minimal 2×12 pt center dividing line. When timing drifts, a whisper-thin 3 pt horizontal bar expands outward from the center divider.
- **Behavior:**
  - Ahead (Rushing): Bar extends leftward from the center divider in `Theme.orange`.
  - Behind (Dragging): Bar extends rightward from the center divider.
  - On Time: Wings retract completely into the center tick; a tiny 6×6 pt dot rests at the baseline.
- **Why it works:** Inspired by broadcast stereo phase correlation meters and Studer console balance needles. Extremely calm and discreet.

#### Variant B3: Integrated Band-Rim Pip (Direct Edge Needle)
- **Anatomy:** Zero extra HUD footprint. The timing indicator is built directly into the top edge of the orange band. A small 8×6 pt chevron/pip travels along the top hairline rim relative to a white center notch on the band.
- **Behavior:** Pip shifts left when rushing, locks on the center notch when on time, and shifts right when dragging.
- **Why it works:** Eliminates eye travel entirely—the drummer's peripheral gaze is already locked onto the top of the pattern band.
- **Trade-off:** Sits very close to the top lane of sixteenth-note hits (often Hi-Hat), which can cause visual collision on dense 4-bar patterns.

---

## 4. Part C: Run Progress Proposals (Toward Stars)

### Mapping to Existing Session & Scoring Data
The new run-progress indicator strictly uses data already published by `PracticeSession`:
- **Target Star Index:** `starRunProgress.starIndex` (0 = Star 1 / Passed; 1 = Star 2 / Goal tempo).
- **Required Qualifying Runs:** `starRunProgress.required` (calculated by `StarStreak.requiredRuns(expectedHits:)`, typically 1 to 4 runs depending on lesson density and intro status).
- **Banked Runs:** `starRunProgress.count` (`starStreak.passedRuns` or `starStreak.masteryRuns`).
- **Live Run Completion:** Continuous progress fraction $f \in [0.0, 1.0]$ derived from host audio clock:
  $$f = \frac{\text{elapsedSteps}}{\text{repeatsPerRun} \times \text{lesson.bars} \times 16}$$
- **Mode Dynamics (`practiceMode`):**
  - **Learning Mode:** Banked runs are permanent credits saved in progress. If a run fails, banked segments remain filled; only the active segment recoils and empties.
  - **Challenge Mode:** Consecutive clean runs are required. If a run fails, the streak resets to 0; all segments empty simultaneously.

---

### Run Progress Variants

```
Variant C1: Segmented Vault Rail (Recommended)
[★ 1]  [ ████████ ] [ ████░░░░ ] [ ░░░░░░░░ ]
       Banked Run 1  Run 2 Live 50%  Run 3 Pending

Mode Failure Dynamics (C1):
Learning:    [★ 1]  [ ████████ ] [ ⌂ recoil ] [ ░░░░░░░░ ]  --> Banked 1 is safe!
Challenge:   [★ 1]  [ ░ drain  ] [ ░ drain  ] [ ░░░░░░░░ ]  --> Streak broken, resets to 0!


Variant C2: Stepped LED Block Meter
[★ 2]  [ █ ] [ ▄ ] [   ]   --> 3 vertical blocks; 1 banked, 2nd filling live
       [ █ ] [ ▄ ] [   ]
       [ █ ] [   ] [   ]


Variant C3: Minimalist Star-Linked Bead Track
[★ 1]  ──( ● )───( ◑ )───( ○ )──   --> Bead 1 solid, Bead 2 filling clockwise
```

#### Variant C1: Segmented Vault Rail *(Recommended)*
- **Structure:**
  - Left: Target star badge (`★ 1` or `★ 2`) in a compact pill (`Theme.surface`).
  - Right: A horizontal sequence of `required` discrete chamber slots (each 28×10 pt with 4 pt gap).
- **States & Live Animation:**
  - **Banked Runs:** Solid `Theme.ink` fill.
  - **Active Run:** Fills smoothly from left to right as sixteenth notes elapse across the pattern. If a run is 4 bars long, each bar completed fills 25% of the slot.
  - **Pending Runs:** Unfilled slot with subtle 1 pt hairline outline.
  - **Clean Pass Completed:** The slot reaches 100% and locks into place with a subtle 0.15 s snap.
  - **Failed Run in Learning Mode:** Banked slots remain locked. The filling slot flashes a gentle secondary outline and drains to empty (0.20 s easeOut).
  - **Failed Run in Challenge Mode:** The entire rail flashes `Theme.markWrong` for 0.20 s; all slots drain back to zero together. The broken streak is instantly understood without text.

#### Variant C2: Stepped LED Meter (Block Gauge)
- **Structure:** Chunky rackmount-style vertical LED block modules. Each required run is represented by a vertical block containing 3 micro-steps (corresponding to lesson phrase subdivisions).
- **Behavior:** The active block fills upward in micro-steps. Banked blocks remain fully illuminated.
- **Why it works:** Evokes classic Akai MPC and Roland hardware sequencer meters.
- **Trade-off:** Takes slightly more vertical height (24 pt) than the slim horizontal rail.

#### Variant C3: Minimalist Star-Linked Bead Track
- **Structure:** A continuous hairline rail with circular bead nodes (14×14 pt).
- **Behavior:** The active bead fills with a radial sweep (like an Apple Watch activity ring). When the run qualifies, the bead turns solid.
- **Why it works:** Modern and ultra-clean.
- **Trade-off:** Radial sweep in small 14 pt circles is harder to read with peripheral vision than a directional horizontal bar.

---

## 5. Part D: Drumming Focus Mode Specification

### The Principle: What Hides vs. What Stays

When the drummer taps **START** (or hits a mapped MIDI start pad), their cognitive mode shifts from **Setup / Selection** to **Rhythmic Execution**. Focus mode clears all peripheral noise while ensuring that critical monitoring and safety controls remain 100% accessible.

```
+-----------------------------------------------------------------------------------+
|  [FADED OUT] Library, Title, Play/Listen, Tools, Help, Volumes                     |
|                                                                                   |
|  [PERFORMANCE HUD]  [ 90 BPM ]          [  ●  ] Timing Cue        [★ 1] [██][░░]  |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|                      ORANGE PATTERN BAND (STATIONARY)                             |
|             HH  [■]   [■]   [■]   [■]   [■]   [■]   [■]   [■]                     |
|             SN        [■]               [■]               | (Playhead)            |
|             KD  [■]         [■]   [■]                     |                       |
|                                                                                   |
+-----------------------------------------------------------------------------------+
|  [PAD FLASH GRID]                      [OPEN CHASSIS]          [TRANSPORT SQUARE] |
|  [■][■][■][■]                                                  +----------------+ |
|  [■][■][■][■]                                                  |      STOP      | |
|  [■][■][■][■]                                                  |----------------| |
|  [■][■][■][■]                                                  |    Restart     | |
|  (Lights hits live)                                            +----------------+ |
+-----------------------------------------------------------------------------------+
```

### 1. Elements That Fade Out
- **Top Bar Left:** `libraryButton` ("Library" / "Today" / "Training" back button).
- **Top Bar Center:** `titleAndSubtitle` (lesson title, category, level difficulty dots, subtitle).
- **Top Bar Right:**
  - `modeButtons` (Listen / Play / After me segment).
  - `patternTools` (From memory toggle, Static / Scrolling toggle).
  - `helpTools` (Info popover button, Legend button, Help '?' deck button, More tools / settings).
- **Bottom Zone Center:**
  - `tempoSquare` (The large 120×120 pt editable BPM button and popover). While running, tempo cannot be manually edited anyway; keeping a large interactive square there is visual deadweight.

### 2. Elements That Stay Visible (The Live Performance HUD)
1. **Orange Rhythm Band (`PatternField`):**
   - Keeps full height, pattern notation, 60 fps playhead, count-in numerals, and bar brackets.
2. **Minimal Performance HUD Strip (above band):**
   - **Left:** Compact, calm BPM readout (e.g. `90 BPM`, 22 pt medium text).
   - **Center:** Timing Cue (Variant B1: Gliding Pip).
   - **Right:** Run Progress (Variant C1: Segmented Vault Rail).
3. **Pad Layout Grid (`PracticePadLayoutSquare`):**
   - Stays in bottom-left corner. Lights up in orange/white whenever physical or screen pads are struck. Vital visual verification that MIDI input is working. (Still hideable via Settings > Show pads).
4. **Transport Controls (`transportSquare`):**
   - Stays in bottom-right corner. Shows large **STOP** button (top 58%) and **RESTART** button (bottom 36%). Minimum touch target > 56 pt.
5. **Dynamic Overlays & Announcements:**
   - 4-beat count-in numerals (`CountInNumeral`).
   - Mid-lesson Star Moment beam (`StarBurst` / `starMomentBeamActive`).
   - Tempo-up banner (`TempoUpBanner`).
   - Badge earned banner (`BadgeBanner`).

### 3. Transition Timing & Motion Rules
- **START Pressed (Activation):**
  - Count-in begins.
  - Fading chrome transitions: `opacity: 1 → 0` using `Theme.Motion.standard` (**0.25 s ease-out**).
  - Controls are set to `.allowsHitTesting(false)` and `.accessibilityHidden(true)`.
- **STOP Pressed or Run Completed (Deactivation):**
  - Playback stops; summary or normal state appears.
  - Chrome transitions: `opacity: 0 → 1` using `Theme.Motion.standard` (**0.25 s ease-out**).
  - Full interaction immediately restored.
- **Reduce Motion Active:**
  - Zero spatial movement or resizing.
  - Plain opacity cross-fade of **0.15 s** (or instant cut).
- **MIDI Transport:**
  - External MIDI hardware controls (MIDI Start/Stop CC or MMC, pad hits) remain 100% active throughout.

### 4. Layout Architecture: Stationary Band vs. Expanding Band
Jakub asked: *"The layout must not jump: the band keeps its size and place, or grows smoothly into the freed space; propose which."*

| Criterion | Option 1: Stationary Band *(RECOMMENDED)* | Option 2: Smoothly Expanding Band |
| :--- | :--- | :--- |
| **Visual Anchoring** | **Perfect.** Band does not move by even 1 pixel when START is tapped. Eye position remains locked. | **Disruptive.** Band moves and expands vertically right as count-in starts, forcing eye refocus. |
| **Audio Clock & 60 fps Safety** | **Zero risk.** Geometry is pre-calculated. No canvas resizing during time-critical audio start. | **Risk of dropped frames.** Resizing a live Canvas and recalculating note positions at audio start. |
| **Chassis Feel** | Creates calm, balanced negative space around the active elements (authentic hardware feel). | Fills screen edge-to-edge, feeling cramped and dense again. |
| **Recommendation** | **Adopt Option 1.** Spatial stability is essential for rhythmic performance. | Reject. |

---

## 6. Preview Catalog (Rendered PNGs)

All preview images have been rendered using the app’s bundled **IBM Plex Sans** typography and precise `Theme.swift` tokens in high-resolution 2× retina PNGs located in `docs/design/previews/164/`:

| Preview File | Description & State Shown |
| :--- | :--- |
| [**`01-timing-cue-variants-light.png`**](file:///Users/kju/Developer/SmackAPad-iPad/docs/design/previews/164/01-timing-cue-variants-light.png) | **Timing Cue Variants (Light Mode):** Side-by-side comparison of B1 (Gliding Pip), B2 (Whisper Bar), and B3 (Rim Pip) across Ahead (-25 ms), On Time, and Behind (+28 ms). |
| [**`02-timing-cue-variants-dark.png`**](file:///Users/kju/Developer/SmackAPad-iPad/docs/design/previews/164/02-timing-cue-variants-dark.png) | **Timing Cue Variants (Dark Mode):** Same comparison in dark appearance (`#1F1D1A`). |
| [**`03-run-progress-variants-light.png`**](file:///Users/kju/Developer/SmackAPad-iPad/docs/design/previews/164/03-run-progress-variants-light.png) | **Run Progress Variants (Light Mode):** C1 (Segmented Rail), C2 (Stepped LED), C3 (Bead Track). Details C1 in live filling (65%), Learning mode fail (credit held), Challenge mode fail (streak broken), and Star 1 earned. |
| [**`04-run-progress-variants-dark.png`**](file:///Users/kju/Developer/SmackAPad-iPad/docs/design/previews/164/04-run-progress-variants-dark.png) | **Run Progress Variants (Dark Mode):** Same progression states in dark appearance. |
| [**`05-focus-mode-light.png`**](file:///Users/kju/Developer/SmackAPad-iPad/docs/design/previews/164/05-focus-mode-light.png) | **Focus Mode Full Screen (Light Mode):** Reference 1180×820 iPad canvas during active drumming. Top bar faded out, minimal HUD active, stationary orange pattern band, pad flashes, and STOP/RESTART. |
| [**`06-focus-mode-dark.png`**](file:///Users/kju/Developer/SmackAPad-iPad/docs/design/previews/164/06-focus-mode-dark.png) | **Focus Mode Full Screen (Dark Mode):** Reference iPad canvas during active drumming in dark appearance. |
| [**`07-focus-mode-before-after.png`**](file:///Users/kju/Developer/SmackAPad-iPad/docs/design/previews/164/07-focus-mode-before-after.png) | **Before & After Comparison:** Side-by-side transition view showing Stopped State (full tools) vs. Drumming Focus State (clean HUD). |

---

## 7. Recommended Combination for Implementation (Ticket 165)

Based on ergonomic testing, peripheral visibility, and rhythmic stability, the recommended combination is:
1. **Remove `HitTimingBar`** from practice screen; keep `HitTimingPlot` in Detail sheet.
2. **Adopt Variant B1 (Gliding Horizon Pip):** Damped spring puck in recessed slot, left=rushing, right=dragging, deadband centered for on-time pocket.
3. **Retire `BandEdgeGlow`** to eliminate dual-indicator confusion.
4. **Adopt Variant C1 (Segmented Vault Rail):** Clear target star badge (`★ 1` / `★ 2`) with live-filling chamber segments, discrete vault locking for Learning mode, and synchronized flash/drain for Challenge mode streak breaks.
5. **Adopt Stationary Band Focus Mode:** 0.25 s fade-out of top bar and stopped tempo button on START; rock-solid stationary band placement; clean HUD above the band; instant restoration on STOP.
