# 02 — Data Port from Legacy

Status: done

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
   - sample kit manifest: use `app/v21/data/2026-10-04-sample-kits.json` (full manifest: 8 kits acoustic, 808, jazz, world, rock, brush, worldperc, house; 371 unique WAV references). Save it as `sample-kits.json`. Do NOT use `app/v21/src/data/sample-kits.json`, it has only the first 4 kits.
2. Copy localisation file from `app/v21/i18n/`:
   - `cs.tsv`
3. Copy all sample WAV files from `ios-wrapper/ios/App/App/public/samples/` (7 kit directories: 808, acoustic, brush, house, rock, virtuosity, worldperc — 371 WAV files, ~95 MB total).
4. Copy every LICENSE file from `app/v21/assets/samples/` (LICENSE.txt, LICENSE-source-*.txt, CREDITS.md per kit).
5. Place everything into `Resources/Data/` (JSON), `Resources/Samples/` (WAVs + licenses), `Resources/i18n/` (cs.tsv).
6. Write a simple Swift loader that validates all JSON files parse without error.

## 8-pad note

No playability report is needed. Verified 2026-10-30: in 8-pad mode all 595 lessons are playable through per-lesson pad assignment (SPEC §6). Lessons keep their optional `hits8` field unchanged (6 lessons).

## WAV files total size

371 WAV files across 7 kit directories, **~95 MB** total.

## Acceptance criteria

- [x] All 547 core + 24 intro lessons load from bundled JSON.
- [x] Electronic-path and genre-extension lessons load and appear in correct categories.
- [x] Invalid or missing JSON produces a clear error, not a crash.
- [x] All 371 WAV files are present in the bundle, and every WAV referenced by the 8-kit manifest exists (jazz, world and worldperc reference WAVs from other folders).
- [x] The 6 lessons with `hits8` still have it after the copy.
- [x] All LICENSE files copied alongside each kit's samples.
- [x] `cs.tsv` copied to resources.
- [x] Architecture supports loading from multiple sources (bundled + external JSON) for future content packs.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: File copying + simple validation. Explicitly allowed to read the legacy folder.

## Done rule

Stop after successful build; Jakub tests on iPad.
