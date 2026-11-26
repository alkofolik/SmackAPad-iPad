# Smack-a-Pad — Story Mode GDD v1.0 (approved with amendments, 2026-11-26)

Source: ChatGPT draft from ticket 248. Checked by Claude against branch `release-polish`; Jakub approved the amendments below on 2026-11-26. **Where the amendments and the draft disagree, the amendments win.**

## Amendments (binding)

1. **23 stages, not 25.** Stages = level 1–5 × technique, but Groove exists only in levels 1–3 (`LibraryCatalog` skips groove for level ≥ 4). Stage sizes range from 5 to ~52 lessons (approx.: L1 groove 33, L1 sixteenths 32, L2 sixteenths 46, L3/L4 fills 52). So there are 23 stage bosses + the final boss; Baron Latebeat has only 3 forms (I–III). The size table in §1.3 extends naturally to 52 lessons with the same ⌊(N−1)/3⌋ rule.
2. **Boss unlock keeps the existing stage rule** (replaces §1.5 rows "Every keystone ★2 / one alternative per fork ★2 / all mandatory mastery → boss"): the boss opens when the stage reaches the current requirement — ★2 on half of the stage's lessons, rounded up, at most 10 (`ProgressionConstant.requiredStageCompletions`). Any lesson of the stage counts (route or side trail). The map highlights how many ★2 lessons are still missing.
3. **Boss in two steps** (replaces §1.8 for now):
   - **v1:** one ★2-mastered lesson of the stage played in a loop for 8 bars (repeat the pattern to reach 8; minimum 4 bars of a long pattern is never cut — use the whole pattern repeated twice if it is 4 bars). Stamina = ⌈0.75 × bars⌉; a played bar is clean when all its notes are perfect or good and it has no wrong hit (no per-bar verdict exists in the app; rule 4a of ticket 251); stamina drops after each clean bar. Boss tempo = level % of that lesson's goal tempo (85/88/90/92/95 %), rounded down. Only attack: **Pattern Veil** (same look as From-memory hiding, but per bar, display only), announced one bar ahead: L1 none, L2 one, L3–L5 two. Gentle attempt = no attacks. No loss, unlimited retries.
   - **v2 (later, separate ticket):** medley of 2–3 patterns without pauses and Tempo Push. Not started until v1 is tested, because seamless transitions touch the run loop.
4. **Keys: the finite economy of §1.7 (7 keys) replaces the current one** (~1 key per stage exam + 8 milestones). Players who already hold more keys keep them. Skins follow §1.7 (boss counts 1 / 5 / 15 / final); bonus jam tracks keep their current rules.
5. **Ghost-note bosses use the existing accuracy metric only.** Scoring does not use hit velocity (velocity only drives the sound).
6. Placement and switching rules (§1.10–1.11) apply as written; a boss victory is only earned in the boss encounter (also offered in Free practice); legacy passed stage exams count as defeated bosses.

---

# **SMACK-A-PAD — Story Mode**

**Game Design Document · v1.0**

*Genre: turn-based musical adventure / finger-drumming education*\
*Platform: iPadOS*\
*Primary audience: adult beginners*\
*Language: English, with future Czech localization*

**Working title of the adventure: The Five Realms of Rhythm**

The central design principle is that **the student chooses the adventure, but the curriculum guarantees the education.** Choices should feel meaningful without allowing the student to accidentally skip an essential skill, choose an excessively difficult route or permanently miss a reward.

The adventure should feel like a rhythm game disguised as a bizarre fantasy campaign, not a fantasy game interrupted by drumming exercises.

# **1. Rules document**

## **1.1 Campaign structure**

The existing curriculum remains the foundation of the entire adventure.

| Element                  | Quantity        |
| ------------------------ | --------------- |
| Intro lessons            | \~25            |
| Main Path lessons        | \~540           |
| Difficulty levels        | 5               |
| Technique regions        | 5               |
| Story sub-levels         | Up to 25        |
| Regional boss encounters | Up to 25        |
| Final boss encounter     | 1               |
| Sound kits               | 8               |
| Instrument skins         | 4               |
| Currencies               | 1 — Tuning Keys |

**One existing Path stage equals one Story sub-level.** No new lessons or artificial subdivisions are necessary.

The five technique regions are revisited at increasing difficulty levels.

Campaign map · 25 sub-levels

LV 1

1.1

1.2

1.3

1.4

1.5

LV 2

2.1

2.2

2.3

2.4

2.5

LV 3

3.1

3.2

3.3

3.4

3.5

LV 4

4.1

4.2

4.3

4.4

4.5

LV 5

5.1

5.2

5.3

5.4

5.5

THE FINAL EXAM

Groove

Sixteenths

Ghost notes

Swing

Fills

Recommended campaign order: level by level, using the existing technique sequence. Genre extensions remain additional practice content outside the mandatory campaign, subject to their existing purchase entitlements.

