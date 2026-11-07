# 135 — Proposal: Home pad titles in a font that matches the logo (HTML preview, no code)

Status: ready-for-agent. Type: proposal. Source: Jakub, 2026-11-07: "Could the pad titles use the font from the logo?"

## Fact

The wordmark "SMACK-A-PAD" is a **vector drawing** (`HomeScreen.swift` ~573), not a font. There is no font file to reuse. We need a free font (SIL OFL) that looks like it: heavy, condensed, tall grotesque.

## Task

1. Pick 3 OFL candidates that match the wordmark (e.g. Anton, Bebas Neue, Barlow Condensed ExtraBold, Oswald Bold — check Czech diacritics: Ě Š Č Ř Ž Ý Á Í É Ů Ú).
2. One offline HTML file `docs/previews/135-pad-title-fonts.html`: the Home 3×3 pad grid (current look, ticket 119) three times, one per font, titles only (DNES, KNIHOVNA, TRÉNINK, INTRO, OVLADAČ, ODZNAKY, PLNÁ VERZE, NASTAVENÍ). Subtitles stay IBM Plex Sans. Light and dark. Fonts embedded (base64) so it works offline.
3. Note under each: licence, diacritics OK, longest title fits without "…".
4. No Swift changes. Jakub picks; then an implementation ticket.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop when the HTML file opens offline. Commit (AGENTS.md).
