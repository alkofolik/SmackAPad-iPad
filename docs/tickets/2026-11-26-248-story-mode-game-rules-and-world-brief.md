# 248 — Story mode: game rules and world bible (brief for ChatGPT, design only, no code)

Status: open

## How to run this

- Where: **ChatGPT**, a normal chat (not Work/Codex, so it does not eat the Codex allowance).
- Model: the strongest model with reasoning on offer in the picker, **thinking high**.
- Paste everything below the line "PROMPT START". Bring the answer back to Claude for a check against the code before any coding ticket is written.

---

PROMPT START

You are a senior game designer for a music-education app. Design the **Story mode** of an iPad finger-drumming trainer called **Smack-a-Pad**. Output design documents only, no code.

### The app today (facts, do not change them)

- The student plays drum patterns on a MIDI pad controller (or on-screen pads). Each lesson is one pattern (1–4 bars) with a start tempo and a goal tempo.
- Content: about 25 Intro lessons, then a Path of about 540 lessons in **5 levels × 5 techniques** (groove, sixteenths, ghost notes, swing, fills) = up to 25 **stages**; stage sizes vary from a few to ~37 lessons. Genre extensions exist (rock, funk, jazz, hip-hop, world, electronic, pop).
- Stars per lesson: ★1 = run passed with ≥ 80 % at any tempo; ★2 = clean run at goal tempo; ★3 = review (played from memory, two spaced reviews on separate days). A lesson counts toward opening the next stage at ★2.
- Purchase: free tier = Intro + Path stage 1; one-time Full unlock opens the rest. Story rules must never lock content behind money beyond this.
- Already built (data model): a Drummer card with XP, levels, ranks (Pad Rookie → Beat Keeper → Pocket Player → Session Drummer → Groove Architect → Master Percussionist) and four attributes 0–100 that only grow, computed from real play: TIMING, SPEED, TECHNIQUE, MEMORY. **Keys** earned from stage exams and milestones. 8 sound kits: Starter (acoustic) open, Rock, 808, House, Jazz, Brush, World, World Percussion locked; 1 key = 1 kit. 4 instrument skins and bonus jam tracks unlocked by milestones. A Path map with stage blocks and a final boss-exam node.
- Two modes: **Story** (default; the app guides, lessons open step by step) and **Free practice** (switch in Settings; everything per purchase tier). Progress counts in both modes.
- Kits never block a lesson. In Story mode a lesson whose kit is still locked plays on the Starter kit; bosses award kits as story rewards.
- Visual style: only orange, black and white, hardware-controller look; no generic "AI look". The UI must stay calm: the owner does not want more text on screen.
- The primary student is a beginner adult. English is the main language; a Czech adaptation follows later.

### What the owner wants

1. **Guided, turn-based adventure.** After finishing a lesson (★1) the student picks one of **2–3 offered paths** (one short line each with an icon), and the map moves on.
2. **Branch-and-merge structure** so content does not explode: each sub-level has keystone lessons on the trunk and forks between them; all branches meet at the boss. Forks offer only lessons of equivalent purpose, so any choice prepares the student for the boss. Unchosen branches stay on the map as optional side trails (extra reward or story crumb).
3. **Use only existing lessons.** Choices change order and selection, not content. New writing = fork lines + one short story card per sub-level + boss intro/outro.
4. **Boss fights** at the end of each sub-level, beginner-friendly: never demand a perfect run, losing costs nothing (retry at once). Idea to develop: a medley of 2–3 patterns from the sub-level without pause; the boss has a stamina bar that drops with each clean bar; boss "attacks" = a slight tempo push or one bar of the pattern hidden. Bosses are personified drummer mistakes (e.g. a tempo-dragger, a rusher, flam twins, a ghost-note wraith, an over-loud hi-hat hydra).
5. **Tone:** comically bizarre fantasy that takes itself dead seriously, mixed with finger-drumming lore. Original world and characters only, no parodies of existing franchises or real people. Keys are drum tuning keys in the fiction.
6. Keys are **never** sold for real money. One currency only (keys); no second currency.

### Deliver (markdown, in this order)

1. **Rules document** with concrete numbers: sub-level size and shape (how many keystones, forks, side trails); how stages map to sub-levels for stages of very different sizes; what opens what in Story mode; when keys are earned and how many in total vs. kits/skins to buy (show the balance for the first two levels); boss rules (stamina, attacks, win condition, no-loss retry, what a win awards, how boss tempo relates to the lessons' goal tempo); what happens when a student switches to Free practice and back; how existing players with lots of progress are placed on the map.
2. **World bible:** premise in 5 sentences; one region per technique (5) with a mood line; mentor character; list of bosses (one per technique × level is allowed to reuse a boss with a stronger form); the rewards in fiction (tuning keys, kits as "instruments of the clans").
3. **Fully written sample:** Level 1 · groove — the map shape, every fork line (≤ 8 words each, EN), the story card (3–5 sentences), boss intro and victory lines (≤ 2 sentences each).
4. **Text budget:** total word count of all story text for the whole game, so the Czech adaptation can be planned.
5. **Open questions and risks** you see, max 8 bullets.

Keep every on-screen line short. Avoid vague advice; give numbers and examples.

PROMPT END

## After ChatGPT answers

1. Claude checks the rules against the code (Path map model, keys, kits, stars, purchase tier) and lists conflicts.
2. Jakub approves or edits.
3. Then coding tickets: branching map, boss fight, story cards, Czech adaptation (Gemini 4 Argon, medium; Claude checks the tone).