## **1.2 Anatomy of a sub-level**

Each sub-level contains four types of nodes.

| Node       | Function                                                       |
| ---------- | -------------------------------------------------------------- |
| Keystone   | Mandatory lesson teaching or consolidating an essential skill. |
| Fork       | A choice between 2–3 equivalent existing lessons.              |
| Side trail | An unchosen fork lesson, available for optional practice.      |
| Boss       | The existing stage exam presented as a musical encounter.      |

A fork always rejoins the main route. There are no permanently exclusive branches, irreversible choices or branching endings.

Selected route

Optional trail

The main route is deliberately shorter than completing every lesson in a stage. Students who want comprehensive mastery can return and complete the remaining trails.

## **1.3 Adapting to different stage sizes**

There should not be a fixed lesson count for every sub-level. Instead, use a consistent structural rule.

For a stage containing N lessons:

- Target approximately one keystone for every two fork lessons.
- Each fork contains two alternatives by default.
- Add a third alternative where the lesson count and educational equivalence allow it.
- The student completes one alternative from each fork on the main route.
- Every existing lesson is assigned to exactly one keystone or fork.

### **Recommended distribution**

| Existing lessons | Keystones | Forks | Mandatory route | Optional lessons |
| ---------------- | --------- | ----- | --------------- | ---------------- |
| 1                | 1         | 0     | 1               | 0                |
| 3                | 1         | 1     | 2               | 1                |
| 5                | 2         | 1     | 3               | 2                |
| 10               | 4         | 3     | 7               | 3                |
| 15               | 5         | 4     | 9               | 6                |
| 20               | 7         | 6     | 13              | 7                |
| 25               | 9         | 8     | 17              | 8                |
| 30               | 10        | 9     | 19              | 11               |
| 37               | 13        | 12    | 25              | 12               |

For stages of four or more lessons, the initial layout uses \\(\lfloor(N-1)/3\rfloor\\) forks, with one more keystone than forks. Remaining lessons become third alternatives or additional keystones.

These are authoring targets, not a reason to force unsuitable lessons into forks. Educational equivalence takes priority over visual symmetry.

### **What makes two lessons equivalent?**

Alternatives within a fork must satisfy the same educational objective.

| Criterion           | Requirement              |
| ------------------- | ------------------------ |
| Primary technique   | Identical                |
| Essential new skill | Identical                |
| Difficulty          | Comparable               |
| Goal tempo          | Within approximately 10% |
| Coordination demand | Comparable               |
| Boss preparation    | Interchangeable          |

For example, two patterns that independently develop alternating-hand sixteenths could form a fork. A basic alternating-hand pattern and a pattern introducing a new ghost-note technique could not.

If equivalence cannot be established, the relevant lesson becomes a keystone.

Small stages with only one or two lessons do not need artificial curricular branches. Their choices concern progression and additional practice instead.

## **1.4 The turn-based gameplay loop**

Choose a path

Play the existing lesson

Earn at least ★1

Record real progress

Offer 2–3 next actions

The map moves forward when the student completes a lesson with ★1. Reaching goal tempo is not required to take the next step.

After completing a keystone, the student receives the available fork choices. After completing a branch lesson, the student can rejoin the trunk, explore an available side trail or improve the lesson to goal tempo.

### **Example decision screen**

LEVEL 01 / GROOVE

PASSED

# **Choose your route.**

Cross the Anchor Bridge

Follow the Lantern Ditch

Reach goal tempo

At a three-way curricular fork, show all three branches and retain the normal lesson replay control elsewhere.

The choice screen must never contain more than three primary actions. No dialogue trees, lengthy explanations or simulated travel animations are necessary.

At a mandatory merge or the final lesson, progression and practice actions substitute for curricular alternatives. This is a deliberate exception to the requirement for multiple adventure paths: the curriculum cannot remain coherent if every mandatory node creates a new branch.

## **1.5 Progression and unlocking rules**

| Requirement                                  | Unlocks                                  |
| -------------------------------------------- | ---------------------------------------- |
| Intro lesson ★1                              | Next Intro lesson                        |
| All Intro lessons ★1                         | First Path stage                         |
| Keystone ★1                                  | Following fork or keystone               |
| One fork alternative ★1                      | Following merge node                     |
| Mandatory route completed at ★1              | Remaining mastery objectives highlighted |
| Every keystone ★2                            | Keystone mastery requirement fulfilled   |
| At least one alternative per fork ★2         | Fork mastery requirement fulfilled       |
| All mandatory mastery requirements fulfilled | Stage boss                               |
| Stage boss defeated                          | Next stage, subject to entitlement       |
| All 25 stage bosses defeated                 | Final boss                               |
| Two successful spaced memory reviews         | Lesson ★3                                |

The boss is deliberately placed **after ★2 mastery**, not after ★1 completion alone.

