# 253 — Story texts in English (brief for ChatGPT, design only)

Status: open · after 249 (needs the final story map)

## How to run this

- Where: **ChatGPT**, normal chat (not Work/Codex). Model: strongest reasoning model, **thinking medium** (creative writing gains little from high).
- Before pasting, attach two files: `docs/design/2026-11-26-story-mode-gdd-v1.md` and the fork list `tools/story_map/fork-list.md` (stage → each fork's lesson titles, genre, tempo; generate it with `tools/story_map/generate.py --export-forks` — if that option does not exist yet, ask Claude to add it before running this brief).
- Bring the answer to Claude: it checks length limits, keys and tone, then an agent puts the strings into the app.

---

PROMPT START

You are the writer for the Story mode of the finger-drumming trainer Smack-a-Pad. The attached GDD defines the world (The Five Realms of Rhythm, Master Rimble, the boss roster) and its **Amendments section is binding** (23 stages, Baron Latebeat only levels I–III). The attached fork list gives every fork of every stage with its lessons.

Write all English on-screen story text:

1. For each of the 23 stages: sub-level title (≤ 4 words), story card body (3–5 sentences, ≤ 45 words), boss intro (≤ 16 words), boss victory (≤ 16 words).
2. For each fork: one line per alternative (≤ 8 words, ideally 4–5), each with a suggested monochrome icon (SF Symbols name). Alternatives of one fork must feel like different routes in the same region; a line may hint at the lesson's musical character (genre, feel) but never names drum terms the student has not met.
3. Final boss (The Grand Miscount): intro and victory.

Tone: deadpan, comically bizarre fantasy that takes itself seriously; Master Rimble's dry voice; no dialogue trees; original names only.

Output as one table per stage plus a final machine-readable block in this exact format, one string per line:
`"story.card.<stageId>.title" = "...";`
`"story.card.<stageId>.body" = "...";`
`"story.boss.<stageId>.intro" = "...";`
`"story.boss.<stageId>.victory" = "...";`
`"story.fork.<stageId>.<forkIndex>.<a|b|c>" = "...";`
`"story.fork.<stageId>.<forkIndex>.<a|b|c>.icon" = "...";`
Stage ids and fork indexes exactly as in the fork list. End with the total word count.

PROMPT END
