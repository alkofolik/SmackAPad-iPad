# 106 — Training log and Training badges

Status: ready-for-agent. Depends on: 98, 100, 101. Source: Jakub, 2026-11-05 ("badges are enough for now"), `docs/2026-11-05-training-push-proposal.md` §3.4 and §4.

## Goal

Reviews, Mix and Play after me get a visible reward: a new badge group **Training** / **Trénink** with 14 badges. Counters only grow; there is no streak that can break and no badge is ever lost.

## Training log (stored in the progress file)

1. New optional data in the progress file (old files decode as empty; `decodeIfPresent`):
   - `reviewsPassed: Int` — passed review runs (ticket 98 pass).
   - `bounceBacks: Int` — reviews passed on the day right after a failed review of the same lesson. Needs `lastReviewFailDay: String?` per lesson in `LessonProgress`.
   - `mixRounds: Int` — finished Mix rounds (every lesson of the set played one full run).
   - `mixMemoryRounds: Int` — finished Mix rounds where every run was a hidden From memory pass (ticket 99) with score ≥ 80 %.
   - `afterMeLessons: Set<Int>` — lessons with a Play after me response ≥ 80 %.
   - `trainingDays: Set<String>` — local days with at least one review run that counted (pass or fail), one finished Mix round or one Play after me response.
2. Merging (import, migration): counts take the larger value, sets are united, `lastReviewFailDay` keeps the later day.
3. Old progress: `reviewsPassed` starts at least at the passes implied by the schedule (`reviewStep`, settled = 4). Everything else starts at zero.
4. Play after me stays "practice only" for stars, credit and reviews (ticket 101); it only writes the log.

## Badges (append to `badges.json`, group `training`)

| Id | Name EN / CS | Condition EN / CS | Metric, goal |
|---|---|---|---|
| `review-first` | Comeback / Návrat | Pass your first review. / Projdi první opakování. | reviewsPassed 1 |
| `review-ten` | Regular / Pravidelně | Pass 10 reviews. / Projdi 10 opakování. | reviewsPassed 10 |
| `review-fifty` | Long memory / Dlouhá paměť | Pass 50 reviews. / Projdi 50 opakování. | reviewsPassed 50 |
| `settled-first` | Settled / Upevněno | Settle your first lesson. / Upevni první lekci. | settled 1 |
| `settled-ten` | Solid ground / Pevná půda | Settle 10 lessons. / Upevni 10 lekcí. | settled 10 |
| `settled-fifty` | In the hands / V rukou | Settle 50 lessons. / Upevni 50 lekcí. | settled 50 |
| `bounce-back` | Bounce back / Zpátky na nohy | Pass a review the day after a failed one. / Projdi opakování den po nesplněném. | bounceBacks 1 |
| `mix-first` | Shuffle / Zamíchej | Finish a full Mix round. / Dokonči celé kolo Mixu. | mixRounds 1 |
| `mix-memory` | Blind mix / Mix naslepo | Finish a Mix round from memory, every run at least 80 %. / Dokonči kolo Mixu zpaměti, každý běh aspoň 80 %. | mixMemoryRounds 1 |
| `mix-twenty` | Juggler / Žonglér | Finish 20 Mix rounds. / Dokonči 20 kol Mixu. | mixRounds 20 |
| `after-me-first` | Echo / Ozvěna | Score at least 80 % in Play after me. / Získej aspoň 80 % v Zahraj po mně. | afterMeLessons 1 |
| `after-me-ten` | Good ear / Dobré ucho | Score at least 80 % in Play after me on 10 lessons. / Získej aspoň 80 % v Zahraj po mně u 10 lekcí. | afterMeLessons 10 |
| `training-days-10` | Ten sessions / Deset tréninků | Train on 10 different days. / Trénuj v 10 různých dnech. | trainingDays 10 |
| `training-days-50` | Fifty sessions / Padesát tréninků | Train on 50 different days. / Trénuj v 50 různých dnech. | trainingDays 50 |

- `settled` = number of lessons with `settled == true`.
- New `BadgeGroup.training` ("Training" / "Trénink") shown in the Badges screen after the existing groups, same row style.
- Evaluate badges after review runs, after a finished Mix round and after a Play after me response (ticket 101 skips badge evaluation today; add evaluation of the Training group only there). New badges use the existing banner (ticket 78). Badges reached by the old-progress derivation are awarded silently at launch (`awardSilently`).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Persistence/Persistence.swift` (progress root, `LessonProgress`, `merging`, review recording), `SmackAPad/Sources/Progression/BadgeModel.swift`, `SmackAPad/Sources/Progression/BadgeEvaluator.swift`, `SmackAPad/Sources/Persistence/BadgeStore.swift`, `SmackAPad/Resources/Data/badges.json`, `SmackAPad/Sources/UI/PracticeSession.swift` (review result, Mix round end, After me response, `evaluateBadges`), `SmackAPad/Sources/UI/BadgesScreen.swift`, `SmackAPad/Sources/App/SmackAPadApp.swift` (`awardSilently`), both `Localizable.strings`.

## Tasks

1. Log fields, decoding, merging, old-progress derivation.
2. Write the log at the four events; evaluate the Training group.
3. Badge definitions, group, names and conditions in `en` and `cs`.
4. Unit tests (only these): pass/fail/pass on consecutive days gives one bounce-back; a Mix round with one shown pass is not a memory round; merge takes max and union; old file with `reviewStep 2` gives reviewsPassed 2.

## Acceptance criteria

- [ ] Badges screen shows the Training group with 14 badges and progress.
- [ ] Passing a first review shows the "Comeback" banner.
- [ ] Mix and Play after me earn their badges; stars and reviews unchanged by Play after me.
- [ ] Old progress files load; derived badges appear without a banner.
- [ ] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: pass one review, finish one Mix round, score 80 % in Play after me; three banners.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: progress-file change and several event hooks; badge logic itself is simple.

## Done rule

Stop after successful build and tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
