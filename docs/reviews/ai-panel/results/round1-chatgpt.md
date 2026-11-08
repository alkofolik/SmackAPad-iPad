## A. Common core

**A1. What is it, and who is it for?**

Smack-a-Pad is an offline iPad practice trainer for beginner-to-intermediate finger drummers using external MIDI pad controllers, built around progressively faster grooves, recall practice and scheduled reviews.

**Review basis:** `00-brief.md`, all 29 pages of :codex-file-citation{path="/Users/kju/Developer/SmackAPad-iPad/build/2026-11-08-chatgpt-upload/smackapad-screenshots.pdf" purpose="source"}, and relevant permitted source files at [commit `5084d26`](https://github.com/alkofolik/SmackAPad-iPad/tree/5084d260f09c850621de745303c7a2de89ee7f29). I did not open `docs/tickets/` or `docs/reviews/`. Competitor information and Apple requirements were checked on **8 November 2026**. This is a materials-based review, not a hands-on test.

**A2. Scores**

| Axis | Score | Reason |
|---|---:|---|
| First 10 minutes for a new user | 5/10 | The source routes first-time users into Intro, but the supplied setup screens expose profiles, note numbers and calibration without demonstrating a successful beginner journey (`HomeScreen.swift`; `27-controller-setup.png`; `30-calibration-guided.png`). |
| Learning effectiveness (does it really make you a better finger drummer?) | 6/10 | Progressive exercises and hidden-pattern reviews are credible practice mechanisms, but velocity is absent from scoring and transfer to independent musical playing is unproven (`intro.json`; `ReviewScheduler.swift`; `ScoringEngine.swift`). |
| Motivation to come back daily | 6/10 | A bounded Today session gives a useful reason to return, undermined by an intimidating review forecast and contradictory completion reporting (`18-training-main.png`; `24-today-session-summary.png`). |
| Visual design and clarity | 7/10 | The practice grid has strong hierarchy, but tiny secondary controls and several competing progress vocabularies make surrounding screens harder to understand (`10-practice-static-view.png`; `03-library-path.png`; `19-due-now.png`). |
| Readiness for App Store release | 4/10 | Purchase infrastructure exists, but the brief explicitly leaves privacy, sound credits, public URLs and hardware validation unfinished (§7; `32-about-credits.png`). |
| Commercial potential | 5/10 | There is a plausible specialist proposition, but both subscription-based MIDI training and inexpensive one-time iPad practice apps already exist; demand for this particular combination remains unmeasured. [Melodics](https://apps.apple.com/us/app/melodics-for-ipad/id1474895145), [FingerDrumPad](https://apps.apple.com/us/app/fingerdrumpad/id6797525538). |

**A3. The three strongest things to protect**

1. **The practice screen prioritizes the instrument.** Large rhythmic information, visible tempo and direct transport controls suit an iPad standing behind a controller. Preserve that hierarchy. Evidence: `09-practice-play-running.png`, `10-practice-static-view.png`, `11-scrolling-view.png`.
2. **Progress continues beyond passing a pattern once.** Tempo progression, recall and later reviews form a coherent practice loop. Preserve the distinction between immediate performance and later retrieval. Evidence: brief §4; `14-run-result.png`; `ReviewScheduler.swift`.
3. **The free version can demonstrate the actual product.** MIDI, calibration, kits and training are included, not merely a sample video or restricted preview. Source data confirms **587 unique lessons: 58 free and 529 Full**. Evidence: brief §6 and the four lesson JSON files.

**A4. The three most serious problems, ranked**

1. **The app’s success signals are not trustworthy enough.** `24-today-session-summary.png` shows two green review checkmarks with 100% scores while reporting **“Reviews 0 of 2.”** A trainer cannot leave users guessing whether practice counted.
2. **The primary hardware experience is insufficiently validated.** Field testing remains pending in brief §7, while `27-controller-setup.png` presents named controller presets that could be mistaken for verified compatibility.
3. **The release has known compliance gaps.** Missing public privacy/support links and sound credits are concrete unfinished work, not hypothetical concerns. Evidence: brief §7; `32-about-credits.png`; `AboutScreen.swift`.

**A5. Would a target user pay, and how much?**

**Yes—conditionally. I would launch Full at US$19.99 once.** The condition is that the free version proves reliable controller setup, understandable scoring and useful practice.

That is below one month of Melodics’ listed US iPad subscription, **$34.99**, but above FingerDrumPad’s **$9.99** one-time unlock. Smack-a-Pad must justify that difference through its controller workflow and structured retention practice, not its lesson count alone. [Melodics pricing](https://apps.apple.com/us/app/melodics-for-ipad/id1474895145), [FingerDrumPad pricing](https://apps.apple.com/us/app/fingerdrumpad/id6797525538).

The `$19.99` in `31-purchases-sheet.png` is not evidence of a configured live storefront price: `docs/2026-11-02-iap-testing.md` explicitly describes local prices as test fixtures.

**A6. One thing for the next month**

**Run an observed hardware beta with ten previously uninvolved target users, and fix the failures it exposes.**

The proposed test should follow users from connection through their first groove, a later review and playing that groove without the app’s notation. Record where they need help and whether they understand what counted. This would address the largest evidence gap in brief §7 and test whether the product produces learning rather than successful screen-following.

## B. Role findings

**R1 — Market analyst**

The relevant alternatives are:

- **Melodics — direct competitor on iPad and desktop.** Free lessons with a daily play limit; the US iPad listing shows **$34.99/month or $179.99/year**. Its strengths are interactive feedback, guided courses and a large lessons-and-songs catalogue. Its clear disadvantage against Smack-a-Pad’s proposition is recurring payment; the cited materials do not establish an equivalent offline, account-free, one-time offering. [App Store](https://apps.apple.com/us/app/melodics-for-ipad/id1474895145), [lesson structure](https://melodics.com/lessons).
- **The Quest for Groove — structured instruction.** Free beginner course, then monthly membership or a non-renewing annual purchase. Exact current amounts were not visible in the retrieved pricing page. Its strengths include explanations, hand technique, playalong material and instructor feedback. Automated MIDI scoring and scheduled recall assessment are not described in the cited materials. [Pricing](https://questforgroove.com/premium/), [FAQ](https://questforgroove.com/faq/).
- **Dragon Finger Drums — substantial recorded-course alternative, with availability uncertainty.** The current homepage simultaneously announces closure and advertises a **$100 lifetime bundle** containing 35 hours of material; it also links a free starter course. Its strength is instruction extending into performance and beatmaking. Continuing support and new enrollment are uncertain; automated MIDI assessment is not described. Treat it as a legacy alternative, not a confidently active service. [Official site](https://dragonfingerdrums.com/).
- **FingerDrumPad — adjacent iPad competitor.** Free download plus **$9.99 once**. It advertises practice charts, detailed timing feedback, configurable touch pads, a sequencer and sound expansion. Its published emphasis is touch playing and MIDI output; external-controller input assessment and spaced retention reviews are **not visible in the cited materials**. It is still enough to disprove “one-time iPad drum training is unique.” [App Store](https://apps.apple.com/us/app/fingerdrumpad/id6797525538), [features](https://fingerdrumpad.com/).
- **Controller bundles — competition at the moment of purchase.** Novation supplies **40 free Melodics lessons across keys and finger drumming**; Ableton offers free Move-specific Melodics lessons for computer or iPad. Their strength is immediate discovery through the hardware ecosystem. The bundled lessons are not a perpetual unlock of the complete paid catalogue. [Novation](https://support.novationmusic.com/hc/en-gb/articles/360001373045-How-to-install-and-activate-Melodics), [Ableton](https://help.ableton.com/hc/en-us/articles/15810376977052-Melodics-Lessons-for-Move).

**Sharpest positioning:** *“Daily finger-drumming practice for your MIDI pads—learn grooves, recall them without the grid, and pay once.”*

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|
| R1-01 | **The opportunity is a specific practice workflow, not an empty category.** iPad support, scoring and one-time pricing are individually available elsewhere. | Competitors above; brief §§3–6; `13-practice-from-memory.png`. | major | high | Lead with the sequence “learn → play without notation → retain,” supported by a real controller demonstration; avoid “first,” “only” or generic “ultimate drum trainer” claims. | S |
| R1-02 | **The addressable audience is narrower than “beatmakers.”** It requires compatible iPad ownership, compatible hardware and an interest in practicing performance rather than primarily producing tracks. | Brief §2 and §8; [Melodics’ iPad compatibility guidance](https://support.melodics.com/en/articles/6777115-connecting-your-midi-instrument-to-melodics-on-ipad); [Quest for Groove’s audience claim](https://questforgroove.com/premium/). | major | medium | Start with owners of a small, verified set of controllers who want a daily practice routine; validate that segment before expanding the message. | M |

**Realistic audience size:** the sources do not support a defensible numerical market estimate. Quest for Groove claims thousands of past students, but that is neither a verified active-user count nor the iPad-compatible subset. My inference is a **small international specialist market**; a sustainable hobby business is plausible, while a full-time income case is unproven. The first 1,000 users should be treated as an acquisition experiment, not an assumed market share.

**R2 — Pricing and business advisor**

Keep the decided free-download-plus-one-time-unlock model. The brief describes bundled content and local operation, which fit a finite purchase. A subscription would require a stronger continuing-service proposition than the materials demonstrate; changing the model would not fix the present evidence gaps.

**Keep free:** the existing 58 lessons, unlimited practice time, all controller setup and calibration, all kits, scoring, and the complete review loop for free lessons. Specifically demonstrate earning and reviewing a lesson before asking for payment.

Optional future packs can work as separately described additions. Preserve access to everything bought in Full, and explain its scope before introducing packs. The current purchase logic already distinguishes Full from future packs (`StoreManager.swift`; `docs/2026-11-02-iap-testing.md`, “Future packs”).

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|
| R2-01 | **The purchase screen sells quantity more clearly than value.** “587 lessons” includes free material and gives little reason to buy after the beginner stage. | `31-purchases-sheet.png`; `PurchasesView.swift` counts both `free` and `full`; brief §5. | major | high | State “529 additional lessons; 587 total,” then name concrete next skills and show representative paid patterns; explain that purchase unlocks content while stage guidance remains skippable. | S |
| R2-02 | **Distribution must be part of the product work.** A catalog and a low price do not establish a route to the first 1,000 users. | Marketing assets remain pending in brief §7; existing hardware distribution examples from Novation and Ableton above. | major | medium | Build controller-specific setup guides and useful demonstrations, then seek community and educator referrals; pursue manufacturer bundles after compatibility and learning evidence exist. | L |

A practical, zero-ad-budget route to the first 1,000 **downloads**:

1. **First testers:** recruit through permission-respecting posts in [r/FingerDrumming](https://www.reddit.com/r/FingerDrumming/comments/1umlj25/want_to_start_finger_drumming/) and the [Loopy Pro forum](https://forum.loopypro.com/discussion/36064/melodics-for-ipad), where relevant discussions already exist. Offer a specific test: connect this controller, learn this groove, return for a review. Those discussions establish relevance, not likely conversion.
2. **App Store discovery:** test descriptive terms such as **finger drumming, MIDI pad, drum practice, rhythm trainer, groove practice**. Use “Finger Drumming Trainer” prominently in the subtitle. Search volumes are **not visible in materials**; these are hypotheses, not validated keywords. Do not stuff competitor or controller trademarks into keywords. [Apple §2.3.7](https://developer.apple.com/app-store/review/guidelines/#accurate-metadata).
3. **YouTube:** publish short, searchable setup demonstrations for controllers actually tested, plus one complete practice-and-recall example. Approach finger-drumming educators with a working example and request an independent evaluation. Their existing instructional offerings are evidence of relevant audiences, not a promise of coverage. [Quest for Groove](https://questforgroove.com/premium/), [Dragon’s free starter material](https://dragonfingerdrums.com/).
4. **Controller makers:** initially request a compatibility-page mention or setup-guide link. A formal bundle is a later negotiation; Novation and Ableton already have Melodics offers, so those channels are not unoccupied.
5. **Measure:** use [App Store campaign links](https://developer.apple.com/help/app-store-connect-analytics/acquisition/campaign-links) and voluntary tester follow-ups to distinguish discovery from successful practice. This does not require adding behavioral tracking to the app.

For scale: **1,000 purchases at $19.99 produce $19,990 in gross customer payments before applicable deductions; 1,000 downloads do not.** That is arithmetic, not a sales forecast. Avoid promising indefinite free content production on the strength of a single unlock.

**R3 — App Store Review risk**

The guideline references below come from [Apple’s current Review Guidelines](https://developer.apple.com/app-store/review/guidelines/). “Blocker” means the identified gap must be resolved before submission; conditional risks are not claims that rejection is certain.

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|
| R3-01 | **A reviewer could miss the playable fallback.** This is an accessibility-of-review risk under **2.1**, not a blanket prohibition on hardware-oriented iPad apps. | `17-practice-touch-pads-portrait.png`; `PracticeScreen.swift:72` requires portrait and a 16-pad profile for the large touch grid. | major | high | Give exact controller-free review steps: select the 16-pad profile, rotate to portrait, open Intro and play. Add an in-app hint when no controller is connected. Supply physical-device footage demonstrating MIDI setup and interaction. [Apple’s review-information instructions](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review). | M |
| R3-02 | **Working purchase code is not evidence that the submitted purchase works.** Relevant rules: **2.1(b), 3.1.1**. | `StoreManager.swift` verifies entitlements, handles transaction updates and implements restore; `31-purchases-sheet.png` shows Restore; `docs/2026-11-02-iap-testing.md` distinguishes local simulation from Sandbox testing. | major | medium | Test the actual distribution build: purchase, cancellation, pending approval, restore after reinstall, refund and offline relaunch. Submit the first non-consumable with the app version; omit placeholder products. [Apple submission procedure](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/). | M |
| R3-03 | **“Data Not Collected” does not remove privacy obligations.** Missing policy access implicates **5.1.1(i)** and missing support contact **1.5**; required-reason declarations are a separate submission requirement. | Brief §7 explicitly lists missing manifest and support/privacy website; `32-about-credits.png`; `AboutScreen.swift` contains only app/version/font information. | blocker | high | Publish accurate support/privacy pages and link them inside the app and in App Store Connect. Declare actual required-reason API uses and inspect the archived privacy report. Do not infer exemption from having no accounts. [Apple’s API declaration requirement](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api?changes=_2_8&language=objc). | M |
| R3-04 | **Bluetooth permission wording and refusal behavior are unverified.** Relevant rules: **5.1.1(ii), 2.1**. | `29-controller-bluetooth-pairing.png` shows pairing, not the permission prompt; the actual permission text is **not visible in materials**. | major | medium | Verify localized `NSBluetoothAlwaysUsageDescription`, for example: “Connect to Bluetooth MIDI pad controllers so your pad strikes can play and score exercises.” Confirm refusal leaves USB and touch practice usable. [Apple’s key documentation](https://developer.apple.com/documentation/BundleResources/Information-Property-List/NSBluetoothAlwaysUsageDescription?changes=__3_1). | S |
| R3-05 | **Sound licensing needs more than a credits checkbox.** Relevant rule: **5.2.1**. | `sample-kits.json` identifies AVL CC BY-SA material in several kits; `32-about-credits.png` omits sound credits; brief §7 acknowledges the omission. | blocker | high | Record provenance, exact licences and modifications; provide appropriate attribution and licence notices. Check ShareAlike and restrictions on technological measures against the actual sample distribution. Obtain additional permission or replace samples if necessary. [AVL licence statement](https://www.bandshed.net/avldrumkits/), [CC BY-SA 3.0 terms](https://creativecommons.org/licenses/by-sa/3.0/legalcode.en). | M |
| R3-06 | **Metadata could overstate compatibility and included functionality.** Relevant rules: **2.3.1–2.3.3**. | `27-controller-setup.png` includes an unqualified “NI Maschine” preset; physical validation is pending in brief §7; songs and chaining remain roadmap items in §9. | major | high | Publish tested model/connection combinations; distinguish note mappings from hardware compatibility. Identify paid content in marketing, show current features, and exclude roadmap promises. Melodics’ own support specifically warns that Maschine hardware does not generally work on iOS. [Compatibility guidance](https://support.melodics.com/en/articles/6777115-connecting-your-midi-instrument-to-melodics-on-ipad). | M |

Two distinctions matter:

- **CC BY-SA does not automatically mean the entire Swift app must be open-sourced.** The licence distinguishes a collection from adaptations, while retaining obligations for the licensed material. Whether this packaging complies needs examination; a generic “sounds credited” line is insufficient. [Licence §4](https://creativecommons.org/licenses/by-sa/3.0/legalcode.en).
- **Account administration can block distribution independently of app review.** Brief §7 leaves it pending. Complete the [Paid Apps Agreement](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements/), [DSA trader-status declaration](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/) and [export-compliance determination](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/). A missing encryption declaration is not, by itself, proof of prohibited encryption.

**R4 — Devil’s advocate**

The strongest failure case is this: **users learn to satisfy the app, accumulate an intimidating review queue, and never become sufficiently better musicians to recommend it.** That is a risk supported by specific mechanisms below—not a demonstrated outcome.

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|
| R4-01 | **“Mastery” can exceed what the app measures.** A player can satisfy the scorer without reproducing ghost-note dynamics; scheduled pattern recall also does not establish musical transfer. | `lessons-core.json`, lesson 185, specifies snare velocities of 95 and 40; `ScoringEngine.swift:48–53` stores no expected velocity, and `PracticeSession.swift` passes only pad and timestamp into scoring. Full-song work is deferred in brief §9. | major | high | Preserve the decided score formula, but describe precisely what stars certify. Add explicit listening/self-check instructions for dynamics and test independent playing before making broad mastery claims. | M |
| R4-02 | **The retention interface can make a short session look like debt.** It announces 29 lessons in Today’s review step, while the actual plan selects at most two; the forecast carries overdue work into later days. | `18-training-main.png`; `TrainingScreen.swift:369–392`; `TodayPlan.swift` uses `prefix(2)`; `ReviewForecast.swift` counts every due date up to each future day. | major | high | Show “2 reviews today” in the session plan, separate the remaining queue, and label the forecast as outstanding work if nothing is completed—or change it to newly scheduled work. | S |
| R4-03 | **Completion styling rewards finishing a step even when the review did not pass.** This can make the trainer appear arbitrary rather than instructive. | `24-today-session-summary.png`; `TodaySessionScreen.swift:332–337` renders a checkmark and best score, while `759–766` counts only passed/settled review feedback. | major | high | Use consistent states everywhere: “Played,” “Review passed,” “Incomplete” and “Skipped.” Explain why a 100% warm-up or otherwise ineligible pass did not count, and offer the next valid attempt. | M |

**Which arguments I actually believe:** I strongly believe the completion inconsistency and workload presentation need fixing. I also believe the current measurement supports a narrower claim than comprehensive finger-drumming mastery. I do **not** conclude that the app cannot teach useful skills, or that its independent/AI-assisted development makes failure inevitable. Neither conclusion is supported by these materials.

## C. What I could not judge

- **Timing feel, sound quality, animation smoothness or perceived latency:** recordings were not supplied, and I did not watch video or play the app. Physical-device sessions across USB/BLE and audio routes would be needed.
- **Actual learning gains:** longitudinal results and independent performance assessments are **not visible in materials**. Delayed, notation-free playing and transfer to unfamiliar grooves would strengthen the learning score.
- **The complete first-launch experience:** screenshots show an existing user with progress. Source confirms a first-run Intro destination, but unaided beginner observation could materially change the onboarding score.
- **Real hardware compatibility:** a connected device screenshot is not a tested compatibility matrix. Model-specific results, including reconnection, power and audio-route changes, would resolve this.
- **Production purchase behavior and final compliance:** the release archive, App Store Connect configuration, actual Bluetooth permission strings, published policy pages and completed Sandbox results are **not visible in materials**.
- **Catalogue quality across all lessons:** I verified counts and inspected selected lesson data; I did not musically audition all 587 lessons. An experienced finger drummer’s content audit could change the learning assessment.
- **Commercial demand:** paid conversion, repeat use, acquisition costs and a defensible numerical audience estimate are **not visible in materials**. Actual cohort results would change the commercial score.
- **Accessibility and smaller-device usability:** screenshots cannot establish VoiceOver behavior, enlarged-text support, touch accuracy or readability at playing distance. Those require device testing.