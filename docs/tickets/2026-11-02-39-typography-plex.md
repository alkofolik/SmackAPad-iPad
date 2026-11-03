# 39 — Typography: IBM Plex Sans across the app

Status: ready-for-human — implemented; iOS build passed; iPad validation pending. Source: Jakub chose variant B on 2026-11-02 (docs/design/2026-11-02-typography-proposals.md).

## Problem

The app mixes Avenir Next Heavy (`Theme.display`) and Menlo (`Theme.text`), which looks wild, terminal-like and amateur. The START/STOP labels and small texts were also too thin and small.

## Goal

One family everywhere: **IBM Plex Sans, Regular 400 + Bold 700, normal width (100)**, with the type scale from the proposal document ("Shared type scale for the whole application").

## Rules

- Bundle `IBMPlexSans[wdth,wght].ttf` (v3.201) from `docs/design/2026-11-02-typography/fonts/`, register it in Info.plist (`UIAppFonts`) and add the target membership. Add the OFL licence text (`ibmplexsans-OFL.txt`) to the app (e.g. Settings → About / Licences) and keep the copyright.
- Replace both `Theme.display`/`Theme.text` and the canvas variants `canvasDisplay`/`canvasText` so every screen uses Plex: practice (count-in numbers, tempo, feedback, pad abbreviations HH/SN/KD in the pattern), result card, library rows, settings, dialogs, onboarding.
- Use the proposed scale: tempo/main result 56 pt Bold; screen title and pad abbreviation 32 Bold; lesson title 28 Bold; section heading 26 Bold; main control 24; navigation/explanation 22; supplementary 20 Regular. No 13 pt metadata, no uppercase tracked overlines.
- Tabular digits for BPM and percentages (do not change weight while tempo updates).
- Real Regular/Bold weights only — no synthetic bold, no condensed width, no automatic shrinking. Ordinary text follows the system text size; canvas notation gets more room instead of clipping Czech accents or shrinking pad labels.
- START / STOP / RESTART labels: Bold, at least 24 pt, single line in Czech and English.
- Keep colours (orange, black, white) and layout unchanged; if a bigger size breaks a layout, make room, do not shrink the text. Ticket 38 (overflow) should be done first.
- Check the Czech diacritics `ě š č ř ž ý á í é ú ů ď ť ň` on every screen.

## Files to read

`AGENTS.md`, `docs/design/2026-11-02-typography-proposals.md` (esp. section B and the shared type scale), `docs/design/2026-11-02-typography/fonts/`, `SmackAPad/Sources/UI/Theme.swift`, every file using `Theme.display`, `Theme.text`, `Theme.meta`, `Theme.control`, `.canvasDisplay`, `.canvasText`, `Info.plist`/project settings.

## Acceptance criteria

- [x] `grep` finds no `AvenirNext` or `Menlo` in Sources.
- [ ] The font is really loaded (a debug check of `UIFont.familyNames` lists "IBM Plex Sans"), no silent fallback to system font.
- [x] Licence text is included and reachable in the app.
- [ ] All screens in both languages and both appearances: no clipped or wrapped labels, START/STOP/RESTART on one line.
- [ ] Build and tests pass.
- [ ] **iPad test (Jakub)**: practice (count-in, running, result), library, settings; Czech and English; light and dark; larger system text size.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app), **high** reasoning (touches every screen and layout; font loading and clipping need care).

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.


## Implementation — 2026-11-02

- Bundled the original IBM Plex Sans v3.201 variable font and complete OFL copyright/licence. The synchronized app target includes both resources. `SmackAPad-Info.plist` registers the font in Debug and Release; Settings → IBM Plex Sans opens the licence.
- Replaced the theme and canvas faces with real `IBMPlexSans-Regular` and `IBMPlexSans-Bold` at normal width. Added the shared 56/32/28/26/24/22/20-point scale, tabular changing numbers, sentence-case section labels and scalable body text. Font lookup has a precondition against silent fallback and a debug `UIFont.familyNames` assertion/log.
- Removed automatic text shrinking. Transport labels are single-line 24-point Bold; rows, headers, result actions and controls gain room or use a stacked layout. Native segmented controls explicitly use Plex and scale their intrinsic height. Confirmation panels use SwiftUI text so they also retain Plex and Dynamic Type.
- Pattern labels remain 32-point Bold with measured cell widths and a scalable per-lane height floor. Static notation pages through the number of bars that fit, and narrow bars scroll to the active beat. Scrolling notation uses the same label metrics. This adapts notation space rather than shrinking labels.
- Preserved the pre-existing uncommitted practice/band/overflow work and localization changes. No legacy code was read or copied.

## Validation

- Source audit: no AvenirNext/Menlo, synthetic weight overrides, tracking or automatic shrinking in the typography scope. Font and licence copies match the originals byte for byte.
- Local CoreText registration resolved both actual Plex faces; the Bold variation resolved to weight 700. The UIKit startup check still needs to run on the iPad; it has not been reported as passed here.
- Build: Debug generic iOS build passed with code signing disabled. The initial sandboxed attempt could not launch Swift macro plugins; the single retry outside that restriction succeeded. Font and OFL copy steps were present. Log: `.build/typography-39-build.log`. Existing calibration/trailing-closure warnings and the App Intents metadata notice remain; no further edits/checks followed the successful build.
- Tests: not added or rerun, following `AGENTS.md`.
- Not verified: all screen layouts and Czech accents on iPad, both languages/appearances, portrait/landscape and larger system text. Include segmented selections, confirmation panels, dense/multi-bar notation and transport labels in the device check.

- Stopped after the successful build. Changes remain uncommitted under this ticket's specific done rule, pending Jakub's iPad check.
