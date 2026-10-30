# 02 — Data Port from Legacy

Status: ready-for-agent

## Goal

Copy all data files (lesson JSON, sample kit WAVs, localisation, licenses) from the legacy Capacitor prototype into the new project's `Resources/` folder. Validate that files load correctly.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.3 Lesson Data, §4.1–4.2 Data Formats, §13 Sample kits)
- `docs/DECISIONS.md` (§5 Lesson data schema, §13 Sample kits, §19 Localisation)

## Legacy source (read-only)

`/Users/kju/AI COWORK/Smack-a-Pad/Smack-a-Pad/2026-10-28-Smack-a-Pad-ipad`

This ticket is explicitly allowed to read the legacy folder.

## Tasks

1. Copy JSON data files from `app/v21/src/data/`:
   - `lessons-core.json` (547 lessons)
   - `intro.json` (24 lessons)
   - `electronic-path.json` (12 lessons)
   - `genre-extensions.json` (12 lessons)
   - `sample-kits.json` (kit definitions)
2. Copy localisation file from `app/v21/i18n/`:
   - `cs.tsv`
3. Copy all sample WAV files from `ios-wrapper/ios/App/App/public/samples/` (7 kit directories: 808, acoustic, brush, house, rock, virtuosity, worldperc — 371 WAV files, ~95 MB total).
4. Copy every LICENSE file from `app/v21/assets/samples/` (LICENSE.txt, LICENSE-source-*.txt, CREDITS.md per kit).
5. Place everything into `Resources/Data/` (JSON), `Resources/Samples/` (WAVs + licenses), `Resources/i18n/` (cs.tsv).
6. Write a simple Swift loader that validates all JSON files parse without error.

## 8-pad playability report

Analysis of all 595 lessons by padIndex usage (padIndex 0–7 only = playable on 8-pad controller mapped to pads 0–7):

| Category | Total | Only padIndex 0–7 | Needs padIndex >7 |
|---|---|---|---|
| starter | 9 | 0 | 9 |
| eighth | 27 | 0 | 27 |
| sixteenth | 122 | 1 | 121 |
| electronic | 45 | 0 | 45 |
| ghost | 62 | 0 | 62 |
| swing | 62 | 0 | 62 |
| world | 115 | 0 | 115 |
| fills | 105 | 0 | 105 |
| intro | 24 | 0 | 24 |
| electronic-path | 12 | 0 | 12 |
| genre-extensions | 12 | 0 | 12 |
| **Total** | **595** | **1** | **594** |

**Key insight**: Core drum sounds (kick=12, snare=13, hat=11) are all at padIndex >7. An 8-pad controller typically maps its pads to these critical indices. The "playable" filter (SPEC §6) checks against the active controller profile's noteMap, not against a fixed 0–7 range.

## WAV files total size

371 WAV files across 7 kit directories, **~95 MB** total.

## Acceptance criteria

- [ ] All 547 core + 24 intro lessons load from bundled JSON.
- [ ] Electronic-path and genre-extension lessons load and appear in correct categories.
- [ ] Invalid or missing JSON produces a clear error, not a crash.
- [ ] All 371 WAV files are present in the bundle.
- [ ] All LICENSE files copied alongside each kit's samples.
- [ ] `cs.tsv` copied to resources.
- [ ] Architecture supports loading from multiple sources (bundled + external JSON) for future content packs.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: File copying + simple validation. Explicitly allowed to read the legacy folder.

## Done rule

Stop after successful build; Jakub tests on iPad.
