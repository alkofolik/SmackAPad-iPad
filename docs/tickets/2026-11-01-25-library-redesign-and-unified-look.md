# 25 — Library redesign, unified look across screens, Intro rows, unlock flow

Status: part-A-ready-for-human; part B pending in a separate conversation (2026-11-01). Ticket 24 prerequisite verified at commit `252a6b2`. Ticket 26 is independent.

## Goal

Jakub's verdict on the library (ticket 19): fonts mixed and unordered, chaotic layout, almost no lessons visible at once, a locked stage fills the page so only one lesson can be read, space badly used, Intro rows look different and show only two stars, two competing unlock prompts. Fix all of it and make the other screens follow the same system ("not every dog a different village").

## 1. One visual system (do this first, the rest builds on it)

Add to `Theme.swift` a small type scale and shared components, then use them everywhere listed below. No new colours (orange, black, white; existing result shades only).

- **Type roles** (replace the ad-hoc `Theme.display(Theme.Size.x)` / `Theme.text(...)` mixing): `screenTitle`, `sectionTitle`, `rowTitle` (Avenir Heavy 18), `meta` (Menlo 13-14), `control` (Menlo 16-18). Rule: **titles and names are Avenir Heavy, data, numbers and labels are Menlo**, nothing else. Max 5 distinct sizes on a screen.
- **Spacing**: one rhythm from `Theme.Space` (8 / 16 / 24); same screen margins on every screen.
- **Shared components** (new file `Components.swift` or similar): `ScreenHeader`, `SectionHeader`, `ListRow` (state icon, title, meta line, trailing stars), `FilterChip`, `InfoBanner` (one-line, with optional action), `StarsView` (three stars, filled / outline, one size set), `ProgressLine`.
- Apply to: Library (sidebar and detail), Intro, Settings (including the Form sections, kit picker, controller profiles), MIDI learn sheet, Practice header and end-of-run strip (typography and spacing only, no layout changes beyond ticket 24), Calibration view. Settings and MIDI learn currently use stock `Form` styling with Menlo only; give them the same section headers, row heights, tint and background.
- Dark and light variants stay as they are.

## 2. Library layout

- **Dense rows**: one row = state icon, number, title (rowTitle), a single meta line "genre · level dots · N bars · bpm -> target", stars on the right. Target row height about 56-64 pt so at least 9-10 rows are visible on an iPad in landscape (today about 4). The tempo/bars/genre must not wrap onto three lines.
- Detail header compact: group title, "passed / total" with progress line, "Play next" in one row. Filters collapse into **one row** (search field, cross filter menu, star chips scrolling horizontally, count and "Clear filters" at the right end). No vertical stack of four controls.
- Sidebar: tighter rows, one-line group title with "passed/total" at the right and the thin progress line below; Levels keep disclosure but with a consistent chevron and the same row height.
- **Locked stage**: the list of its lessons stays fully visible (dimmed text, lock icons, still readable). The lock explanation is **one slim `InfoBanner` line** at the top ("Earn 2 stars in 5 lessons of <stage> to open this · 2/5"), not a block that pushes the list down. Tapping a locked lesson scrolls to / pulses the banner, it opens nothing.
- Landscape and portrait; sidebar width unchanged.

## 3. Intro rows

Intro uses `IntroExerciseRow` with its own look and only two stars. Replace it with the shared `ListRow` + `StarsView`: **three stars**, same tap-for-requirements popover as `LibraryLessonRow` (ticket 23), same fonts. Keep the Intro-specific goal text as the meta line. Check that the memory star can actually be earned in Intro lessons (practice screen is shared; `StarStreak` has an Intro minimum) and that a memory star earned there shows. Library header text "24 exercises" becomes the real count.

## 4. First steps is abolished

- Remove the "First steps" category from every UI surface (sidebar, titles, filters, strings).
- The one remaining lesson (id 6 "Open hat on the and") is shown in **Intro**, as the last exercise of its natural place (after the hat lessons; decide by BPM/difficulty and note the choice in the report). Do this in the catalog projection (`LibraryCatalog`), not by renumbering or editing `lessons-core.json`; saved progress for id 6 is untouched. It must not appear twice (not in the Path stage 1 list either) and counts must stay consistent (Intro count, Path count, 539 core total).
- Remove `starter` as an unlock category; the always-open Intro replaces it. Keep the migration of saved unlocks working (no progress lost).
- Update `SPEC.md`, `DECISIONS.md` (one line each) and the localisation catalogs.

## 5. Unlock flow

- **Remove the pop-up alert** (`softUnlockAlert` in `Progression.swift` and its use in `LibraryScreen`). The only place to unlock is the banner on the stage page.
- Unlock is two steps **inline**: tap "Unlock" -> the banner changes to "Really unlock <stage>?  [Yes, unlock] [Cancel]" (no new window). Only the Yes button unlocks.
- **Lock again**: a stage that is open **only because of a manual unlock** and in which **no lesson has any star** shows "Lock again" in its banner (also with the inline "Really?" step). Stages that are open for any other reason (threshold reached, a played lesson, migration snapshot, Intro) never show it. Locking removes only the manual unlock record. Update the "never re-lock" rule in ticket 21 and `DECISIONS.md` §15 accordingly (one line): manual unlocks may be undone while the stage has no stars.
- Texts via the localisation catalogs (`en`, `cs`).

