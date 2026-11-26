# 254 — Czech adaptation of the story texts

Status: open · after 253 is approved and in the app

## Goal

Add Czech versions of every `story.*` string. Adaptation, not literal translation: keep the deadpan humour, rewrite where a pun does not work in Czech. Same length limits as English; if a Czech line is too long, rewrite it shorter, never make the font smaller (GDD §4.3). Boss and region names: use the GDD's provisional Czech names as a start (Baron Pozdorytmus, Kotevní marky, Šeptající krypty, Veliký Přečet, Ladicí klíč…) and propose better ones where you have them. Drum names stay English (app-wide rule).

## How to run this (two steps; Argon is only in the Gemini desktop app, not in Antigravity)

1. **Gemini desktop app, Gemini 4 Argon, thinking medium** (a pure writing task, no code). Attach `docs/design/2026-11-26-story-mode-gdd-v1.md` and the English strings file from ticket 253, and ask for the same machine-readable block (`"story.…" = "…";`) in Czech, plus a list of every name that differs from the GDD's provisional Czech names. Save the answer as `docs/design/story-strings-cs.txt`.
2. **Antigravity, Gemini 3.8 Flash, thinking low** (mechanical): copy the strings into `cs.lproj` next to the English ones, run `LocalizationTests`, check no line exceeds the length limits.
3. Claude reviews the tone and lengths of all Czech lines and sends back fixes; Jakub has the last word on names.

## Acceptance criteria

- [ ] Every `story.*` key has a Czech string; none longer than the limits; `LocalizationTests` pass.
- [ ] Names list reviewed by Jakub.

### Manual iPad check for Jakub

- Switch the app to Czech, open the map: story card, one fork choice and one boss screen read naturally and fit without wrapping oddly.
