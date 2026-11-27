# 252 — Story key economy (7 keys), kit claim screen, skins by bosses

Status: open · after 251

Design source: `docs/design/2026-11-26-story-mode-gdd-v1.md` — the **Amendments** section at its top is binding and wins over the draft below it.

## Goal

Replace the current key schedule (1 key per stage exam + 8 milestone keys ≈ 32) with the finite economy of GDD §1.7 (Amendment 4), and let a boss victory present its kit as a reward.

## Rules

1. **Keys (total 7, each earned once):** Intro completed at ★1 → 1; L1 Groove boss → 1; L1 Swing boss → 1; L2 Sixteenths boss → 1; 10 distinct stage bosses defeated → 1; L3 Ghost notes boss → 1; L4 Fills boss → 1. No other source of keys. Remove `rewardKeys` from the other milestones and stage exams (milestones stay as achievements).
2. **Legacy saves:** keys already earned or spent stay (never negative, never taken away, never duplicated). Already unlocked kits stay unlocked.
3. **Kit claim screen** after a key-awarding victory: "+1 Tuning Key", the suggested kit (GDD table: Rock, 808, Jazz, House, Brush, World, World Percussion), buttons "Claim instrument" / "Choose another kit" / "Save key". Kit selector keeps the real kit names; the clan epithets (GDD §2.5) are a small subtitle.
4. **Skins:** Midnight MPC → first boss defeated; Cream Vintage → 5 bosses; Acid Rack → 15 bosses; the final-boss skin stays locked until the final boss exists (keep it hidden, not "coming soon"). Bonus jam tracks keep their current rules.
5. Same rules in Story and Free practice; backup export/import and merge carry the new fields.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Progression/DrummerPathEvaluator.swift`, `SmackAPad/Sources/Progression/DrummerPathModels.swift`, `SmackAPad/Sources/Progression/StudioRigCatalog.swift`, `SmackAPad/Sources/Persistence/ProgressMerge.swift`, `SmackAPadTests/DrummerPathTests.swift`.

## Tests

Update `DrummerPathTests`: exactly 7 keys reachable; each source once; legacy save with more keys keeps them; kit claim/choose/save; skins by boss counts; backup round-trip. Narrow tests while working, full `SmackAPadTests` once at the end.

## Acceptance criteria

- [ ] Only the 7 listed sources award keys; legacy keys and kits preserved.
- [ ] Kit claim screen after a key-awarding boss victory works with all three choices.
- [ ] Skins unlock by boss count; builds, `SmackAPadTests` passes on the iPad simulator.

### Manual iPad checks for Jakub (no good playing needed)

- Your real profile: keys and kits you have are still there.
- Debug scenario with an open L1 Groove boss: win in Gentle attempt (or use the debug win if 251 adds one) → kit claim screen with 808 suggested.

## Agent assignment

Antigravity: **Gemini 4 Hydrogen, thinking medium** (wrote ticket 241's model). Fallback: Codex Sol 6.2, medium.

## Done rule

Build, full test suite once, commit on `release-polish`, report changed files concisely.
