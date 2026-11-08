# Smack-a-Pad — Project Brief for Independent AI Reviewers

## 1. What it is

Smack-a-Pad is a native SwiftUI iPad application designed as a focused practice instrument and trainer for finger drumming. It is played primarily using an external hardware MIDI pad controller (connected via USB or Bluetooth Low Energy), with on-screen touch pads provided strictly as a fallback or bonus. Navigation, curriculum browsing, settings, and session management are operated entirely by touch on the iPad screen. The app operates as a quiet, distraction-free practice environment with zero ads, no user accounts, and no social feeds.

## 2. Who it is for

The app is built for beginner to intermediate finger drummers:
- Beginners who just acquired a 16-pad or 8-pad MIDI controller (or want to try with touch pads) and need a structured, non-intimidating way to build finger independence, coordination, and timing from scratch.
- Intermediate drummers, beatmakers, and producers who want to tighten their rhythm, increase playing tempo, build a solid muscle memory of common genre grooves (rock, funk, hip hop, jazz, electronic, Latin), and play patterns reliably from memory without staring at notation.

## 3. Screens and Main Flow

The app is organized around a hardware-inspired central hub, a deep lesson library, a dedicated practice view, and a spaced-repetition training system:

- **Home screen**: Designed as a physical hardware controller surface with a central 3×3 pad grid. Outer pads launch directly into the primary destinations (Continue / Today session, Library, Training, Intro, Controller setup, Badges, Full unlock, Settings), while the centre pad displays the brand mark and opens the About/Credits modal.
- **Library**: The master catalogue of grooves, organized into three switchable views:
  - *Path*: Structured progression grouped by skill level (1 to 5) and technique, unlocked stage by stage.
  - *Genres*: Grooves grouped musically (Rock & punk, Funk & soul, Jazz, Hip hop & trap, Latin & world, Electronic, Pop & country).
  - *Techniques*: Grooves grouped by technical focus (Basic groove, Sixteenths, Ghost notes, Swing & shuffle, Fills & toms).
  Includes persistent multi-select star filters (`3★`, `2★`, `1★`, `In progress`, `Not started`).
- **Intro exercises**: A dedicated onboarding collection of 25 progressive exercises (hand coordination, basic eighths, open hi-hat coordination) that are always unlocked and accessible without stage restrictions.
- **Practice screen**: The core playing environment. Dominated by a bold horizontal orange band displaying the note pattern grid (static or scrolling mode, count labels `1 e & a`, hand indicator colors). Everything else is minimal and peripheral:
  - *Listen mode*: Plays the pattern audibly through the audio engine so the player can internalise the rhythm.
  - *Play mode*: Interactive play scored against level-dependent timing windows, featuring quiet bar-by-bar text verdicts (`clean`, `ahead`, `behind`, `uneven`) rather than distracting per-hit flashes.
  - *From memory mode*: Fades or hides the pattern grid entirely, requiring the player to perform from tactile memory.
- **Training screen**: The daily retention hub driven by spaced repetition. Features a prominent Today banner, a memory progression meter, a 7-day review forecast strip, the *Due now* list (ordered by fragility, filtered with step chips), collapsible *Waiting* boxes for future reviews, a *Settled* box, plus *Mix* (continuous multi-pattern playback) and *Play after me* modes.
- **Today session**: A guided 10–15 minute daily workout assembled dynamically from up to two fragile due reviews, one fresh progression lesson, and an optional consolidation mix, concluding with a session summary card.
- **Badges screen**: A gallery of 55 achievement badges spanning 8 categories (passed lessons, mastered tempos, memory stars, course completions, level mastery, genre breadth, technical skills, and training consistency).
- **Settings**: System configurations including drum kit selection (8 bundled kits), BPM progression step (1, 2, 5, or 10 BPM), appearance (Light/Dark/System), language (English/Czech), controller profile picker, and direct links to calibration and MIDI setup.
- **Controller setup & MIDI learn**: Configuration for external controllers. Users select 16-pad or 8-pad mode, manage controller profiles (preset profiles included), pair Bluetooth MIDI devices via the native iOS dialog, or run an interactive MIDI Learn wizard where tapping each pad maps hardware note numbers to app pad slots.
- **Calibration**: A guided 10-click procedure aligning audio output latency with MIDI input timing. Measures a per-device signed offset in milliseconds using robust median statistics to ensure scoring remains fair regardless of audio or MIDI hardware.
- **Purchase sheet**: An in-app purchase modal displaying the one-time "Full Version" unlock, detailing unlocked features (529 Full lessons, complete progression, unlimited training), real localized App Store pricing, and a Restore Purchases option.

