# 254 — Czech adaptation of the story texts

Status: open · after 253 is approved and in the app

## Goal

Add Czech versions of every `story.*` string. Adaptation, not literal translation: keep the deadpan humour, rewrite where a pun does not work in Czech. Same length limits as English; if a Czech line is too long, rewrite it shorter, never make the font smaller (GDD §4.3). Boss and region names: use the GDD's provisional Czech names as a start (Baron Pozdorytmus, Kotevní marky, Šeptající krypty, Veliký Přečet, Ladicí klíč…) and propose better ones where you have them. Drum names stay English (app-wide rule).

## How to run this

- Antigravity: **Gemini 4 Argon, thinking medium** — writes the Czech strings into `cs.lproj` next to the English ones and lists every name it changed versus the GDD.
- Then Claude reviews the tone and length of all Czech lines and sends back a list of fixes; Jakub has the last word on names.

## Acceptance criteria

- [ ] Every `story.*` key has a Czech string; none longer than the limits; `LocalizationTests` pass.
- [ ] Names list reviewed by Jakub.

### Manual iPad check for Jakub

- Switch the app to Czech, open the map: story card, one fork choice and one boss screen read naturally and fit without wrapping oddly.
