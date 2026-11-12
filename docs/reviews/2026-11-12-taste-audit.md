# Taste audit: AI-generic look (taste-skill, app-screen rules)

Status: all 4 batches done. Analysis only, no code changed.
Method: rules of `taste-skill:design-taste-frontend` (house rules + `references/app-screens.md`), read only; its scripts were not run (AGENTS.md). Screens captured in the iPad (A16) simulator, landscape, dark mode, debug scenario `reviewDueToday`.

## Batches

| # | Screens | Status |
|---|---|---|
| 1 | Foundation (Theme.swift), Home, Training (Today band, Extra mix, Play after me, Review queue, Memory) | done |
| 2 | Library (filters, genre menu, star popover), Mix lineup, Today session | done |
| 3 | Practice / play screen: ready, legend, count-in, running HUD, result, session results, options; banners and summary in code | done |
| 4 | Settings, Controller, Calibration, Full version, Badges, Intro, Help (light mode); About and alerts in code | done |

## Batch 1 findings

### Foundation (Theme.swift)
1. **Cream ground + orange.** `creamHex 0xF4EFE6` with orange is the skill's named "assistant palette" (yellow-cream ground with terracotta/rust). The brief itself says "exactly orange, black, white". The destructive colour `0xC0392B` ("warm brick red / terracotta") is the same tell. → Light ground a true near-white (or a cool grey), destructive from the orange/black system, not a fourth hue.
2. **Hairline as the system divider** (`Theme.hairline`, 1px outlines, `destructiveOutline`). Skill: separate surfaces by a tone step, not a line. → Drop outlines on cards; use `surface` tone step.
3. **`stepTag` is monospaced.** Banned outside code. → Plex Sans with tabular figures.
4. **Same radius on everything** (~16pt on band, cards, buttons, rows). On the brief's own reject list. → Decide two radii: pads (hardware) and controls; buttons either square or fully round.