A student can explore the entire main route first, then return to any unfinished mastery objectives. The map highlights only the lessons still needed.

Any alternative within a fork can satisfy its mastery requirement. A student who initially chooses route A but later masters route B is not required to master route A.

### **Side-trail rewards**

Unchosen lessons remain available permanently after their fork is reached.

Side trails offer existing stars, XP, attribute development through real play and progress toward existing milestones. Their map nodes also reveal their short adventure titles when discovered.

Completing all side trails earns visual completion of that sub-level, but does not grant another currency, additional keys or a mandatory competitive advantage.

★3 remains entirely optional for campaign progression. Its purpose is long-term retention.

## **1.6 Free tier and Full unlock**

The free adventure contains the entire Intro and the first Path sub-level, including its boss, side trails and mastery objectives.

The student can earn keys and unlock available sound kits through legitimate free-tier progress.

At the end of stage 1, a student without Full unlock sees the remainder of the map but cannot enter paid Path lessons.

The only purchase gate is the existing one-time Full unlock. Keys never open curriculum content, and purchased lessons never require additional payment.

## **1.7 Keys and reward economy**

Tuning Keys are the only currency. They represent the student's growing authority over the instruments of the five clans.

The economy is finite, predictable and independent of grinding.

# **7**

Total keys available

# **7**

Locked sound kits

# **0**

Keys needed for lessons

### **Key distribution**

Five keys are earned through designated stage exams. Two are earned through milestones.

| Achievement                     | Keys  | Suggested kit    |
| ------------------------------- | ----- | ---------------- |
| Complete Intro at ★1            | 1     | Rock             |
| L1 · Groove boss                | 1     | 808              |
| L1 · Swing boss                 | 1     | Jazz             |
| L2 · Sixteenths boss            | 1     | House            |
| Defeat 10 distinct stage bosses | 1     | Brush            |
| L3 · Ghost notes boss           | 1     | World            |
| L4 · Fills boss                 | 1     | World Percussion |
| **Total**                       | **7** | **7 kits**       |

The suggested kit is the thematic reward associated with that achievement. The student can accept the recommendation, choose a different locked kit or save the key.

This preserves the existing rule of one key per kit while allowing bosses to present instruments as adventure rewards.

Keys are never earned repeatedly from the same achievement.

### **Economy during the first two levels**

Assuming normal campaign order and immediate spending:

| Checkpoint                           | Total keys earned | Available kits including Starter | Locked kits |
| ------------------------------------ | ----------------- | -------------------------------- | ----------- |
| New player                           | 0                 | 1                                | 7           |
| Intro completed                      | 1                 | 2                                | 6           |
| Groove I completed — free tier limit | 2                 | 3                                | 5           |
| Level 1 completed                    | 3                 | 4                                | 4           |
| Sixteenths II completed              | 4                 | 5                                | 3           |
| Level 2 completed                    | 5                 | 6                                | 2           |
| Level 3 completed                    | 6                 | 7                                | 1           |
| Level 4 completed                    | 7                 | 8                                | 0           |

Sound kit progression

Starting game

1/8

Intro

2/8

Free tier completed

3/8

Level 1

4/8

Level 2

6/8

Level 3

7/8

Level 4

8/8

All instruments become available before the final difficulty level. Level 5 is about mastery and prestige, not collecting resources.

### **Instrument skins**

Skins remain milestone rewards and cannot be purchased using keys.

| Existing skin | Proposed unlock               |
| ------------- | ----------------------------- |
| Skin 1        | First stage boss defeated     |
| Skin 2        | Five stage bosses defeated    |
| Skin 3        | Fifteen stage bosses defeated |
| Skin 4        | Final boss defeated           |

Existing bonus jam tracks should be distributed across campaign milestones, preferably the completion of each difficulty level. Their actual distribution depends on how many tracks already exist.

### **XP, ranks and attributes**

The existing Drummer card serves as the adventure's character sheet.

DRUMMER CARD

# **Beat Keeper**

LEVEL 08 · 1,240 XP

## **2**

TIMING

43

SPEED

27

TECHNIQUE

35

MEMORY

18

Illustrative player statistics

Attributes continue to grow exclusively from actual playing performance. Story decisions cannot artificially increase TIMING, SPEED, TECHNIQUE or MEMORY.

Boss fights are not RPG stat checks. A student never needs a specific character level or attribute value to enter a boss encounter.

## **1.8 Boss encounters**

Bosses are personifications of common drumming mistakes.

The student defeats them by demonstrating the corresponding musical skill, not by tapping arbitrary attack buttons or accumulating character power.

### **Encounter structure**

