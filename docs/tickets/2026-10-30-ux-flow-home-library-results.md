# 17 — UX Flow: Home, Library Layout, Lesson Result (Melodics-inspired)

Status: ON HOLD (2026-10-30) — to be rewritten after the practice screen (ticket 11); it must then use the three-star model and drop the old Result screen. Prompts B7–B10 are obsolete.

## Goal

Add the screens and flows that sit around the play screen: a Home screen, a clearer Library layout, and a lesson result screen. Take the *structure* from a review of Melodics (screen recording, 2026-10-30), never the look. Look stays as in `docs/DESIGN-BRIEF.md` (orange / black / white, reject list).

## Files to read

- `AGENTS.md`
- `docs/DESIGN-BRIEF.md`
- `docs/SPEC.md` (§3.5–3.8, §5 scoring)
- `docs/DECISIONS.md` (§3, §7, §15, §16, §20)
- Tickets 05, 11, 12, 14 (this ticket extends them; it does not replace them)

## What Melodics does (reference only)

- **Top bar:** Home, Guided, Explore, Progress, Settings, instrument switcher, user + level.
- **Home:** hero carousel "New lesson" with a small "Resume from last session / Continue" card; below it "How are you progressing": month practice calendar, current + best day streak, lesson stars and stars left to the next level.
- **Explore:** Lessons / Songs switch, browse by grade or genre, jump-to, favourites, search, grid/list toggle. Card = cover, skill tag, Play, stars, audio preview, progress bar.
- **Guided:** vertical path of courses with % complete; also a plain course grid.
- **Lesson:** (1) step intro with the used pads highlighted on a pad grid, a hands/fingers drawing and one sentence ("Step 4 of 5"); (2) performance: one horizontal lane per pad, notes scroll to a fixed hit line, hits turn green with a pulse, streak counter, thin progress bar, side sliders (metronome, your notes, guide notes, backing), Performance/Practice tabs, only back/pause/restart as controls; (3) result: "Lesson passed 80/100", stars, three actions (listen back, try again, practice), three more (next, playground, exit), breakdown perfect/early/late/misplaced/best streak, line chart of recent attempts with a short verdict.

## What we take, what we skip

| Take | Skip (and why) |
|---|---|
| Home with one big "Continue" and a progress block | Hero carousel, marketing banners (not our tone) |
| Practice calendar + day streak | Level/XP system (we have categories + soft unlock) |
| Result screen: score, pass/mastery state, breakdown, 3 clear next actions | Mascots, emoji mood icon, confetti (brief forbids) |
| Breakdown early / late / wrong pad / best streak | Green/red status colours (brief: feedback by position, size, shape) |
| Library: filters, search, favourites, list/grid toggle | Songs, Courses, Guided Path (no such content in v1; lessons are single patterns, SPEC §4.1) |
| Play: hidden controls, only back / pause / restart visible | Multi-step lessons "Step 4 of 5" (our lesson = one pattern with tempo ramp) |
| Play: fixed hit line + scrolling lanes | Hand/finger drawings (we teach rhythm, not fingering) |
| Practice/Performance split | — consider later; not v1 |

Note: our lesson model has no steps. Do not invent a step system. The tempo ramp (SPEC §5) plays the role of "progress inside a lesson"; show it as a thin progress strip.

## Tasks

1. **Navigation shell**: iPad-first. Sidebar or bottom bar with Home, Library, Intro, Progress, Settings. Large touch targets. Landscape primary, portrait supported.
2. **Home screen**:
   - One large orange "Continue" card: last lesson, category, current BPM → target BPM, best score.
   - Below: month practice calendar, day streak (current + best), passed/mastered counts per category.
   - Second row: "Recommended next" (next unpassed lesson in the current category) and Intro entry.
3. **Library layout** (extends ticket 12; data and lock rules stay as in 12):
   - Filters: category, genre, level; search; favourites toggle; list/grid toggle.
   - Row/card: title, genre, level, pass/mastery badge, best score, BPM progress. Not a uniform grid of identical rounded cards (reject list): use list rows with a strong typographic hierarchy.
4. **Result screen** (after a run, shown over/after the play screen):
   - Score as a large number and the pass/mastery state shown as text (use SPEC §5 thresholds; do not invent stars or new thresholds).
   - Breakdown: perfect / early / late / wrong pad counts, best streak.
   - Last attempts as a simple line or bar strip with one short verdict line.
   - Actions: Try again, Next BPM / Next lesson, Back to library. Optional: Listen back (only if the audio engine can replay the take; otherwise skip).
5. **Play screen additions** (small, on top of ticket 11): thin lesson-progress strip, streak counter that stays small and peripheral, and a visible set of three controls (back, pause, restart); everything else stays one touch away.
6. All styling through `Theme.swift` tokens. Feedback by position, size and shape; no status colours.

## Out of scope

Songs, courses, guided path, multi-step lessons, XP/levels, content store, social features.

## Acceptance criteria

- [ ] Home shows Continue, calendar, streak, recommended next, Intro entry.
- [ ] Library has filters, search, favourites, list/grid toggle; lock/unlock behaviour from ticket 12 unchanged.
- [ ] Result screen shows score, pass/mastery state, breakdown, best streak and three actions.
- [ ] Nothing from the "AI look" reject list; only orange / black / white + derived greys.
- [ ] Works in light and dark variant, landscape and portrait.
- [ ] **iPad test**: all screens render correctly on iPad.

## Visual reference

Direction B (Cut Tape) was chosen. Image prompts for Home and Result: `docs/design/2026-10-30-direction-b-home-result-prompts.md` (images B7–B10). Jakub generates them and adds the chosen images to `docs/design/` before this ticket goes to an agent.

## Dependencies

After tickets 05 (progression), 08 (scoring), 11 (theme + play screen). Coordinate with 12 and 14: either run this first and let 12 consume the Library layout, or run 12 first and treat task 3 as a follow-up.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high (with gpt-taste skill), same as ticket 11.
- **Reasoning**: high. This is design-sensitive SwiftUI that has to respect the brief and the existing tokens; low reasoning tends to produce the generic look the brief rejects.

## Done rule

Stop after successful build; Jakub tests on iPad.