### Home
5. **Index numbers 01–08 on pads.** Skill bans index numbering as costume. Here it imitates MPC pad numbers, which is the closest thing to a real reason — but it carries no information (pad 05 = Controller means nothing). → Either remove, or make them real: the MIDI note / pad the player can hit on their controller to open that tile. That would turn decoration into the app's one "live thing".
6. **Decorative faders with dB scales (CH 01–04), screws, brushed texture.** Fake hardware that does nothing = the brief's "fake 3D" and the skill's "fake dashboard". Tiny uppercase "CH 01" labels too. → Remove, or bind to something real (e.g. the four mixer channels = actual sound volumes in Settings, or live MIDI velocity of the last hits).
7. **Centred title + centred 3×3 grid** with empty side bands in landscape. The frame is symmetric but the sides hold only ornaments. → Use the width: grid left, a real "today" summary (what's due, streak, last session) right.
8. **Uniform grid of identical cards** — accepted here because it *is* the controller metaphor; the centre logo tile breaks the pattern sensibly. Keep.
9. **"How it works" row:** default SF Symbols (question mark, chevron) in a generic list row. → Make it a ninth function on the plate or plain text link.

### Training
10. **Eyebrows everywhere:** "1 · REVIEWS", "2 · NEW LESSON", "3 · MIX · OPTIONAL", "EXTRA MIX", "PLAY AFTER ME" — tiny uppercase tracked labels with index numbers. Strongest AI tell on the screen. → Sentence case headings at readable size; order shown by position (left→right already shows it).
11. **"now" pill badge** in the first card. Banned. → The black outline already marks the current step; drop the pill.
12. **Dashed border** on the optional Mix card. → Show "optional" by lower contrast (lighter tone fill), not a dashed line.
13. **Two titles:** "Training" (header) and "TODAY" (band). → One. The date can sit in the band heading ("Today, Thursday 12 Nov").
14. **Outlined panels with outlined + filled button pairs** (Another mix / Start mix, Another lesson / Start) — identical twin panels, generic template. → Two panels should differ in composition; secondary actions as text buttons.
15. **Default SF Symbols** (info circle, chevrons, back arrow in a rounded square) — brief's reject list says "untouched default SF Symbols". → Own icon set drawn to match the pads, or text.
16. **Continue card** duplicates the Home "Continue" pad and the "Play after me" lesson — the same lesson appears three times. Content issue more than style.

### What already works (keep)
- Orange band carrying the plan — a real, product-owned element.
- Barlow Condensed display face: a deliberate choice, fits hardware labels.
- Real data on screen (lesson names, BPM, counts), no vanity numbers, no gradients, no glow, no emoji.

## Batch 2 findings

Note: there is no separate lesson-picker screen. `LessonPicker.swift` holds `ContentView` (the file name is misleading). "Another lesson" swaps the lesson in place.

### Library
17. **Stock iPad split view.** It has a system sidebar toggle, a system segmented control (Path / Genres / Techniques), a magnifier search field and a system blurred menu. It reads as a default UIKit template, not as this product. → Keep the split, but draw the sidebar as the product's own: levels as a vertical strip of pads or LED meters instead of list rows.
18. **A row of outlined pill chips with counts in brackets:** "3★ (3)", "2★ (0)", "1★ (0)", "In progress (0)". Chips that show "(0)" offer a choice with no result. "Not started (" is cut off at the right edge. → Hide filters that have zero results. Use one menu for the star filters. Do not put counts in brackets.
19. **The active filter is invisible.** On entry the "3★" filter was already active but looked exactly like the inactive chips, and the list said "No matching lessons". Only "Not started" showed an orange outline once tapped. → The active state must be obvious (filled), and every screen must start on "All".
20. **The genre menu sits on a button labelled "All"** with a list icon, between the star chips. It reads as a fourth star filter. → Label it "Genre: All".
21. **Thin progress lines under every row**, sidebar and header included. Hairlines carry the progress, and with 12/1,722 they show almost nothing. → One clear meter per level. Leave rows with no progress without a line.
22. **Lesson rows are identical outlined cards** with a radio circle, an index number (4, 5, 6…), five difficulty dots, three empty stars and an info icon. That makes six small marks per row. → Drop the radio circle and the outline, show stars only once earned, and say the difficulty in words or with one mark.
23. **Large empty area** to the right and below when the list is empty, with a lone "Settings" button in the top right. → An empty state that says why it is empty and offers "Show all lessons".
24. **Keep:** the mini pattern preview in each row. It is the product's own element and the strongest thing on the screen.

### Daily mix (Mix lineup)
25. **Three identical cards in a row** with numbered circles 1/2/3, an orange "Review" label and twin outlined buttons (Listen / Try). This is the "row of identical cards" tell. → One list, or one large card for the current item with the others queued.
26. **An empty cream pill next to "80 BPM"** on every card, with no text. It looks like a broken element. Either it is missing content or it is meant as a control nobody can identify.
27. **Half the screen is empty** between the cards and the bottom bar. → Make the pattern bands large (the brief says the pattern dominates); they are the content.
28. **Keep:** the orange mini bands with the pad name. They match the brief.

### Today session
29. **"FIRST STEP OF THE DAY"** is monospaced, uppercase and letter-spaced. That is three banned devices in one label, and the clearest AI tell found so far. → Delete it. The step strip above already says this is step 1.
30. **A stepper of four outlined cards** labelled "1. Review / Start", "2. Review / Waiting"… with numbering and status words in small coloured caps. → Show order by position and the current step by fill. Drop the word "Waiting".
31. **No screen title.** The screen opens with a back button and a centred grey line, "Reviews · 2 today". → One clear heading ("Today: 4 steps").
32. **The "Rhythm pattern preview" label plus a tiny preview.** A label that names what you can see, and a pattern at about 270 px on a 1180-point screen. The brief says the pattern is the dominant element. → Show the pattern large, without the label.
33. **A centred card in an empty screen** with Skip / Done for today as twin outlined buttons. → Use the width. Make the secondary actions plain text buttons.

### Possible bugs seen in batch 2 (to become tickets, not fixed)
- Library opened with the "3★" filter active and invisible, showing "No matching lessons", although the chip said "3★ (3)".
- The empty cream pill on every Daily mix card.
- The "Not started (…)" chip is cut off at the right edge.

## Batch 3 findings — play screen

Captured: ready state with the Pad legend popover, count-in, running, early-stop result, the Session results sheet and the Practice options popover. The tempo-up banner, star burst, badge banner and the Today step hand-off and summary cards were checked in code only, because reaching them needs real hits.

### What already works (keep, this is the product's face)
- **The orange band dominates and runs edge to edge.** Beat numbers are large, sixteenths are dots and the KD cells are big. This is the brief carried out, and nothing generic.
- **The four-bar meter in the HUD** looks like real LED segments and carries real data.
- The large "0 %" figure on the result is type, not a tile. That fits the app-screen rule "KPIs are type".

### Toolbar and HUD
34. **Icon soup.** The ready screen has 11 icon buttons in four differently styled groups: a pill group (ear, drumsticks, speech bubbles, a head with a brain), an outlined capsule (arrow, sidebar "1", repeat), three outlined squares (info, grid, question) and a separate square (toggles). None has a label. Most are SF Symbols, which the brief rejects, and the brain head and speech bubbles are stock metaphors. The app-screen rule says: labels by default, icons only with names. → Group by job: mode (Listen / Play / From memory) as one labelled segmented control in the product's style, and everything else behind one "Options" button.
35. **Two identical eye icons side by side** in the running HUD. Their difference cannot be seen. → Label them or merge them.
36. **The BPM is small and in the corner** ("80 BPM", top left, at about 28pt) while playing. The brief says big type for BPM, read from arm's length. → Make the BPM the second-largest thing on the screen, after the band.
37. **"— %" placeholder and a pill around the percentage.** → Show the figure plainly, without a pill; before the first hit, show nothing.
38. **Two progress bars:** one segmented bar inside the top of the band, with a hatched (diagonal stripes) unfinished segment, and a second thin bar under the band. → One progress bar. Drop the hatching, which is a decorative texture.

### Count-in
39. **The big black "3" is laid over the band** and collides with the beat label "3" and a KD cell, so two different threes appear on screen at once. The skill's rule is that nothing lies on top of the main element. → Show the count-in in the band's header row or as the beat numbers lighting up, not as a stamp over the cells.

### Result
40. **0 % sits next to three full orange stars.** The stars are the lesson's earlier rating, but placed next to 0 % they read as a reward for 0 %. → Show earned stars only after a counted run; otherwise show grey stars or none.
41. **Pills for sentences:** "Warm-up with notes · only hidden passes count." and "1 run · best 0%" are full sentences in rounded chips. → Plain text under "Not counted".
42. **The "Not counted" line has a default alert icon.** → The words are enough.

### Session results sheet
43. **The content panel is narrower than the sheet:** a hard-edged dark box sits inside a wider rounded sheet, with the blurred screen showing at its sides. It looks broken. The sheet also has both a drag handle and a back button.
44. **Contradiction:** the sheet says "Best: 92 %", while the result card under it says "best 0%". It also says "1 completed passes" (plural). → Use one definition of "best"; fix the plural.
45. **An outlined "Run 1" row with a red tick and a divider line.** → A tone step, no outline.

### Practice options popover
46. **A stock iOS grouped form** (rows, dividers, toggles, steppers). This is acceptable for settings, but it does not look like the product. → At least tie the toggles to the palette.
47. **The toggles are cream on cream:** when on, the knob and the track are almost the same colour, so on and off are hard to tell apart in dim light. This is a contrast problem, not only taste.

### Seen in code only
48. **`kicker`** is a named eyebrow label (monospaced, tracked, `Theme.stepTag`), used on the hand-off and summary cards (TodaySessionScreen.swift:834, :926). Step tags with `.tracking` appear at :514 and :1214, and at TrainingScreen.swift:518, :1207 and :1315. → Delete them all in the eyebrow sweep.
49. **True monospace outside code:** `Theme.stepTag`, TrainingScreen.swift:1012 and :1156, and SettingsView.swift:310.
50. **Badge banner:** an orange glow (`shadow(color: orange.opacity(0.6))`, BadgeBanner.swift:33 and :50) and a 12pt "New badge" label above the name. Glow is banned. → Drop the glow; let the badge name say it.

### Possible bugs seen in batch 3 (to become tickets, not fixed)
- Session results: "Best: 92 %" against "best 0%" on the result card, and the plural "1 completed passes".
- Session results sheet: the inner panel is narrower than the sheet.
- The Pad legend popover was open when the screen first appeared and covered the band (it may have been triggered by a tap I made during the transition, so recheck on the iPad).

## Batch 4 findings — the rest, in light mode

Captured in light mode (`-light` launch argument): launch, Home, Settings, Controller, Timing calibration, Full version, Badges, Intro exercises, How it works (topic list and one topic). About (`AboutDetailView`) and the system alerts were checked in code only.

### Light mode overall
51. **Beige on beige.** The ground, plate, pads, cards and buttons are all cream within a few percent of each other. Surfaces barely separate, and on Home only the Today pad and the logo carry colour. Settings and Controller have no orange at all apart from the picker values. This is where the skill's "assistant palette" (cream ground with warm accents) shows most. → Light ground near-white or neutral grey, cards one clear tone step darker, black for structure (the brief's "black, white, orange").
52. **Colours outside Theme.swift.** There are three oranges: `Theme.orange` #FF6B00, the logo pad #FF5B1F (HomeScreen.swift:576) and `PracticeInstruments.orange` #FF7800 (PracticeInstruments.swift:9). The logo's orange is visibly redder than the Today pad next to it. Creams and blacks are also redefined at HomeScreen.swift:574–575, :639–640 and :740, and PurchasesView.swift:237. The brief says "all colours defined once as tokens in Theme.swift". → One orange; every colour from Theme.