| Parameter                    | Rule                                            |
| ---------------------------- | ----------------------------------------------- |
| Patterns                     | 2–3 existing stage patterns                     |
| Length                       | 4–12 bars                                       |
| Count-in                     | One bar                                         |
| Transitions                  | Continuous, without pauses                      |
| Clean bar                    | At least 80% using the existing accuracy metric |
| Victory                      | At least 75% of bars played cleanly             |
| Perfect performance required | No                                              |
| Failure penalty              | None                                            |
| Retry limit                  | Unlimited                                       |
| Entry fee                    | None                                            |

Boss patterns are selected from the student's mastered keystones and fork alternatives. Selection prioritizes the central educational objectives of the sub-level.

Where the selected patterns total fewer than four bars, repeat the complete sequence until the encounter reaches at least four bars.

For an exceptionally small stage containing only one lesson, repeat that lesson as the boss sequence. No new pattern is created.

The sequence is shown before the attempt and remains unchanged on immediate retries.

### **Boss stamina**

Boss stamina represents the number of successfully performed bars required to win.

\\[ \text{Stamina}=\left\lceil 0.75\times\text{Total bars}\right\rceil \\]

Each clean bar removes one stamina unit. An unsuccessful bar removes nothing, but never restores stamina.

| Encounter length | Starting stamina | Clean bars needed | Unsuccessful bars allowed |
| ---------------- | ---------------- | ----------------- | ------------------------- |
| 4 bars           | 3                | 3                 | 1                         |
| 6 bars           | 5                | 5                 | 1                         |
| 8 bars           | 6                | 6                 | 2                         |
| 10 bars          | 8                | 8                 | 2                         |
| 12 bars          | 9                | 9                 | 3                         |

The student finishes the musical sequence even if the boss reaches zero stamina early.

### **Interactive stamina example**

BOSS ENCOUNTER / 01.01

# **BARON LATEBEAT**

STAMINA

6 / 6

ENCOUNTER PROGRESS

0/8 bars

1

2

3

4

5

6

7

8

6 more clean bars needed

Design simulator — test individual bar outcomes

4 bars6 bars8 bars12 bars

&#x20;Missed bar

&#x20;Clean bar

Reset encounter

### **Boss tempo**

The encounter uses a common baseline tempo derived from the lowest goal tempo among its selected lessons.

| Difficulty level | Boss baseline tempo      |
| ---------------- | ------------------------ |
| Level 1          | 85% of lowest goal tempo |
| Level 2          | 88%                      |
| Level 3          | 90%                      |
| Level 4          | 92%                      |
| Level 5          | 95%                      |

Round down to a whole BPM.

For example, if a Level 1 boss combines patterns with goal tempos of 80, 85 and 90 BPM, the encounter starts at 68 BPM.

The student has already demonstrated the patterns at their respective goal tempos. The slightly reduced boss tempo compensates for continuous transitions and the additional cognitive demands of the encounter.

### **Boss attacks**

There are only two attack mechanics.

# **68 → 70**

BPM

**Tempo Push**

The boss increases the tempo by approximately 3%, capped at +3 BPM, for one bar. It then returns to baseline. The tempo never exceeds the lowest selected goal tempo.

Warning: “Tempo push ahead.”

?

?

?

?

ONE BAR HIDDEN

**Pattern Veil**

The note prompts disappear for one bar. The pads, beat grid, metronome and position indicator remain visible.

The hidden bar must have already appeared visibly during the encounter.

Warning: “One bar hidden.”

| Level | Maximum attacks | Available mechanics |
| ----- | --------------- | ------------------- |
| 1     | 1               | Tempo Push          |
| 2     | 1               | Either mechanic     |
| 3     | 2               | Both mechanics      |
| 4     | 2               | Both mechanics      |
| 5     | 2               | Both mechanics      |

Attacks are announced one bar in advance. They cannot overlap, occur on the opening bar or appear without sufficient preparation.

If no suitable previously visible bar exists for Pattern Veil, use Tempo Push instead or omit the attack.

Attacks never alter the actual note pattern.

### **Losing a boss fight**

Failure does not reduce stars, XP, attributes, stamina outside the encounter, keys or unlocked content.

The failure screen offers up to three actions:

# **The beat continues.**

Nothing lost. Try again.

Retry the boss

Gentle attempt

Practice first

**Gentle attempt** disables boss attacks while retaining the same musical sequence, tempo and victory threshold.

A victory using Gentle attempt awards exactly the same progression and rewards. There is no inferior victory badge.

Boss attacks provide excitement, not a mandatory accessibility barrier.

### **Winning a boss fight**

A first victory awards the existing stage-exam completion, access to the next entitled stage, normal XP from actual playing, a boss victory marker and any associated key or milestone reward.

Repeated victories remain available for enjoyment and practice, but cannot duplicate keys or milestone rewards.

Boss performances do not automatically grant ★3 or replace spaced memory reviews.

## **1.9 The final boss**

**The Grand Miscount**

The final boss becomes available after all existing Path stages and their bosses have been completed.