## 6. Do not

Change progression thresholds, star rules or scoring; touch the practice screen beyond type/spacing tokens; change data files except as stated; add status colours.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md` §10, `docs/tickets/2026-11-01-19-*.md`, `-21-*.md`, `-23-*.md`, `docs/DECISIONS.md` §15, `SmackAPad/Sources/UI/Theme.swift`, `LibraryScreen.swift`, `IntroScreen.swift`, `SettingsView.swift`, `ContentView.swift` (MIDILearnView), `CalibrationView.swift`, `StarRequirement.swift`, `SmackAPad/Sources/Progression/Progression.swift`, `LibraryCatalog.swift`, `SmackAPad/Sources/Persistence/Persistence.swift`, tests `LibraryCatalogTests.swift`, `StageCompletionTests.swift`, `IntroProgressMigrationTests.swift`.

## Tests

Lesson 6 appears once, in Intro only, and counts add up; no `starter` group exists; re-lock allowed only for a manually unlocked stage without stars (and not for naturally open ones); unlock requires the confirm step (pure state model); existing library/stage tests updated, not weakened.

## Acceptance criteria

- [ ] At least 9 library rows visible in landscape on an iPad (11-inch) without scrolling; no wrapped meta line.
- [ ] Locked stage: lessons readable, one-line banner, no pop-up anywhere.
- [ ] Unlock needs "Really?"; "Lock again" appears only where allowed.
- [ ] Intro rows look like all other rows and show three stars with the requirements popover.
- [ ] No "First steps" anywhere; lesson 6 in Intro with its progress intact.
- [ ] Library, Intro, Settings, MIDI learn, Calibration share fonts, spacing and components; only the five type roles are used.
- [ ] Build succeeds, new/updated tests pass.
- [ ] **iPad test (Jakub)**: landscape and portrait, light and dark, English and Czech, a locked stage, unlock + lock again.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app).
- **Reasoning effort**: **high** (xhigh for part A below; never `max`).
- **Reasoning**: Cross-screen refactor plus progression changes and a design judgement call. Claude Opus 4.6 on Antigravity is no longer available.
- **Run it in two conversations**: **A** = section 1 (shared design system) and sections 2-3 (library layout, Intro rows); **B** = sections 4-5 (First steps abolished, unlock flow). Commit after each part. Part B starts only after A is committed.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task (a separate commit for section 1 is welcome). Final report max 5 lines.


## Part A implementation (2026-11-01)

- Added five named typography roles in `Theme.swift` (28/22/18/13/16 pt) and shared `ScreenHeader`, `SectionHeader`, `ListRow`, `FilterChip`, `InfoBanner`, `StarsView`, `ProgressLine`, and form styling in `Components.swift`. Applied the roles to Library, Intro, Settings, MIDI learn, Calibration, and practice chrome. Practice changes are typography only; the shared button style now uses the control role.
- Library lesson rows have a 60 pt minimum height with a single metadata line; the compact header contains progress and Play next. Search, cross-filter menu, horizontally scrolling star chips, count, and Clear filters share one row. The clear action uses its icon when space is limited. Sidebar level disclosures and stage rows use the same 48 pt minimum and inline passed/total counts; sidebar width is unchanged.
- Locked-stage requirements occupy a fixed 48 pt banner above the scrolling list. Long requirements scroll horizontally. Selecting a locked group reveals its lessons; tapping a locked lesson reveals/pulses the pinned banner without opening a lesson or requesting an alert. The banner's manual Unlock action still uses the existing confirmation alert until part B replaces that flow.
- Intro uses the same lesson row and three-star requirements popover, with its goal as metadata. The sidebar exercise count is computed from the catalogue. Source inspection verified that `PracticeSession` computes and persists memory stars for Intro and that `StarStreak` applies the Intro minimum; scoring and persistence were not changed.
- Settings, controller profiles, MIDI learn, and Calibration use shared section headers, form margins, row heights, tint, and adaptive surfaces. Calibration strings now follow the selected app language using existing translation keys. No lesson data or progression rules changed.
- Validation: Debug build for generic iOS Simulator succeeded with code signing disabled (`xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath build/Ticket25A CODE_SIGNING_ALLOWED=NO build`). The first sandboxed attempt could not launch Xcode macro plugins; the same build succeeded with the required access. No new model tests were needed for part A, and previously passing tests were not rerun, following AGENTS.md. No browser/skill scripts or iPad checks were run.
- Pending Jakub: actual row visibility on 11-inch iPad, portrait/landscape, both appearances/languages, star popovers, and locked-banner feedback. Part B still owns lesson 6 placement, First steps removal, inline unlock confirmation/re-lock state and its tests, and the progression documentation updates. No BPM/difficulty placement decision was made in part A.