### Settings, Controller, Calibration
53. **Stock iOS grouped forms stretched to 1180 pt:** labels on the far left, values on the far right, sliders about 900 pt long. They look like the Settings app, not like this product. → Two columns on iPad (groups left, detail right), or limit the measure to about 720 pt.
54. **The same setting in two places with different units:** metronome volume is "80 %" in the practice options and "−2 dB" in Settings. Tempo step also appears in both. → One unit; ideally one place.
55. **Small outlined buttons left inside rows** ("Full unlock", "Restore Purchases", "Connect Bluetooth MIDI"), with mixed capitalisation ("Restore Purchases" here, "Restore purchase" on the paywall). → Sentence case everywhere; one button style.
56. **Grey section heading inside a card** ("Connect a controller") looks disabled.
57. **The Controller screen shows no controller.** → The product's best "one live thing": a 4×4 pad grid that lights up as MIDI notes arrive, with the note number on each pad. That also makes Home's 01–08 pad numbers meaningful (finding 5).
58. **Calibration:** the tap area is an outlined box that looks like a text field, not a pad. A half-width divider dangles under it, and "Calibration input" is both the section title and the row label. → Draw the tap area as a Home pad; remove the duplicate label.

### Full version (paywall)
59. **Three feature rows with an icon in a tinted rounded square** (books, card, star). This is one of the skill's most explicit bans and the classic template paywall. → Plain lines of text, or show the real thing: a strip of locked lesson patterns from the 529.
60. **Keep:** the black poster panel with "FULL VERSION" and the large orange "529". That is type doing the work.