It combines three previously mastered patterns from three different technique regions.

| Parameter                     | Final encounter                   |
| ----------------------------- | --------------------------------- |
| Patterns                      | 3                                 |
| Length                        | 4–12 bars                         |
| Baseline tempo                | 95% of lowest selected goal tempo |
| Maximum attacks               | 2                                 |
| Victory requirement           | 75% clean bars                    |
| Gentle attempt                | Available                         |
| Exclusive reward              | Final instrument skin             |
| Rank or attribute requirement | None                              |

The final encounter is a celebration of accumulated skill, not an artificial difficulty spike.

Defeating the final boss does not automatically grant the Master Percussionist rank. Existing rank progression remains independent.

All previously discovered regions, bosses and side trails remain replayable after the campaign ends.

## **1.10 Switching between Story and Free practice**

Story and Free practice are two interfaces to the same student progress.

| Action                             | Result                                                              |
| ---------------------------------- | ------------------------------------------------------------------- |
| Story → Free practice              | All lessons within the purchase tier become accessible.             |
| Free practice → Story              | Previously earned stars and attributes remain.                      |
| Earn ★2 in Free practice           | Automatically fulfills the corresponding Story mastery requirement. |
| Earn ★3 in either mode             | Counts toward the same memory progression.                          |
| Pass a stage exam in Free practice | Counts as the corresponding boss victory.                           |
| Earn a milestone in either mode    | Rewards are shared.                                                 |
| Unlock a kit in either mode        | Available in both modes.                                            |

Free practice also provides access to existing stage exams within the player's purchase entitlement.

The student never has to repeat an already completed lesson simply because they changed modes.

Story requirements control the guided map, not the underlying ownership or validity of progress.

## **1.11 Existing players and save migration**

When an existing player opens Story mode for the first time, the campaign is reconstructed from their actual lesson progress.

For each fork, select the alternative with the highest earned star count as the player's provisional route. Resolve ties using existing lesson order. Other alternatives remain available as side trails.

| Existing progress                 | Story placement                       |
| --------------------------------- | ------------------------------------- |
| No progress                       | Beginning of Intro                    |
| Partially completed Intro         | Next unfinished Intro lesson          |
| Existing Path progress            | Skip the Intro requirement            |
| All mandatory route lessons at ★2 | Boss immediately available            |
| Previously passed stage exam      | Boss already defeated                 |
| Progress in later stages          | Display it on the map and retain it   |
| Entire Path mastered              | Present remaining exams or final boss |

The recommended current location is the earliest unfinished accessible campaign objective. Previously unlocked Story stages must not be relocked.

Existing stars, XP, levels, ranks, keys and purchased or earned instruments are preserved. Previously granted rewards must not be duplicated.

If a legacy save already contains more keys than the new economy requires, retain them. Do not confiscate them or invent a new spending system to absorb them.

## **1.12 Visual and UX principles**

Story mode should resemble the interface of a professional piece of musical hardware.

**Signal orange**

Active route, success, focus

**Black**

Hardware, panels, structure

**White**

Text, contrast, negative space

Intermediate neutral tones are derived from black and white. No additional chromatic colors.

Use geometric symbols, pad-shaped nodes, signal paths, thin connecting lines and restrained typography.

Represent boss characters using distinctive monochromatic emblems rather than elaborate fantasy portraits. Their names and behavior establish their personalities.

The presentation should avoid decorative fantasy menus, dialogue bubbles, particle effects, glowing gradients, floating XP notifications and generic RPG inventory screens.

Recommended screen transitions are 150–300 ms. Every animation should be skippable or non-blocking.

Story cards appear once when entering a sub-level and remain accessible from its map. Boss dialogue appears once per first encounter or victory, not on every retry.

# **2. World bible**

## **2.1 Premise**

The world was once governed by the Great Pulse, an ancient rhythm that kept everything reasonably on time. Five percussion clans maintained it until a catastrophic disagreement over a count-in shattered their alliance. Their instruments fell silent, and musical mistakes acquired physical bodies and positions of considerable authority. An inexperienced drummer must travel through the five realms, restore their instruments and demonstrate the ancient discipline of playing properly. The fate of civilization now rests upon two hands and an unexpectedly demanding hi-hat.

## **2.2 The five regions**

The regions represent techniques rather than musical genres. Each contains its own strange inhabitants, architecture and drumming philosophy.

REGION I · GROOVE

**The Anchor Marches**

Endless bridges, marching settlements and a population that considers losing the beat a municipal offence.

*Mood: industrial, grounded, solemn.*

REGION II · SIXTEENTHS

**The Sixteenth Foundry**

An immense mechanical kingdom where every second is officially divided into smaller, more productive seconds.

*Mood: precise, mechanical, relentless.*

REGION III · GHOST NOTES

**The Whisper Crypts**