### Player flow between screens
1. The player launches into **Home**.
2. Tapping the top-left pad immediately resumes their journey via the **Today session** (if reviews/lessons are pending) or continues the last active lesson.
3. Alternatively, the player browses the **Library** or **Intro**, picks a pattern, and enters the **Practice screen**.
4. In Practice, they preview in *Listen*, practise and raise tempo in *Play*, and test recall in *From memory*.
5. When a lesson reaches Star 2 (Mastery at target tempo), it automatically enters the **Training** spaced-repetition queue.
6. On subsequent days, the player visits **Training** or starts the **Today session** from Home to review due lessons and earn permanent mastery (Star 3).
7. Hardware adjustments (kit sound, controller mapping, calibration) are accessed anytime from Home or via the unobtrusive tools popover in Practice.

## 4. Learning System

The educational methodology blends deliberate practice, motor-skill automation, and spaced retrieval:

- **Three-Star Progression**:
  - **Star 1 (Passed)**: Demonstrates basic competence. Awarded for completing a full run with a score of $\ge 70\%$ ($\ge 80\%$ for Intro exercises) within the timing window.
  - **Star 2 (Mastery)**: Demonstrates speed and clean execution. Awarded for achieving a clean run at or above the lesson's target BPM. A clean run enforces strict error limits based on pattern length: $0$ errors for $\le 15$ hits, $\le 1$ error for $16$–$32$ hits, $\le 2$ errors for $> 32$ hits ($0$ errors always required for Intro).
  - **Star 3 (Retention / Settled in hands)**: Demonstrates durable long-term retention. Practice *From memory* mode alone does not grant Star 3. Instead, once Star 2 is reached, the lesson enters the spaced review system in Training. Passing **two separate review sessions on different days** (reaching review step $\ge 2$ or settled status) awards Star 3 with a special celebratory completion animation.
- **Tempo Auto-Progression**:
  - After any clean run below the target tempo, the app automatically steps up the tempo by the user's selected increment: **1, 2, 5, or 10 BPM** (default is 5 BPM).
  - Tempo rises smoothly without stopping the musical flow, allowing players to build speed gradually toward target BPM. Unclean runs never decrement tempo.
- **Spaced Review Schedule & Training Due List**:
  - Review intervals follow an expanding spaced-repetition schedule:
    - Step 0 $\rightarrow$ 1 day gap
    - Step 1 $\rightarrow$ 3 days gap
    - Step 2 $\rightarrow$ 7 days gap
    - Step 3 $\rightarrow$ 21 days gap
    - Passing Step 3 marks the lesson as permanently **Settled** (*Upevněno*).
  - A review attempt must be played *From memory* at target BPM with a score of $\ge 80\%$.
  - Passing advances the lesson to the next interval; failing steps it back one step and reschedules it for tomorrow.
  - The Training screen organizes reviews cleanly: *Due now* shows the top 5 most urgent reviews (prioritizing fragile Step 1 reviews and overdue lessons) with quick step filter chips, while upcoming reviews wait in tappable future-day boxes (*Tomorrow*, *In 2–3 days*, *In 4–7 days*, *Later*).
- **Stage Unlocking & Soft Unlock**:
  - In the Library Path, a stage unlocks automatically when the player earns 2 stars on $\min(\lceil N / 2 \rceil, 10)$ lessons in the preceding stage ($N$ = lesson count of previous stage).
  - To prevent frustration, a **Soft Unlock** mechanism allows any player to manually tap and unlock a locked stage with an inline confirmation dialog. Unplayed, manually unlocked stages can be re-locked at will.
- **Badges**:
  - 55 structured badges reward volume, speed, retention, genre diversity, and daily habit consistency without gamey distraction.

## 5. Content

The app contains **587 bundled lessons** across diverse musical styles:
- **Intro exercises**: 25 exercises (24 foundational coordination drills from `intro.json` + core lesson 6 covering open hi-hat offbeats). All 25 are 100% free.
- **Core curriculum**: 539 lessons spanning Levels 1 to 5 across 8 core categories:
  - *Starter / Basic groove* (rock, pop, dance fundamentals)
  - *Eighth-note grooves* (eighth-note hi-hat variations)
  - *Sixteenth-note grooves* (funk, pop, hip hop 16th subdivisions)
  - *Electronic* (house, techno, breakbeat, electro, drum & bass)
  - *Ghost notes* (funk and snare dynamics)
  - *Swing & shuffle* (triplet feel, jazz, blues, swing)
  - *World & Latin* (bossa nova, samba, afrobeat, reggae, New Orleans)
  - *Fills & toms* (linear fills, tom movements, rhythmic breaks)