### Badges
61. **An Apple-Fitness-style ring grid** with the same icon repeated on all seven badges in a row, so the badges cannot be told apart. Percentages like "1 %" add noise. The brief says "not a gamified kids app". → Each badge needs its own mark (or none), and progress shown once per row, not seven rings.

### Intro exercises
62. **The same row tells as the Library** (radio circle, index number, three empty stars, info icon), but without the pattern preview that makes Library rows good. Numbered sections "2. Two hands", "3. Eighth notes". "Intro Exercises" (title case) here and "Intro exercises" in the sidebar.

### How it works (help)
63. **The topic list is a generic chevron list in a popover** that covers the app title. "Watch tutorial" is bold text with no button shape.
64. **Contradiction in the signal legend:** the arrows read "→ Late, ← Early", but the text says "a glow on the right means you are early". Right means late in one place and early in the next. → Pick one direction mapping.
65. **The colour legend icons in tinted squares** (tick, clock, cross) are acceptable here because they explain real marks, but they should use the same colours the band uses.
66. **The brief is out of date:** DESIGN-BRIEF.md says "no per-hit feedback and no status colours", but the app now has hit marks (correct / off / wrong). Update the brief so future reviews judge against the real rules.

### Code-only checks
- About: the app mark has a shadow at rest (AboutScreen.swift:46). Rows use SF Symbol icons plus chevrons.
- System alerts and confirmation dialogs (Settings, Library) are standard iOS. Leave them.

## Overall summary

**What gives the app its own face (keep and grow):** the orange pattern band, the mini pattern previews in lesson rows, the LED bar meter, Barlow Condensed in large sizes, the black paywall poster and big numbers set as type.

**The five sweeps that remove most of the AI look, in order of effect versus risk:**
1. **Eyebrow sweep.** Delete every small uppercase, tracked or monospaced label above a heading (`kicker`, `stepTag`, "1 · REVIEWS", "EXTRA MIX", "New badge"), plus index numbers and the "now" pill. Findings 3, 10, 11, 29, 30, 48–50.
2. **Palette sweep.** One orange; a neutral light ground instead of cream; tone steps instead of hairlines and outlines; every colour from Theme. Findings 1, 2, 51, 52.
3. **Icon sweep.** Replace untouched SF Symbols with labels or one drawn icon set; group the play toolbar by job. Findings 9, 15, 34, 35, 59.
4. **Card-row sweep.** Break up rows of identical outlined cards (Training, Daily mix, Today stepper, lesson rows, Badges). Findings 14, 22, 25, 30, 61.
5. **Ornament sweep.** Remove or make real the fake faders, screws, hatching, glows and decorative pad numbers. Findings 5, 6, 38, 50.

**The one big idea:** make the controller visible and live. Pads that light up from real MIDI input on Home, in Controller setup and on the play screen would replace the decorative hardware with real hardware, and no competitor would have the same screen.

## Top 3 changes from batch 1
1. Remove eyebrows, index numbers and the "now" pill across the app (one sweep, biggest visible gain).
2. Replace the cream/terracotta palette with the brief's strict orange/black/white; tone steps instead of hairlines.
3. Remove or make real the Home ornaments (faders, screws, pad numbers).