A sacred underground civilization where silence is powerful, and unnecessarily loud visitors are deeply embarrassing.

*Mood: restrained, mysterious, delicate.*

REGION IV · SWING

**The Crooked Coast**

A coastline where roads bend, clocks lean sideways and perfectly straight subdivisions are regarded with suspicion.

*Mood: elastic, eccentric, relaxed.*

REGION V · FILLS

**The Fractured Peaks**

Mountain clans communicate through elaborate drum fills, occasionally forgetting to return to the original conversation.

*Mood: explosive, dramatic, controlled chaos.*

## **2.3 The mentor**

## **Master Rimble**

Keeper of One

A retired clan drummer, former examiner and self-appointed guardian of the first beat.

He regards rhythm as a public responsibility. He never raises his voice and is almost impossible to impress.

Rimble introduces each region through its short story card. He does not interrupt performances or deliver extended tutorials.

His humor comes from absolute seriousness about ridiculous circumstances.

Examples of his voice for future writing:

> The bridge is unstable. Fortunately, the tempo is not.

> That was a fill. Returning was also required.

> We do not negotiate with the metronome.

These are editorial voice references, not additional mandatory on-screen dialogue.

## **2.4 The bosses**

Five recurring antagonists return in stronger forms at each difficulty level.

This creates recognizable rivals without requiring 25 entirely independent characters or sets of artwork.

**Baron Latebeat**

Groove · Tempo dragging

An aristocrat who considers arriving after the beat a privilege of his rank.

**The Flam Twins**

Sixteenths · Unintended flams and uneven spacing

Two officials permanently attempting to occupy the same subdivision.

**The Whisper Wraith**

Ghost notes · Poor dynamic control

An ancient spirit that confuses subtle percussion with either silence or shouting.

**The Rushing Magistrate**

Swing · Rushing and rigid subdivision

A coastal judge who repeatedly reaches conclusions before the music does.

**The Spill Hydra**

Fills · Overplaying and losing the downbeat

A many-headed percussionist whose fills cannot agree on where to end.

### **Complete boss roster**

| Level | Groove               | Sixteenths            | Ghost notes           | Swing                  | Fills                |
| ----- | -------------------- | --------------------- | --------------------- | ---------------------- | -------------------- |
| I     | Baron Latebeat       | The Flam Twins        | The Whisper Wraith    | The Rushing Magistrate | The Spill Hydra      |
| II    | Latebeat the Overdue | The Double Flam       | The Unquiet Wraith    | The Hasty Magistrate   | Hydra of Three Fills |
| III   | Duke Latebeat        | The Subdivision Twins | The Thunder Wraith    | The Crooked Magistrate | Hydra of Seven Fills |
| IV    | Archduke Latebeat    | The Relentless Twins  | The Shouting Silence  | The Premature Verdict  | The Endless Hydra    |
| V     | Latebeat the Eternal | The Infinite Flam     | The Deafening Whisper | The Final Rush         | Hydra Without End    |

### **Final antagonist: The Grand Miscount**

A mysterious entity that has spent centuries insisting the song begins on a different beat.

It embodies accumulated rhythmic confusion: dragging, rushing, unintended doubles, dynamic instability and fills that never return home.

All boss forms reuse their corresponding core emblem. Increasing difficulty can be expressed through Roman numerals, additional geometric markings and more severe titles.

Their fictional mistakes must never introduce scoring requirements unsupported by the existing playback evaluator.

## **2.5 The instruments of the clans**

Each existing sound kit is an ancient instrument configuration preserved by one of the world's percussion orders.

Starter — The Common Drum

The instrument entrusted to every apprentice.

Rock — The Iron Assembly

Built to withstand considerable enthusiasm.

808 — The Buried Engine

Its foundations are audible underground.

House — The Endless Hall

Its ceremonies rarely end before morning.

Jazz — The Crooked Brass

Officially unpredictable. Unofficially precise.

Brush — The Quiet Council

Its loudest members are barely audible.

World — The Wandering Circle

Preserves the rhythms of distant clans.

World Percussion — The Gathering of Hands

Many traditions, one shared pulse.

These fictional instrument names are primarily world-building references. The kit selector should retain the recognizable existing kit names.

### **Tuning Keys**

Tuning Keys are physical drum tuning tools passed down by the clan masters.

Receiving one signifies that a drummer may be trusted with another instrument. They are not magical coins, gemstones or commercial tokens.

Instrument skins represent ceremonial finishes granted to accomplished drummers.

Jam tracks represent gatherings where the clans invite the student to perform alongside them.

# **3. Fully written sample**

## **Level 1 · Groove**

**Region:** The Anchor Marches\
**Sub-level:** The Unsteady Crossing\
**Boss:** Baron Latebeat

For this sample, a ten-lesson stage is assumed. The actual Level 1 Groove lesson inventory was not supplied, so the lesson identifiers and educational objectives below are illustrative placeholders for existing content.