- **Electronic path extensions**: 12 dedicated electronic lessons (hardgroove, broken techno, UK club).
- **Genre extensions**: 12 specialized rhythmic lessons (Jersey club, Footwork/juke).
- **Free vs. Full breakdown**:
  - **Free Tier (58 lessons)**: All 25 Intro drills + 31 Level 1 Path lessons (Stage 1) + 3 electronic starter lessons. Players can experience the entire learning loop, calibration, scoring, and training without paying.
  - **Full Tier (529 lessons)**: Levels 2 through 5, advanced genres, ghost notes, fills, world rhythms, and complex syncopations, unlocked via the one-time purchase.
- **Audio kits**: 8 bundled high-quality acoustic and electronic sample kits: *Acoustic*, *808*, *Jazz*, *World*, *Rock*, *Brush*, *World Percussion*, and *House* (371 unique WAV audio files embedded in the app bundle).

## 6. Business Model

- **Free download**: The app is completely free to install from the App Store with 58 playable lessons and all core features (calibration, MIDI input, audio engine, sample kits, spaced repetition).
- **One-time Non-Consumable In-App Purchase (`cz.kju.SmackAPad.full`)**: A single lifetime purchase unlocks all 529 locked lessons and advanced stages forever. No recurring subscriptions.
- **Future content packs**: The software architecture is prepared to support optional modular paid packs in post-1.0 releases (`cz.kju.SmackAPad.pack.<id>`).
- **Privacy & Ethics**:
  - No user registration, no passwords, no email collection.
  - No third-party tracking, advertising SDKs, or behavioral telemetry ("Data Not Collected").
  - Works 100% offline; all lessons, audio samples, and progress files reside locally on the iPad.

## 7. Current State of Development

### What is completed and fully operational
- Native SwiftUI architecture targeting iPadOS 17+, optimized for landscape iPad orientation on a stand.
- High-performance low-latency audio engine (`AVAudioEngine`) with shared output presentation latency compensation.
- Native CoreMIDI integration with hardware timestamps, BLE fallback handling, preset controller profiles, and user-facing MIDI Learn.
- Guided 10-click hardware calibration procedure.
- Full 16-pad and 8-pad layout support (in 8-pad mode, all 587 lessons are playable via dynamic slot assignment and specialized 8-pad hit mappings).
- Scoring system with level-dependent timing windows (Levels 1–5), adaptive timing center drift tracking, and double-hit debounce guards.
- Complete visual UI following the custom hardware-inspired aesthetic (Theme tokens, high-contrast typography, zero generic UI kits).
- All 11 primary views and sub-flows implemented and linked.
- Local persistence using clean JSON and UserDefaults storage in the app sandbox.
- StoreKit 2 in-app purchase implementation with transaction listener, entitlement verification, and restore functionality.
- Complete English and Czech localization.

### What is pending before version 1.0 release (from Release Checklist sections C and E)
- **App Store compliance & security metadata**:
  - Creation of the privacy manifest (`PrivacyInfo.xcprivacy`) covering standard system API declarations (UserDefaults, boot time, file timestamps).
  - Setting the export compliance encryption declaration (`ITSAppUsesNonExemptEncryption = NO`).
- **Legal attribution & support web**:
  - Adding visible in-app sound credit disclosures in About screen for third-party Creative Commons samples (specifically CC BY-SA for AVL Drumkits).
  - Launching the minimal static support and privacy policy website to obtain public URLs required by App Store Connect.
- **Storefront marketing assets**:
  - Final App Store promotional screenshots on a 13-inch iPad (English and Czech).
  - Final English and Czech marketing descriptions, keywords, and App Store review notes.
- **Hardware validation**:
  - Field testing with physical USB and Bluetooth MIDI controllers on physical iPads to verify real-world calibration pass rates and audio latency across older iPad models.
- **Developer administrative setup**:
  - Apple Paid Apps agreement completion, EU trader status (DSA) declaration, and local tax/business formalities.

## 8. Decided (Do Not Re-Argue)

The following architectural and product decisions are finalized for version 1.0 and should not be debated by reviewers:

- **Target platform**: iPad-only on iPadOS 17 or later; iPhone is explicitly unsupported.
- **Input priority**: Hardware MIDI pad controllers (USB/BLE) are the primary instrument; on-screen touch pads are strictly secondary fallbacks.
- **Monetization**: Paid upfront one-time unlock (`cz.kju.SmackAPad.full`), never a mandatory monthly subscription.
- **User accounts & cloud**: No user logins, no server infrastructure, no iCloud sync in v1.0; all data is local.
- **Visual design philosophy**: Industrial hardware aesthetic (orange, black, white tokens), high contrast for arm's length viewing in dim light; no gamified mascots, confetti, floating cartoon bubbles, purple gradients, or glassmorphism.
- **Practice screen UX**: Pattern-first grid view; no distracting per-hit visual flashing; feedback is delivered as a quiet, one-word textual verdict per bar (`clean`, `ahead`, `behind`, `uneven`).
- **Scoring formula**: Score equals $\text{matched hits} / (\text{expected hits} + \text{extra hits})$; hits within the timing window count equally without granular accuracy weighting.
- **Timing tolerance**: Philosophy of human groove tolerance; microsecond pedantry is rejected; adaptive timing center shifts with systematic player drift.
- **8-pad controller compatibility**: Achieved via per-lesson dynamic voice mapping (`layoutForEight`) and `hits8` fallback patterns, ensuring 100% of bundled lessons can be played on 8-pad controllers.
- **Progression gates**: Progression is guided via 2-star stage requirements, but soft-unlock overrides ensure no learner is ever permanently trapped.
- **Third star qualification**: Star 3 is earned solely through passing two spaced reviews in Training; practice From memory mode alone does not grant Star 3.
- **Persistence stack**: Plain JSON files in Documents and UserDefaults; no Core Data or SwiftData.

## 9. Planned After 1.0 (Post-v1 Roadmap)

These features have already been conceptualized and scheduled for future updates (v1.1+ or v2.0); reviewers should be aware they are already on the roadmap:

- **Full songs built from lessons**: Multi-section songs (intro, verse, chorus, bridge, breakdown, outro) assembled dynamically from existing lesson patterns, offered in Short (16-bar) and Full arrangements with a thin section overview strip.
- **Chaining mode**: Step-by-step assembly of longer musical pieces (learn part A, then part B, then chain A+B, then C, then B+C, growing automatically as each chain is mastered).
- **Groove + Break phrases**: 4-bar and 8-bar musical phrase drills combining 3 (or 7) bars of a groove lesson with 1 bar of a drum fill lesson.
- **Results by part & targeted repair**: Diagnostic breakdown after long runs highlighting the weakest bar or section, accompanied by a one-tap "Practise this place" shortcut that loops the weak section at a 10 BPM slower tempo.
- **Post-v1 infrastructure**: Additional downloadable genre content packs, iCloud progress backup, and hardware haptic strike feedback.

## 10. How It Was Built

The application is created by a solo creator who does not write code. The entire codebase, software architecture, UI components, tests, and documentation have been generated systematically by AI engineering agents working from modular markdown specifications and technical task tickets.

---

## Notes for the Developer (Documentation Discrepancies)

*This internal section highlights minor inconsistencies found between legacy project documents and recent ticket implementations. Reviewers may disregard or Jakub can reconcile before sending:*

1. **Star 3 Earning Mechanism**:
   - `SPEC.md` §5.3 states that Star 3 (Memory) is earned by scoring $\ge 80\%$ at target BPM in Practice with the pattern hidden (*From memory* mode).
   - *Current Implementation (Ticket 143, 2026-11-07)*: Star 3 is earned **exclusively through two passed reviews in Training** on separate days. Practice *From memory* remains an essential training tool, but no longer awards Star 3 directly. `SPEC.md` should be updated to reflect Ticket 143.
2. **Training Screen Structure & List Order**:
   - Earlier specifications described a flat *Due* list without step filtering or collapsed categories.
   - *Current Implementation (Ticket 144, 2026-11-07)*: The Due list shows the first 5 fragile reviews with a "Show all" toggle, step filter chips (All, Step 1–4), categorized collapsible *Waiting* boxes (*Tomorrow*, *In 2–3 days*, *In 4–7 days*, *Later*), and a bottom *Settled* box.
3. **Total Lesson & Free Counts**:
   - Early specifications cited "539 core + 24 intro lessons".
   - *Current Count (Ticket 32 & App Store Checklist)*: Exactly **587 total lessons** (24 intro + 539 core + 12 electronic path + 12 genre extensions). Exactly **58 lessons are free** (24 intro + 31 Level 1 core + 3 electronic path; note core lesson 6 is ordered with Intro exercises), and **529 lessons are Full**.
