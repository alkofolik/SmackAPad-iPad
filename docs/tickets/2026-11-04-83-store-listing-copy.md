# 83 — App Store listing texts and review notes (EN + CS)

Status: parked (App Store release track, not scheduled). Source: Claude's pre-release audit, 2026-11-04.

## Why

App Store Connect needs texts per language with hard limits; App Review needs notes on how to test without hardware.

## Rule

Create `docs/store/listing.md` with, for **English (primary)** and **Czech**:

| Field | Limit |
|---|---|
| Name | 30 chars ("Smack-a-Pad" + optional suffix, check the name is free in App Store Connect first) |
| Subtitle | 30 chars |
| Promotional text | 170 chars (can change without review) |
| Description | 4000 chars; first 3 lines matter most |
| Keywords | 100 chars, comma-separated, no spaces after commas, no words already in name/subtitle |
| What's New (1.0) | short |
| IAP "Full unlock": display name | 30 chars |
| IAP "Full unlock": description | 45 chars |

Plus (English only):
- **App Review notes**: the app is free to download; Intro and Path stage 1 are free, everything else is unlocked by the non-consumable `cz.kju.SmackAPad.full`; Restore Purchases is in Settings and in the purchase sheet; **no MIDI controller is needed for review** — use on-screen touch pads in portrait or a hardware keyboard; no login.
- Suggested **category** (primary Music, secondary Education) and **age rating** answers (no objectionable content).
- **App Privacy** answer: "Data Not Collected" (must match ticket 81).

Content rules: describe only features that exist in the build; no competitor names (Melodics etc.), no prices in text; no "best/#1" claims; counts like "600 lessons" only if they match lesson data at release.

## Files to read

`AGENTS.md`, this ticket, `docs/SPEC.md`, `docs/DECISIONS.md`, `SmackAPad/Resources/Data/*.json` (count lessons by `access`), localisation catalogs (use the app's own Czech terms).

## Acceptance criteria

- [ ] All fields within limits (character counts listed next to each field).
- [ ] Czech uses the same terms as the app UI.

## Agent assignment

- **Agent**: Claude (Opus) in the Smack-a-iPad chat, **thinking medium** — copywriting in Czech. Fallback: Gemini 3.8 Pro, medium.

## Done rule

Do not commit. Jakub edits, Claude commits afterwards.