No new patterns are proposed.

## **3.1 Map structure**

Four keystones, three binary forks, three optional side trails and one boss.

01.01

## **THE ANCHOR MARCHES**

The Unsteady Crossing

MAIN ROUTE · 7 LESSONS3 SIDE TRAILS

Illustrative progress

2 / 7

## **3.2 Lesson assignments**

| Node    | Existing lesson slot | Educational purpose               |
| ------- | -------------------- | --------------------------------- |
| K1      | 01                   | Establish the basic pulse         |
| Fork 1A | 02                   | Maintain the established pulse    |
| Fork 1B | 03                   | Equivalent pulse exercise         |
| K2      | 04                   | Establish kick/snare coordination |
| Fork 2A | 05                   | Consolidate coordination          |
| Fork 2B | 06                   | Equivalent coordination exercise  |
| K3      | 07                   | Establish a sustained groove      |
| Fork 3A | 08                   | Maintain groove across bars       |
| Fork 3B | 09                   | Equivalent groove exercise        |
| K4      | 10                   | Consolidate stage objectives      |
| Boss    | Stage exam           | Combine mastered patterns         |

Actual assignments require verification against the existing lesson catalog.

The resulting stage has eight possible main routes. All eight teach the same essential objectives.

## **3.3 Every fork line**

Each option uses a monochromatic icon and one short line of English text.

| Fork | Icon     | Exact on-screen text        | Words |
| ---- | -------- | --------------------------- | ----- |
| 1A   | Anchor   | Cross the Anchor Bridge     | 4     |
| 1B   | Lantern  | Follow the Lantern Ditch    | 4     |
| 2A   | Shield   | Join the Pail Guard         | 4     |
| 2B   | Ship     | Board the Tin Ferry         | 4     |
| 3A   | Windmill | Investigate the Silent Mill | 4     |
| 3B   | Tower    | Climb the Watch Tower       | 4     |

All six lines become reusable map labels or tooltips. They also identify side trails when the student returns to the stage.

The selected branch changes the lesson played, not the stage's educational requirements.

### **Preview the route selection**

FORK 1

Cross the Anchor BridgeFollow the Lantern Ditch

FORK 2

Join the Pail GuardBoard the Tin Ferry

FORK 3

Investigate the Silent MillClimb the Watch Tower

## **3.4 Shared navigation lines**

The following exact lines are used where a curricular fork is not appropriate.

| Situation                          | On-screen choices                                  |
| ---------------------------------- | -------------------------------------------------- |
| Keystone passed                    | Fork A / Fork B / Reach goal tempo                 |
| Branch passed at ★1                | Rejoin the trail / Other branch / Reach goal tempo |
| Branch passed at ★2                | Rejoin the trail / Other branch                    |
| Consecutive keystones              | Continue the trail / Reach goal tempo              |
| Route finished, mastery incomplete | Reach goal tempo / Explore side trail              |
| Route fully mastered               | Face the boss / Explore side trail                 |
| Boss failed                        | Retry the boss / Gentle attempt / Practice first   |
| Boss defeated                      | Open the next gate / Return to the map             |

Only applicable actions appear. An unavailable side trail or already completed mastery objective is not presented as a choice.

## **3.5 Story card**

Shown when entering the sub-level for the first time.

THE ANCHOR MARCHES

# **The Unsteady Crossing**

The Anchor Marches have been waiting for a beat since Tuesday.

Baron Latebeat insists this is punctual.

Master Rimble disagrees.

Keep the pulse, and the bridges will recognize your authority.

Enter the Marches

## **3.6 Boss encounter**

**Boss:** Baron Latebeat

**Musical mistake:** Tempo dragging.

**Lesson selection:** Two or three mastered patterns emphasizing a consistent pulse and uninterrupted groove.

**Example configuration:**

| Parameter           | Value                 |
| ------------------- | --------------------- |
| Selected patterns   | 3                     |
| Pattern lengths     | 2 + 2 + 4 bars        |
| Example goal tempos | 80 / 85 / 90 BPM      |
| Starting tempo      | 68 BPM                |
| Starting stamina    | 6                     |
| Maximum attacks     | 1                     |
| Attack tempo        | 70 BPM for one bar    |
| Victory             | 6 clean bars out of 8 |
| Key reward          | 1                     |

### **Boss introduction**

> The Baron has arrived late to his own ambush. Hold the pulse.

### **Victory lines**

> The Baron is on time for his defeat. The bridge recognizes your authority.

### **First-victory reward screen**

STAGE 01.01 / COMPLETE

# **BARON DEFEATED**

The bridge recognizes your authority.

# **+1 Tuning Key**

RECOMMENDED CLAN INSTRUMENT

# **808**

The Buried Engine

Cost: 1 Tuning Key

Claim instrument

Choose another kit · Save key

For free-tier players, this is the conclusion of the available campaign chapter. They can continue practicing, mastering side trails, completing memory reviews and using their earned kits.

# **4. Text budget**

The adventure should be economical in writing and localization. Its world is communicated through names, route choices and isolated story cards rather than ongoing dialogue.

## **4.1 Writing limits**

| Text type              | Maximum length          |
| ---------------------- | ----------------------- |
| Fork option            | 8 words                 |
| Story card             | 45 words, 3–5 sentences |
| Boss introduction      | 16 words, 1–2 sentences |
| Boss victory           | 16 words, 1–2 sentences |
| Boss name              | 5 words                 |
| Region name            | 4 words                 |
| Shared navigation line | 8 words                 |
| Mentor name and title  | 5 words                 |

There are no written conversations between characters, unique lesson introductions, separate side-trail stories or procedural narrative events.

## **4.2 Whole-game localization estimate**

With approximately 540 Path lessons, the recommended map structure produces no more than approximately 360 unique fork options before any necessary curriculum adjustments.

| Text category                       | Unique entries | Maximum words |
| ----------------------------------- | -------------- | ------------- |
| Fork options                        | 360            | 2,880         |
| Sub-level story cards               | 25             | 1,125         |
| Sub-level titles                    | 25             | 125           |
| Boss introductions                  | 26             | 416           |
| Boss victories                      | 26             | 416           |
| Boss names                          | 26             | 130           |
| Region names                        | 5              | 20            |
| Mentor name and title               | 1              | 5             |
| Shared Story UI lines               | 30             | 240           |
| Reward terminology and kit epithets | 12             | 48            |
| Campaign title                      | 1              | 5             |
| **Total**                           | **537**        | **5,410**     |

This is a planned editorial ceiling, not an exact count of a completed script. Actual totals depend on the verified lesson inventory and number of valid forks.

Maximum narrative text budget

## **5,410 words**

Fork options

2,880 words

53%

Story cards

1,125 words

21%

Boss dialogue

832 words

15%

Names and UI text

573 words

11%

**Recommended actual writing target: 3,500–4,200 English words.**

The maximum should be treated as a ceiling, not a target to fill. Most fork lines can be four or five words long, as demonstrated in the sample.

## **4.3 Czech adaptation**

Czech localization should prioritize the same deadpan humor rather than literal translation of every fantasy name.

| English            | Possible Czech adaptation |
| ------------------ | ------------------------- |
| Baron Latebeat     | Baron Pozdorytmus         |
| The Anchor Marches | Kotevní marky             |
| The Flam Twins     | Dvojčata Flamova          |
| The Whisper Crypts | Šeptající krypty          |
| The Grand Miscount | Veliký Přečet             |
| Master Rimble      | Mistr Rimble              |
| Tuning Key         | Ladicí klíč               |

These Czech names are provisional creative directions, not finalized localization.

Reserve approximately 30% additional horizontal text space for localization. A longer Czech line should be rewritten rather than displayed using a smaller font.

All narrative strings should be authored independently of the lesson data and musical notation, so translation cannot inadvertently modify the curriculum.

# **5. Open questions and risks**

1\. **Lesson equivalence is the largest design dependency.** The existing 540 lessons need to be classified by educational purpose before constructing the actual map. Some stages may support fewer meaningful forks than the proposed distribution.

2\. **Existing stage unlock thresholds.** This design proposes ★2 on every keystone and at least one alternative per fork. Any already implemented numerical stage threshold must be reconciled with this rule rather than silently replaced.

3\. **MIDI velocity and ghost notes.** If the current evaluator does not reliably support dynamic accuracy across MIDI controllers and on-screen pads, ghost-note bosses must use the existing supported performance metric.

4\. **Boss scoring and continuous playback.** Per-bar accuracy, seamless pattern transitions and temporary tempo changes need to be supported. These are design requirements whose current implementation status has not been verified.

5\. **The existing reward economy.** Seven total keys is a proposed finite economy for new players. Existing reward schedules and legacy saves need reconciliation before adopting it.

6\. **Branch choices may become cosmetic.** Every alternative should have a recognizable musical or practical difference while retaining the same educational purpose. Otherwise, players will stop caring which route they select.

7\. **Boss difficulty needs beginner playtesting.** The proposed 75% clean-bar threshold and reduced tempos are starting values. Test with actual adult beginners, not exclusively experienced drummers.

8\. **The adventure could overwhelm the trainer.** Story mode succeeds only if it gets students playing more frequently. Extra screens, excessive navigation, reward interruptions and unnecessarily long animations should be removed even when they appear entertaining in isolation.

**Core design principle:** The adventure may be absurd. The rhythm education must remain serious.

Smack-a-Pad should reward the student for becoming a better drummer, with the satisfaction of defeating a ridiculous aristocrat serving as an additional reason to keep practicing.