# Ticket 173 — Localization inventory

## Scope and starting state

- English: 818 unique keys; Czech: 819 unique keys. Neither source file had duplicate keys or empty values.
- English-only: `1 lesson due for review`, `%lld lessons due for review`, `Review in %lld days · practice only`.
- Czech-only: `1 lekce čeká na opakování`, `%lld lekce čekají na opakování`, `%lld lekcí čeká na opakování`, `Learn a new profile (MIDI learn)`.
- The retired TSV had 2,653 lines and 2,648 effective keys. The former loader used the last assignment for repeated keys. Of these keys, 2,399 were absent from the Czech catalogue. Every effective missing entry was moved unchanged, including older content keys; the 249 existing Czech catalogue values were preserved.
- Checked all 737 `localized(...)` call occurrences in native Swift sources, including literal keys in conditional expressions and multiline calls. No `String.LocalizationValue` construction or typed call site exists. The two unused `String.LocalizationValue` overloads were removed with their separate Foundation lookup; string and format overloads now share the single string-key lookup.
- Direct UI calls additionally lacked `OK` (Settings and app alert), `Delete profile "%@"?` (controller deletion), and `%lld of %lld` (practice progress). The Czech translation of the deletion prompt reuses the existing catalogue wording; the other meanings are unambiguous.
- Dynamic calls forward lesson titles, genres, goals, watch notes, badge text, enum titles and other computed keys. Their existing TSV translations are preserved by the complete migration. User-generated names and runtime text still fall back to the supplied key as before; they are not a finite list of literal source keys.
- Reminder bodies previously bypassed localization. They now use `localized(_:)` for the same wording and the same Czech 1 / 2–4 / other plural branches.

## Explicit Czech plural exceptions

These keys are used only by the Czech reminder branch and deliberately have no English entries:

| Key | Where missing | Action |
| --- | --- | --- |
| `1 lekce čeká na opakování` | EN, intentional | Retained; checked explicitly by the catalogue test. |
| `%lld lekce čekají na opakování` | EN, intentional | Retained for 2–4 lessons; checked explicitly by the catalogue test. |
| `%lld lekcí čeká na opakování` | EN, intentional | Retained for the other Czech counts; checked explicitly by the catalogue test. |

The test requires this exact difference, so deleting even an exception from Czech fails. The regular English reminder keys now also have Czech counterparts.

## Added entries

Every row below identifies the original gap. Correct existing values were not rewritten. Imported English text remains the former key fallback, including brace placeholders in older content strings.

| Key | Where missing | Action |
| --- | --- | --- |
| `%lld lessons due for review` | CS | Added the missing catalogue entry; existing translations retained. |
| `%lld of %lld` | EN, CS | Added the missing catalogue entry; existing translations retained. |
| `+0.01 BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `+0.1 BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `+1 beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `+: added hit compared with bar 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `+{n} BPM after a clean run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `+{n} BPM after a successful run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `, Michael Fischer / Technopolis, TR-808 Sound Sample Set 1.0.0 (1994).` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `, Michael Fischer / Technopolis, TR-808 Sound Sample Set 1.0.0 (1994). CC0. Wood uses claves; Ride uses a short 808 cymbal setting. House and techno currently use 808; a dedicated 909 kit is not included.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `, Versilian Studios and Karoryfer Samples, performed by Austin McMahon.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `, Versilian Studios and Karoryfer Samples, performed by Austin McMahon. CC0 for Virtuosity recordings; the clap uses the existing AVL sample under CC BY-SA 3.0. Includes stereo cymbals with four recorded variants for closed hat, ride and crash, three for open hat. A selected palette rather than the full library and microphone mixer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `, recorded by Glen MacArthur.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `, recorded by Glen MacArthur. CC BY-SA 3.0. The audio is unchanged; 65 files were selected and renamed. Wood uses a stick click, Shaker uses maracas and Open hat uses the recorded hat swish.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `, then test your transport buttons and tempo knob.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `-pad mode.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `. Brush recordings from Karoryfer Swirly Drums with VCSL percussion. The supplied audio files are unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `. New VCSL percussion and Swirly bongos use CC0 1.0. This kit also reuses unchanged Acoustic recordings under CC BY-SA 3.0; their original credits and license still apply.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `. Rock recordings from Karoryfer Big Rusty Drums with VCSL percussion. The supplied audio files are unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `0 bars left` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `0 ms · on time` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `1 lesson due for review` | CS | Added the missing catalogue entry; existing translations retained. |
| `1 of 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `1 star` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `1/16 triplets` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `1/8 triplets` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100 %:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100 percent goal progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} clean full run at {bpm} BPM or faster` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} clean full run at {bpm} BPM or faster · {mode}-pad mode` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} clean full runs at {bpm} BPM or faster` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} clean full runs at {bpm} BPM or faster · {mode}-pad mode` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} consecutive clean full run at {bpm} BPM or faster` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} consecutive clean full run at {bpm} BPM or faster · {mode}-pad mode` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} consecutive clean full runs at {bpm} BPM or faster` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `100%: {n} consecutive clean full runs at {bpm} BPM or faster · {mode}-pad mode` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `120 selected lessons are playable.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `120 selected lessons are playable. The remaining 475 are a preview of the full course. All four sound kits are included.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `16 pads only` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `16ths` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `16ths {count}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `2 days` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `2 of 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `2 stars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `2 successful repeats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `24 short lessons · pulse, two hands, grooves and first fills` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `3 days` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `3 stars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `3 successful repeats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `5 days` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `808 rhythm tutorial · Computer Music` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `808 sample license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `99Sounds license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `: loop bar 2, raise tempo after two successful repeats, then Stop.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A (seconds)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A + beside L or R marks a hit absent from the same position on the same pad in bar 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A clean full run adds {bpm} BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A complete backbeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A first sixteenth pair` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A keyboard cannot reproduce MIDI velocity.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A kick and snare answer` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A knob with end stops sets BPM across the selected range.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A knob with end stops sets BPM across the selected range. With pickup enabled, turn it to the current tempo first; the pad display shows the target.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A large community library of sounds and packs. Downloads require a free account.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A mapped note becomes transport only.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A mistake keeps your progress.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A month in a row` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A new lesson, reviews and a mix.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A new step at your level.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A one-beat snare fill` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A pattern can contain at most 8 bars.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A selected palette rather than the full library and microphone mixer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A short tom answer` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A silent downbeat is intentional; do not fill it with an extra kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A sound file could not be verified. Downloaded sounds are kept. Try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A sound file is unavailable. Downloaded sounds are kept. Try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A steady right hand` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A successful full run adds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A successful full run adds {n} BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A two-bar phrase` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A weaker repeat resets the streak.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A week in a row` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `AVL and the selected Virtuosity drums use five recorded dynamic layers. Virtuosity cymbals and percussion use their original velocity splits and alternate actual recorded takes; the shaker has one velocity layer. The 808 responds to MIDI velocity through volume. Keyboard input uses a fixed velocity. Samples load before the lesson count-in begins. Jazz downloads about 64 MB on first use; decoded samples are reused during this session. Shared files are loaded once across palettes. A closed hi-hat cuts off an open hi-hat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `About this exercise` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Absolute · 0–127` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Accuracy of each hit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Acoustic` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Acoustic + World` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Acoustic + world percussion` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Acoustic sample license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Acoustic · AVL Black Pearl` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add a clap backbeat to a dance pulse.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add a kick between beats without moving the snare.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add a pickup at the end of the bar without shortening the bar.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add a sound before changing its volume.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add an offbeat hat without moving the tom or kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add claps on beats 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add claps on beats 2 and 4. Keep the right-hand kick steady and the left-hand tom pickups intact. Listen to the louder clap accents and the softer tom answers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add hats on every &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add hats on every &. At 2 &, press Hat R and Rim together with your right hand. Elsewhere the same hand plays the two pads separately. Keep the kick steady.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add open hats on every &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add sounds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Add to kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Added hit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 10` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 11` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 7` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 8` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban calypso 9` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Afro-Cuban rhumba 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `After a clean full run (≥90%).` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `After a clean full run (≥90%). Stop whenever you like.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `After passing a lesson, continue along the Path, from the basics to level 5.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `After saving your first sound, we ask the browser to protect storage. Otherwise it may remove sounds when space is low. Clearing site data also removes your kits.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `After your first run, every hit appears here` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `After {n} consecutive clean repeats, +{step} BPM up to {bpm} BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `After {n} successful repeats (not consecutive), +{step} BPM up to {bpm} BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Aim for 80% to pass; every guided lesson remains open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All courses` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All courses in this view` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All eight sound kits are included.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All genres` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All lesson goals are complete.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All lesson goals are complete. Continue to the next lesson or replay this one.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All lessons passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All levels` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All passed lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All sounds are saved for offline use.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All sounds are saved in this version.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All source lessons must be available to play this song.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All unlocked` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All {n} bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All {n} bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All {n} lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `All · easiest first` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Allow MIDI for this site in your browser permissions.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Allowed errors: {used} of {limit}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Alternate them on the four beats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Alternate two bars.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Alternate two bars. In bar 1, the middle kick is on 2 a; in bar 2 it moves earlier to 2 &. Hats, snares and the final rim stay the same. Learn the kick changes alone, then add the other layers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Alternate two kick shapes while the other parts stay steady.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Always read the license; sounds belong to their authors.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ambiguous name. Choose an instrument.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `An extra hat there counts as an extra hit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Anchor A (seconds)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Anchor A is the first beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Anchor B (seconds)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Answer the pulse with open hats and close them on the next beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Answer the snare on 4 with a kick on 4 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `App and data` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Appearance and language` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Applied for this session; browser storage is unavailable` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Assign MIDI to the existing start / stop action.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Assign a separate controller button to each action.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Assign a separate controller button to each action. Use MIDI Learn, or enter the note or CC number manually. A mapped note becomes transport only. CC buttons leave your sound pads free.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Assign again` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Assign at least one sound, or cancel.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Assign or clear this transport action.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Assigned knob` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At 2 &, rim and hat are one simultaneous event.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At 2 &, rim and hat are one simultaneous event. Prepare both pads so neither is late.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At least 85% of hits in the perfect/good timing window; up to 10% missed or extra hits (at least one allowed).` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At least 85% of hits in the perfect/good timing window; up to 10% missed or extra hits (at least one allowed). Successful repeats accumulate; a weaker repeat keeps your credit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At least 90 %, no missed hits and no wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At least 90 %. Allowed errors (missed hits + wrong pads): {errors}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At least 90%, no missed hits and no wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At least 90%. Allowed errors (missed hits + wrong pads): {n}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At the end of bar 4, the open hat and high tom land together on 4 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At the end of bar 4, the open hat and high tom land together on 4 &. Do not add a fifth beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At {bpm} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At {bpm} BPM or faster, collect {n} Practice runs with ≥90%, no missed hits and no wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `At {bpm} BPM or faster, collect {n} consecutive Practice runs with ≥90%, no missed hits and no wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio could not start.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio could not start. Press Start again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio name` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio player` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio saved on this device.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio storage is unavailable. Try a regular browser window.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio timing changed or is not ready. Try again; previous settings are unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio unavailable` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Audio waveform` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto +{n} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto keeps device timestamps.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto keeps device timestamps. Bluetooth timestamps over 250 ms old or over 50 ms in the future use receipt time; raw timestamps remain in reports.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto preserves device timestamps; unusually old Bluetooth timestamps use browser receipt time.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto sound` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto tempo off` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto tempo step` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto uses Jazz for jazz, New Orleans and blues; World percussion for Latin, Afro-Cuban, Afrobeat, Highlife and Middle Eastern; House/Techno for house and techno styles; 808 for the other electronic genres; Rock for rock and punk; Brush for soul, reggae, gospel, country, lo-fi, trip hop and pop; Acoustic for all other genres. You can choose any kit manually.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto uses Virtuosity for jazz, New Orleans and blues; the World palette for Latin, Afro-Cuban, Afrobeat, Highlife and Middle Eastern lessons; 808 for electronic styles, Jersey club and footwork; AVL acoustic for other genres.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto uses Virtuosity for jazz, New Orleans and blues; the World palette for Latin, Afro-Cuban, Afrobeat, Highlife and Middle Eastern lessons; 808 for electronic styles, Jersey club and footwork; AVL acoustic for other genres. You can choose any palette manually. World keeps acoustic drums and adds recorded shaker, woodblock and cowbell; it does not change a snare into a conga.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto · Bluetooth compatibility` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Auto · match lesson genre` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Automatic tempo increases in Practice` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Automatic tempo is off.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Avoid dragging the snare forward to meet the following kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Avoid squeezing in an extra hit at the end of the bar.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `A–B loop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `B (seconds)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `BROWSE & REVIEW` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Back to Home` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Back to My audio` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Back to Practice` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Back to lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Backbeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Backbeat with extra kick` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Backbeat, kick on the and of 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Backup and reset progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Backup progress is not an object.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Badge earned` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 1 is the full groove.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 1 is the full groove. Bar 2 ends with two snare hits. Return to kick and hat together on bar 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 1 is the previous groove.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 1 is the previous groove. In bar 2 add a quieter left-hand snare on 3 & before the snare on 3 a. Your right hand keeps hats on 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 1 uses the displaced-kick study.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 1 uses the displaced-kick study. Bar 2 adds two close final kicks on 4 e and 4 &, and an answering snare on 4. Your right hand keeps quarter-note hats throughout.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 2 adds two close final kicks on 4 e and 4 &, and an answering snare on 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 2 ends with one extra kick on 4 a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 2 ends with two snare hits.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 2 has kick and hat together on 2 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 2 has kick and hat together on 2 &. It is a deliberate change, not a timing mistake.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 2 shifts just one tom from a to & after beat 2.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 3 adds one quiet closed hat on 2 a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar 4 adds a high-tom answer on 4 & before the low tom on 4 a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar count` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar {bar} / {bars} · repeat {repeat} / {repeats}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar {bar} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar {bar}, count {count}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bar {n} of {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bars {from}–{to} of {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bars {from}–{to} repeat during Practice and Play along.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bars: {bars}. Hits: {count}. Tempo: {tempo} BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Base kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Base sound` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Base sound restored.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Beat 2 has three pads at once, with two played by the left hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Beat 2 has three pads at once, with two played by the left hand. Keep the wrist loose and avoid a flam.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Beat 3 joins three pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Beat 3 joins three pads. Count all four beats even when the snare gives the groove a slower feel.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Beats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Beats per bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Before your first lesson, connect your pad and calibrate` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Best score` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Best score {n}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Best score {score} %.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Black` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bluetooth compatibility active: unusually old/future event timestamps are replaced by browser receipt time.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bluetooth compatibility active: unusually old/future event timestamps are replaced by browser receipt time. This includes delivery jitter; it is not a latency measurement.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bluetooth headphones add 150–300 ms of delay that this app cannot measure reliably.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bluetooth headphones add 150–300 ms of delay that this app cannot measure reliably. For playing, use wired headphones or speakers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bluetooth timestamps over 250 ms old or over 50 ms in the future use receipt time; raw timestamps remain in reports.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bluetooth timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Boom bap song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Boom bap with ghost snare` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Boom bap with pushed kick` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bossa song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Both hands share the snare pad.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Both hands share the snare pad. Every hit, hand, velocity and timing is preserved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Both pads must land together, without rushing toward the final kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brazilian sambareggae 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brazilian sambareggae 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brazilian sambareggae 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brazilian sambareggae 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brazilian sambareggae 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Breakbeat, two bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Breakdown {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Bridge {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken UK techno beat · Future Music` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno 1 · missing kick` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno 1 · the missing kick` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno 2 · rim pickup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno 3 · two kick shapes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno 3 · two kicks` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno 4 · break and return` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno 4 · the return` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Broken techno · 4 guided lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browse 99Sounds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browse Freesound` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browse SampleRadar and license notes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browse all courses` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browse guided lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browse lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser / device` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser compatibility` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser compatibility · Advanced` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser installation support and current app state.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser receipt time` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser storage is full. No changes were saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser storage is unavailable. My kits cannot be saved here. Built-in kits still work. Try a regular browser window.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser storage protection could not be requested. The browser may remove sounds when space is low.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser storage protection was granted. Keep an exported kit as a backup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser storage protection was not granted. The browser may remove sounds when space is low. Keep an exported kit as a backup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser storage used` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Browser support` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brush` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brush recordings from Karoryfer Swirly Drums with VCSL percussion. The supplied audio files are unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Brush · Swirly + VCSL` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Build your foundation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Build {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Buttons and tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `CC button behavior` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `CC buttons leave your sound pads free.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `CC0 for Virtuosity recordings; the clap uses the existing AVL sample under CC BY-SA 3.0.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `CONTINUE` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `COURSE COMPLETE` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Calculate tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Calculate tempo from two beats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Calibrate` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Calibrate timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Calibration cancelled.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Calibration instructions and fine tuning` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Cancel count-in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Cancel import` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Cancel recording` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Cancel the measurement and keep the saved result.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Centred` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Challenge` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Change in Library` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Change just the final hat to an open hat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Change pads without changing the pulse.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Changes are saved immediately.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Changes saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Change…` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Changing tempo during playback restarts the lesson with a count-in after you finish turning the knob.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check MIDI timing and audio output, then retry.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check all bars in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check game` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check game complete` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check games` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check it and try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check sound assignments` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check that the rhythm still sticks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check the assignments and save.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check the assignments, then save. Nothing has been saved yet.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check the highlighted tom positions before starting.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check the open-hat pad before starting; it sits above the closed-hat pad.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check which browsers support your controller.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Check your connection and try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose 1, 2, 4 or 8 bars.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose Assign, then strike the pad for this position.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose English or Czech.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose English or Czech. Your progress and MIDI mappings stay unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose Everything to use Density Ladder.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose Merge or Replace.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose Merge or Replace. Import was cancelled.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose Save mapping to assign this control.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a WAV, MP3, OGG, M4A or AAC file.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a ZIP of 110 MB or smaller.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a ZIP or folder with at most 512 files.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a built-in base kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a file no larger than 64 MiB.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a genre yourself. Suggestions use the track tempo at 100 %; a slower speed is only suggested.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a kit or match it to the lesson genre.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a lesson in the Library` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a local file to load into the app.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a loop with B after A, inside the track.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a mode and start a run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a note or a continuous controller message.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a positive whole-number starting bar.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a saved kit to edit its sounds.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a tempo between 30 and 400 BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a valid first-beat offset.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a valid instrument.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose a valid pattern tempo and grid.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose an input and press Start.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose an input and press Start. Existing settings stay in place until a reliable result is ready.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose an input and press Start. Tap to the sound.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose another lesson in the Library` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose audio no longer than 5 minutes.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose between 2 and 12 beats per bar.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose file` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose folder` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose how many days to play each week.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose how played hits appear on the Focus strip.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose mono or stereo audio.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose one ZIP at a time, or select audio files without a ZIP.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose one audio file for an instrument, or drop it on its row. All pads using that instrument share the sound.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose one file per instrument. Skip files you do not want. Saving replaces the selected instruments together.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose only one file for each instrument. Skip duplicate assignments.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose short hits for pads. The limits above still apply; long loops or unsupported formats may be rejected.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose song bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the CC behavior your controller sends.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the CC behavior your controller sends. MIDI Learn detects the signal, channel and number; select the button behavior yourself.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the format sent by your endless encoder.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the format sent by your endless encoder. Each relative step changes tempo by 1 BPM, independently of the pad and button step. Reverse swaps the direction.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the input whose timing you want to measure.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the number of physical pad positions.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the same group on your controller.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the source in the Library; this shows the current source.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose the value used by this control.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose two anchors inside the track, with B after A.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose what Space does while a lesson is open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose what to practise next` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Choose whether daily training is displayed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Chorus {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Chrome or Edge · macOS, Windows, Linux` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clap and kick land together on 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clap and kick land together on 2 and 4. Let both hands arrive together; the tom just before them stays separate.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean repeat {n} of {total}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean repeats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean repeats {done} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean run at full tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean run at full tempo. Lesson complete.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean run at full tempo. Song complete.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean run at goal tempo: {n} of 3.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean run at goal tempo: {n} of 3. Keep the same tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean runs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clean runs raise your tempo automatically.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clear assignment` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clear knob` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Clear the knob mapping first, or choose another control.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Click` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Click to turn assistance off` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close course navigation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close drawer` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close guide` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close notification` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close other Smack-a-Pad tabs and try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close setup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close the editor without saving changes.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Close. Repeat at the same tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Colour = instrument. Labels show the hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Combine a same-hand chord with a continuing offbeat line.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Combine kick, backbeat and quarter-note hats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete a full Practice run with a score of at least {score} %.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete a full Practice run with a successful Learning run or a score of at least {score} %.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete a lesson on 100 different local days.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete a lesson on 30 consecutive local days.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete a lesson on 7 consecutive local days.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete both the 8-pad and 16-pad checks in one guided lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete one whole check game with Training enabled.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete the stars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Complete this lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Completed / started` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Completed ✓` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Confirm the track tempo and first beat before recording a pattern.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Connect a MIDI controller first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Connect a MIDI input first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Connect a controller and allow MIDI access in the browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Connect a controller and allow MIDI access when asked.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Connect your MIDI controller, arrange the pads and check that everything responds.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Connected MIDI controller` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Connection` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Consecutive days: {count}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continue guided path` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continue in Practice; return here to download.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continue to the next lesson or replay this one.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continue where you left off` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continue your practice` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continue {next} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continue:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Continuous loop · count-in once.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Control and detail` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Controller buttons for starting and stopping, and tempo settings.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Controller check` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Controller layout` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Controller model` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Controller, timing, sound and progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Controller:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Controls` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Copy` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Could not reach the license server.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Could not reach the license server. Check your connection and try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 1 & 2 & 3 & 4 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 1 & 2 & 3 & 4 &. Play every syllable with your right hand on Hat R.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 1 & 2 & 3 & 4 &. Play kick with your left hand; each & is Hat R with your right hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 1 e & a aloud.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 1 e & a, 2 e & a, 3 e & a, 4 e & a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 1, 2, 3, 4 aloud with the click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 1, 2, 3, 4 aloud with the click. Play Kick L with your left hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 4 & even though the & is silent.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count 4 & even though the & is silent. Return to 1 exactly with the click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count all four beats even when the snare gives the groove a slower feel.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count beat intervals: beat 1 to beat 129 is 128 intervals. Use distant anchors for a more precise result.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count both bars and keep the five-kick shape unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count both bars and keep the second bar identical to the first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count every beat even though the rim gives the pattern a different shape.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count every beat; play Snare L with your left hand only on 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count the last beat 4 e & a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count the last beat 4 e & a. Your right hand plays Hat R on 4, &, a; the next 1 stays in place.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count the missing hat silently.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count through beats that have no kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count-in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count-in before every repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count-in before every repeat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count-in starts when ready` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count-in · {n} beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count-in · {n} beats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Count-in · {n}. Listen first; then tap ten times.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Country fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Country fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Country fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Counts toward tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Course` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Course edition` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Course list` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Course order` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Course progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Course visibility` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Create a kit and choose its built-in base kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Create a kit before adding audio files.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Create a local kit with the selected base sounds.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Create kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Current MIDI channel, controller and tempo range.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Current controller assignment for starting and stopping.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Current playback run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Current sound kit:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Daily training` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Dance offbeats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Dance with a clap` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Data and app` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Day series` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Default sound kit saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Default. Each hit stays visible until the end of the bar.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete all progress in this browser? Download a backup first if you want to keep it.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete profile "%@"?` | EN, CS | Reused the existing Czech translation of Delete \\"%@\\"?. |
| `Delete progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete progress only after downloading a backup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete progress…` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete this audio from this device? This cannot be undone.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete this kit and its sounds?` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Delete this pattern from this device? This cannot be undone.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Deletes saved lesson progress and rewards. Download a backup first. This cannot be undone.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Dembow with hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Dembow with rim and shaker` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Density Ladder always uses both hands.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Density increases after a clean run. Auto tempo off.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Density {n}/{total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Density:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Detect the signal, channel and number.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Detected CC {n} on channel {channel}. Choose the knob mode, then save.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Device` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Device dependent` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Device event timestamp` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Difficulty jump +{n}. Try easier lessons first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Difficulty jump compared with the previous lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Dim unused pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Discard recording` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Disco song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Disco with sixteenth hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Divide each beat into two equal parts.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not accent or delay every hat just because a kick joins.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not add a fifth beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not bunch the right-hand hit close to the kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not leave a gap at the bar line or rush the return to bar 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not move beat 4 earlier to make room for the extra kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not pause the right hand when the left hand joins.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not press rim and kick together.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not shorten the silent space at the end of the bar.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Do not speed up between beats 3 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Done, try without the ladder` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Double track tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download a backup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download a backup before changing browsers or devices.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download a backup in Settings before closing.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download a backup now and then, and load it on another computer to continue there.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download a progress backup regularly.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download a sound or a sample pack from a library below.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download all for offline` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download all for offline ({size})` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download backup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download backup · {n} lessons not backed up` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download before reloading.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download cancelled. Downloaded sounds are kept.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download report` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Download the recorded MIDI signals and results.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Downloaded` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Downloaded {done}/{total} sounds ({size}).` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Downloading kit {kit} ({size}) … {done}/{total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Drop {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Drum and bass on the ride` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Drum and bass song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Drum and bass two-step` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Drum and bass with ghost snares` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Drum and bass, ghost snares` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Drum and bass, two bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Dubstep with kick push` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Dubstep with sixteenth hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Duplicate filename. Check its folder and assignment.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Duplicate kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Duration at start → goal tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `ELECTRONIC PATH · 12 GUIDED LESSONS` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `EXTENSION LESSONS` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `EXTENSIONS` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each audio file must be 10 MB or smaller.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each closed hat follows an open hat by one sixteenth.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each closed hat follows an open hat by one sixteenth. Let the final kick of bar 2 lead into the next bar; do not merge the two kicks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each hit flashes briefly. The strip stays mostly empty.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each pad should score separately.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each relative step changes tempo by 1 BPM, independently of the pad and button step.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each run has its own count-in.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each sound has its own license: CC0, CC BY (credit required), CC BY-NC (non-commercial only), or legacy Sampling+ (restrictions apply).` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Each sound must be 8 seconds or shorter.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Earn this star at {bpm} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Earned` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Earned 1 new badge` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Earned clean runs accumulate in Learning mode.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Earned {count} badges` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Earned {count} new badges` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Easiest first` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Easy rock` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Edit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Eight and sixteen` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Eight steady hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Eight-pad arrangement:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Eighth notes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Eighth-note hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Electro with pushed kick` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Electronic 808` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Electronic path` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Electronic · Fischer 808` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Emphasise numbered beats and tap the & more gently.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `English` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enlarge the window to at least 1100 × 690 px.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enter a MIDI control, or choose Learn MIDI and press your button.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enter a positive whole number of intervals.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enter a tempo from another tool and click Set tempo. Bar lines will appear on the waveform; turn on the metronome and check by listening.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enter both a channel and a number.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enter the MIDI note or CC number from 0 to 127.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enter the controller number from 0 to 127.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Enter the number of intervals, or set a tempo to suggest it.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Esc or Stop = back to Practice` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Estimate` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Estimate ready. Verify it with the click before applying.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Estimate tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Estimates can be wrong. Verify the tempo and first beat by listening to the click over the track.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Estimating…` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Every hit and its timing stays intact.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Every hit, hand, velocity and timing is preserved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Everything` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Existing settings stay in place until a reliable result is ready.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Export .mid` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Export .mid lets you keep a pattern elsewhere.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Export kit ZIP` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Export this kit?` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Extension` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Extensions` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Extensions · outside the Path · easiest first` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Extra kick after three` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Extra kick after two` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `FOUNDATIONS · 24 GUIDED LESSONS` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Faster` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Faster by 1 BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Feel offbeat hats against a four-beat kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `File` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `File {name} has been downloaded.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fill in the channel, CC number and BPM range.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Find a song tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fine tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fine-tune scoring for this input and audio setup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Finish a four-bar club phrase with a snare answer and a clean restart.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Finish a full Practice run with` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Finish a full Practice run with a score of at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Finish a full Practice run with a successful Learning run or a score of at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Finish a full Practice run with a successful Learning run or at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Finish a full Practice run with at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First bar is a steady groove, then the fill` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First bar is a steady groove, then the fill.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First bar to loop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First fills` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First steps` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First-beat offset (seconds)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `First:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fischer TR-808 source` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fit two quick hats at the end of the bar.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fits when slowed to {n} %` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fixed increment for mapped tempo buttons.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Flash only` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Focus` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Focus on your next lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Focus: played hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Follow four count-in clicks, then tap once on each of the next ten clicks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Follow four count-in clicks, then tap once on each of the next ten clicks. Use one pad on your controller, or Space on your keyboard. Listen to the clicks; do not chase the visual indicator.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Follow playback` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Follow system · default` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork / juke · Build the syncopation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork / juke · extension` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · a short snare burst` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · displaced kicks` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · feel the half-time pulse` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · half-time pulse` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · hat response` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · open-hat response` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · snare burst` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · triplet feel` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · triplet subdivision` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · two-bar conversation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Footwork · two-bar talk` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For 100%:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For 100%: {n} more clean full run at {bpm} BPM or faster.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For 100%: {n} more clean full runs at {bpm} BPM or faster.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For 100%: {n} more consecutive clean full run at {bpm} BPM or faster.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For 100%: {n} more consecutive clean full runs at {bpm} BPM or faster.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For a knob, learn its MIDI CC below.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For a momentary CC button, both press and release trigger an action in change mode.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For better sound, download the {kit} kit ({size}).` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For evenings and dark studios` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For offline use, choose Install in your browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For offline use, choose Install in your browser. Download a progress backup regularly.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For playing, use wired headphones or speakers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For several sounds, choose Add sounds, a folder or a ZIP. Check the assignments and save.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `For the guided goal, practise at goal tempo with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Foundation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Foundations` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Four on the floor` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Four on the floor with clap` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Free WAV sample packs: drums, 808, percussion, cymbals, hi-hats and loops.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Free drum and sound-effect packs.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Free playing over audio. Starting a lesson pauses the track.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Freesound licenses` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `From bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `From section` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Full ({n} bars)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Full density` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Full lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Full training` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fully complete` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Fully completed lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fast fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fast fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fast fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk purdieshuffle fill` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk rock fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk rock fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk rock fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk rock fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk rock fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk rock fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk song 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Funk, soul, blues` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `GUIDED PATH · INCLUDED` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Gap click` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Genre extensions` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Genre filters` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Genre library` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Genre matches` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Genre · all levels · easiest first` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Genre: all` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Get more sounds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Get the full course` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `GetSongBPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ghost notes and dynamics` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ghost notes {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Goal achieved` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Goal reached` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Goal reached in this controller mode` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Goal tempo reached` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Goal tempo reached · keep it clean.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Goal: {bpm} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Goal: {bpm} BPM · at least {score}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Good` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Gospel fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Gospel fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Gradually · recommended` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Great` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Grid` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Grid click` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Groove variations` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Groove {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Groove, fill, return` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Grooves` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Grooves and fills adapted from the` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Guide` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Guided goal reached.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Guided goal reached. Try the next lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Guided path passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Halve track tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hand and loudness are not verified.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hands take turns` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hardgroove 1 · tom pickups` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hardgroove 2 · open-hat drive` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hardgroove 3 · clap accents` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hardgroove 4 · four-bar return` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hardgroove 4 · the return` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hardgroove drum construction · Jon Musgrave` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hardgroove · 4 guided lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hat L` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hat R` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `HatL` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `HatR` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hats with a kick anchor` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hats, snares and the final rim stay the same.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hear alternating strong and soft hats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hidden courses:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hide completed courses` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hide course` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hide passed lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hide: nothing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop and trap` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 7` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 8` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hip hop fill 9` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hits moved by this grid: {count}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hold a steady pulse when the kick leaves the quarter-note grid.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hold eighth-note hats and return cleanly after their break.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Home Screen web apps have an exception.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House and techno currently use 808; a dedicated 909 kit is not included.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House song 1 (layers)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House/Techno` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House/Techno · synthesized` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House: kick and clap` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House: offbeat open hat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House: shaker groove` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `House: sixteenth hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `How it works` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `How to practise` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `How to read the pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Hundred days` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `If it is a ZIP, leave it zipped.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import as a new kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import audio` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import cancelled. No changes were saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import kit ZIP` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import preview:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import preview: Merge adds {ma} lessons and changes {mc}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import preview: Merge adds {ma} lessons and changes {mc}. Replace adds {ra}, changes {rc}, and removes {rr}. Choose Merge or Replace.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Import was cancelled.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Importing progress does not unlock the full course.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In 8-pad mode the two toms occupy unused top-row slots.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In 8-pad mode the two toms occupy unused top-row slots. The left hand rests during the fill. Reposition the right hand calmly before beat 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In Challenge mode the 3 clean runs must be consecutive.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In Safari on Mac, WebKit may delete script-writable website data after seven days of Safari use without interaction with this site.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In Safari on Mac, WebKit may delete script-writable website data after seven days of Safari use without interaction with this site. Home Screen web apps have an exception. Keep a downloaded backup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In bar 1, the middle kick is on 2 a; in bar 2 it moves earlier to 2 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In bar 4, leave out the final closed hat and play rim answers on 4 e and 4 a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `In bar 4, replace the clap on 4 with a short snare answer on 4, 4 & and 4 a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Include the controller model in the test report.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Included` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Included full course` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Includes stereo cymbals with four recorded variants for closed hat, ride and crash, three for open hat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Input offset` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Install` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Install Smack-a-Pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Install the app for offline use when the browser allows it.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Installation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Installation status` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Installed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Instrument / pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Interface language` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Intervals` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Intervals between anchors` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Intro {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `It is a deliberate change, not a timing mistake.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz and New Orleans` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz funk fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz funk fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz funk fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz funk fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz funk fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz funk fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz fusion fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz fusion fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz fusion fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz linear 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz linear 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz march 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz march 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz march 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz march 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz march 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz march 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz mediumfast` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz · Virtuosity + AVL clap` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jazz — Virtuosity selection` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey and footwork` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey club · Learn the bounce` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey club · extension` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey rhythm reference · Native Instruments` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · a snare answer` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · a two-bar snare variation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · backbeat bounce` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · bounce with a backbeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · groove and break` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · groove, break and return` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · right-hand anchor` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · the five-kick bounce` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · the right-hand anchor` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Jersey · two-bar snare twist` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Join a groove bar, fill bar and clean return.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Join two different kick phrases while keeping the right hand steady.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `KEYBOARD` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep a calm quarter-note pulse beneath a half-time snare.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep a dance pulse under a skippy two-bar hat and kick phrase.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep a downloaded backup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep a downloaded copy of your progress.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep a four-bar form through an intentional gap and a rim answer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep alternating the two kick shapes across four bars.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep alternating the two kick shapes across four bars. In bar 4, leave out the final closed hat and play rim answers on 4 e and 4 a. Count the missing hat silently. Return to the kick on 1. Practise bar 4 as a section, then finish a full run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep counting through the silent beats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep eight hats flowing over kicks on 1 and 3.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep four equally spaced beats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep hats flowing while the left fingers alternate.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep hats on every & and snares on beats 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep hats on every & and snares on beats 2 and 4. Kicks land on 1, 2 a and 3 &. Count through beats that have no kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep hats steady while the snare joins on 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep it independent; do not move either kick to the clap.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep lesson 1 unchanged and add a right-hand rim on 4 a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep lesson 1 unchanged and add a right-hand rim on 4 a. The hat on 4 & comes first, then the rim, then the kick on the next 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep open hats on every & and add short closed hats on 1 a and 3 a.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep practising; previous progress is safe.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep quarter-note kicks with the right hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep quarter-note kicks with the right hand. Place each low tom one sixteenth before the next kick. Count 1 e & a aloud. Start slowly; first listen to the two sounds answering each other.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the & evenly between the numbered beats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the final two taps small and relaxed; lower BPM if tense.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the five-kick shape even across the loop.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the groove steady when the section changes.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the hand relaxed; do not rush the following kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick and right-hand hats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick and right-hand hats. Your left hand plays snare on 3, then 3 a and 4. Start slowly: the last two snare hits are one sixteenth note apart.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick and tom pattern from lesson 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick and tom pattern from lesson 1. Add open hats on every &. The right hand moves between Kick R and Open hat; the left hand keeps the tom pickups.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick pulse steady even when the hats feel stronger.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick shape while adding two claps.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick steady while the other hand anticipates each beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick steady.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick unchanged through a quieter extra snare.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the kick under it, then return to 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the missing final hat silent while playing the final kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the missing final hat silent while playing the final kick. This is an original performance variation, not a transcription of a record.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the pulse and try again; previous settings are unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the pulse through a missing final hat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the right-hand kick steady and the left-hand tom pickups intact.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the rolling pattern stable when the clap joins.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the same BPM across both bars; the fill does not change the pulse.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the same left-hand pattern.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the same left-hand pattern. Add Hat R with your right hand on beats 2 and 4. Listen to each layer before playing all three.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the same pulse with your right hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the same tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the second bar the same length as the first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the second bar the same length as the first. The two final kicks are only one sixteenth apart. This is an original footwork-inspired study.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the snare on 2 and 4 as solid as the kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep the wrist loose and avoid a flam.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep your left hand on snare and kick. Right hand rests during the answer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep your left hand over Kick L and Snare L. Alternate the pads on the four beats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep your right hand moving on Hat R. Your left hand plays Kick L on 1 and 3 and Snare L on 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keep your wrist loose and your taps small.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Key not recognised.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Key not recognised. Check it and try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keyboard input is available.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keyboard profile` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keyboard timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keyboard · Space` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keyboard: 1234 / QWER` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Keyboard: 1234 / QWER / ASDF / ZXCV` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick L and Clap are both left-hand pads and coincide on beat 2. Prepare both pads before the simultaneous hit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick R` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick and clap coincide on beat 2.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick and hat together` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick and offbeat hat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick and snare coincide twice.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick and snare coincide twice. Both pads must land together, without rushing toward the final kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick and snare land together on beat 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick and snare land together on beat 4. The following two snares are not evenly spaced triplets.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick on every beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kick, snare, kick, snare` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kicks land on 1, 2 a and 3 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kicks land on 1, 2, 3, 3 a and 4 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kit created. Choose a file for an instrument, then use this kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kit deleted.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kit duplicated.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kit exported. Keep the ZIP as a backup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kit imported.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kit name` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kit selected.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Kits, offline, calibration` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Knob not assigned` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ladder` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ladder: rung {n}/{total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Land the simultaneous kick, clap and hat together.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Land two different pads at the same instant.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Language, backup, version` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Language, progress backup, installation and version information.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last 32 hits · calibration` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last 32 scored hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last backup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last bar to loop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last completed repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last completed run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last hit:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last increase` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last increase: {from} → {to} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last played:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last repeat {score} %` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last repeat: {score}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last run {score} %` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last run: {n}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last run: {score}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last {n} runs: mostly early by {ms} ms.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last {n} runs: mostly late by {ms} ms.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Last {n} runs: on time (within ±10 ms).` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latest completed series` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin and world` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian baiao fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian bossa 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian bossa 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian frevo 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian frevo 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian ijexa 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian ijexa 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian ijexa 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian maracatu 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian maracatu 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian samba 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian samba 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian samba 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian sambareggae 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian sambareggae 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian sambareggae 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian sambareggae 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian sambareggae 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian sambareggae 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian songo 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian songo 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian songo 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin brazilian songo 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin dominican merengue 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin dominican merengue 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin dominican merengue 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin dominican merengue 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin dominican merengue 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin dominican merengue 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin samba fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Latin samba fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learn MIDI` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learn a new profile (MIDI learn)` | EN | Added the missing catalogue entry; existing translations retained. |
| `Learn every pad position in order.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learn tempo knob` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learn the kick changes alone, then add the other layers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learning` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learning allows a small timing or pad mistake.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learning and controls` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learning cancelled.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learning does not start playback.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learning will not change the tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Learning · full lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Left` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Left hand` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Left hand only` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Left hand · ghost note, play softly` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson access` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson bar {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson complete.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson completion` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson filters` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson guide` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson library` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson list` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson order` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson order, access, daily training and Focus.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson passed. Take the next step.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson passed. You can continue to the next lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson passed. You can move on and return for the tempo goal later.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson progress and stars stay unchanged. Once every two to four weeks is enough.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson requirements` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson settings` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson state` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lesson states` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lessons and training` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Lessons for this track` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Let both hands arrive together; the tom just before them stays separate.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Let the final kick of bar 2 lead into the next bar; do not merge the two kicks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Let the next kick start the phrase again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Level {min}–{max}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Level {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Level {n} of 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Level · Path order` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Library bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Library content` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Library groups` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `License key` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `License pages checked on 4 October 2026. Read the current terms before using or sharing sounds. Smack-a-Pad does not download sounds for you.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Licensed for personal and commercial projects without royalties; editing is allowed. Do not sell or redistribute the audio files on their own, even for free.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Licensed for use in your music without royalties. Do not redistribute the sample files.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Licenses and sound sources · Advanced` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Light up the next pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Light, dark or system appearance. Application language.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Limit reached · recording stopped` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen first` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen first and count three equal parts per beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen first, then Play along, then Practice.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen first. Emphasise numbered beats and tap the & more gently.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen first; then tap ten times.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen for one combined attack.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen to each layer before playing all three.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen to each layer first; this first exercise uses a straight grid.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen to four clicks, then tap on the next ten.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen to the clicks; do not chase the visual indicator.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Listen to the louder clap accents and the softer tom answers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Load backup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Load the selected kit before saving it as the default.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loading sounds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loading the next kit. Pads keep the current sound.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loads on first play` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop a section` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop bars 2 or 4 first, then turn the section loop off for a full run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop bars {from}–{to}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop end` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop lesson bars {from}–{to}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop selection` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Loop start` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Low certainty. Verify the tempo by listening.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MAIN COURSE` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MAIN COURSE · INCLUDED` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI Learn` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI Learn detects the signal, channel and number; select the button behavior yourself.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI access blocked` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI access is blocked` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI access is blocked.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI clock changed during calibration.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI clock changed during calibration. Try again with a stable timing mode.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI input` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI needs permission from the browser and a controller recognized by your system.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI needs permission from the browser and a controller recognized by your system. On a Mac, use Chrome, Edge or Firefox for MIDI. This page checks MIDI support in your current browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI not connected` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI pads, mapping and calibration. A well-set controller makes accurate scoring possible.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI requires a secure HTTPS page.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI start / stop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI tempo step` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `MIDI, layout, check` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Main` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Main course` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Main course · included` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Main path` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map Tempo − and Tempo + above to two pads or buttons.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map Tempo − and Tempo + above to two pads or buttons. For a knob, learn its MIDI CC below. Tempo controls work while a lesson is open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map any number of positions. Keep the same assignments on your controller. Choose a position to change just that pad.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map controller pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map controls` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map tempo control` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Map the eight physical pads once; their MIDI map is saved separately from the sixteen-pad layout.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Mapping saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Match the MIDI channel sent by your controller.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Match the MIDI values sent by your knob.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Match the current tempo before taking over` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Match the press and release values of your button.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Maximum BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Mean offset` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Measure` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Measure again` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Median timing with a ± spread band.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Medium` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Memory star` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Memory star earned` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Memory: at least {score}% at {bpm} BPM after one listen` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Merge adds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Merged progress:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Merged progress: {n} added, {changed} changed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Middle Eastern 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Middle Eastern 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Middle Eastern 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Minimum BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Minimum must be lower than maximum.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Miss` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Missed hit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Missed hit count` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Mix complete` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Moombahton with hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `More` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `More settings` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `More sound sources` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Motown song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Move to two toms while keeping the bar length.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Move your fingers rather than lifting the whole hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Moving pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My audio` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My audio can store up to 256 MiB. Delete a track first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My kits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My kits are loading.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My kits are still loading. Please try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My kits can store up to 100 MB in total. Remove some sounds first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My kits · Advanced` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `My patterns use 4/4. Set four beats per bar before recording.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `NOW` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Name the kit you want to create.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Need 90% for a clean run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Need {threshold}%, scored {score}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Needs 16 pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 10` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 11` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 12` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 13` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 14` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 15` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 16` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 7` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 8` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New Orleans funk fill 9` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New VCSL percussion and Swirly bongos use CC0 1.0. This kit also reuses unchanged Acoustic recordings under CC BY-SA 3.0; their original credits and license still apply.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New count-in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New sample origins` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New version available` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `New version available —` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next Check game lesson:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next Mix lesson:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next count-in in 1.2 s` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next in training` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next lesson →` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next on the path` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next repeat:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Next repeat: {n} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No MIDI controller` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No audio saved yet.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No changes were saved. Please try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No clearly weak place.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No completed series yet` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No controller found` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No expected hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No hits were recorded` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No hits were recorded — check your MIDI connection or try the keyboard.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No hits were recorded. Try recording again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No lesson matches these filters.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No lessons in this view.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No lessons in this view. Show passed lessons, select another course or restore a hidden course on the left.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No name match. Choose an instrument or skip.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No patterns saved yet.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No review due` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No run yet` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No saved kits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No saved kits yet.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No songs match these filters.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No suitable lesson for this tempo and genre.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `No supported audio files were found. Choose sounds or an exported kit ZIP.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not completed: accuracy {score}% of {threshold}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not completed: play the whole lesson without a section loop.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not completed: tempo {bpm} of {target} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not completed: two reviews per visit. Come back for another visit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not counted` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not counted in {kind}: {reason}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not downloaded` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not downloaded yet` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not passed yet` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not played yet.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not started yet` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not supported` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not used by kit.json. Choose an instrument or skip.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Not yet` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Note {n}. Use Map pads for the {mode}-pad layout.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Nothing is planned today. Choose a lesson in the Library.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Nothing planned` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Now` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Number` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `OK` | EN, CS | Added unchanged OK in both languages. |
| `Off {off} · missed {miss} · wrong pad {wrong}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Off-time hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Off: scoring follows your average lead or lag, so steady playing is rewarded. On: every hit is judged against the click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Offline sounds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `On a Mac, use Chrome, Edge or Firefox for MIDI.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `On average you are` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `On average you are {n} ms early.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `On average you are {n} ms late.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `On macOS Sonoma 14 or later, choose File → Add to Dock in Safari to open a separate app. Download a backup first and restore it there.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `On macOS, use Chrome, Edge or Firefox.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `One open hat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `One-bar count-in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Only first attempts count, without rehearsal.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Only positions unused by the pattern are reassigned.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Only the selected tester lessons can be played.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Only the selected tester lessons can be played. Importing progress does not unlock the full course.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open Settings › Sound kits › My kits › Add sounds and choose files or a ZIP. Create a kit first if needed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open a lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open a playable lesson to use its pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open all lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open course navigation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open demo version` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open hat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open hat on the and` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open hat {count}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open the existing pad mapping guide.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open the list to see your new badges.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Open timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Opens after passing {needed} lessons in stage {stage} (now {passed})` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100 % goal: one clean full run at {bpm} BPM or faster.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100 % goal: three clean full runs at {bpm} BPM or faster, scoring at least 90 % with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100 % goal: three consecutive clean full runs at {bpm} BPM or faster, scoring at least 90 % with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100% goal:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100% goal: 1 clean full run at {bpm} BPM or faster.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100% goal: {n} clean full run at {bpm} BPM or faster, scoring at least 90% with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100% goal: {n} clean full runs at {bpm} BPM or faster, scoring at least 90% with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100% goal: {n} consecutive clean full run at {bpm} BPM or faster, scoring at least 90% with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional 100% goal: {n} consecutive clean full runs at {bpm} BPM or faster, scoring at least 90% with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Optional · model name` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Options` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Original pad exercise informed by these production references.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Original pad exercise informed by these production references. The practice progression is our suggestion.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Original project synthesis under CC0 1.0, without third-party recorded samples.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Other` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Other achievements` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Other courses to explore` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Other modules can open progressively after a pass (80% or better), or you can keep every lesson open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Outlier taps ignored.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Outro {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pad assignments` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pad layout` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pad names and lesson rhythms stay the same.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Paper light` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Part of the full version` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass & tempo goal` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass a full Practice run with` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass a full Practice run with a score of at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass a full Practice run with a successful Learning run or a score of at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass a full Practice run with a successful Learning run or at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass a full Practice run with at least {score}%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass at ≥80%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass this lesson with ≥80% in a full Practice run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass with a successful Learning run or ≥80%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass with a successful full Learning run or ≥80%.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass {needed} lesson in stage {stage}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass {needed} lessons in stage {stage}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass {needed} lessons in stage {stage} · {passed} / {needed}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass {n}: {score}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass {pass}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: a score of at least {score}% in a full Practice run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: a score of at least {score}% in a full Practice run. The target-tempo goal is optional for moving on.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: a successful Learning run or a score of at least {score}% in a full Practice run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: a successful Learning run or a score of at least {score}% in a full Practice run. The target-tempo goal is optional for moving on.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: a successful Learning run or at least {score}% in a full Practice run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: a successful Learning run or at least {score}% in a full Practice run. The target-tempo goal is optional for moving on.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: at least {score}% in a full Practice run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pass: at least {score}% in a full Practice run. The target-tempo goal is optional for moving on.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Passed · include completed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Passed, goal remaining` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Passed. For the guided goal, practise at goal tempo with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Passed. Keep practising at this tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Passed. Keep practising; previous progress is safe.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Passed. Play it cleaner to raise the tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Path · Level {level} · stage {stage} of {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Path · Level {level} · {technique} · {index} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern length` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern name` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern notation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern preview · first bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern saved on this device.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern storage is unavailable. Try a regular browser window.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pattern ·` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Patterns stay in this browser and are not included in progress backups.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pause audio` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Perfect` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Perfectly timed hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Persistent · default` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Physical pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Place a syncopated rim over a steady dance pulse.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Place each low tom one sixteenth before the next kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Place syncopated kicks between the right-hand pulse.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Place the snare with the last part of the bounce.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Place triplet-grid kicks around the steady beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play Hat R with your right hand. Keep your wrist loose and your taps small.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play Kick L and Hat R together with both hands on every beat. Listen for one combined attack.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play Kick L with your left hand. Count 1 e & a, 2 e & a, 3 e & a, 4 e & a. Kicks land on 1, 2, 3, 3 a and 4 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play a complete one-bar rock/pop groove.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play a lesson to unlock` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play a short snare burst without changing the pulse.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play again` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play along` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play audio` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play closed hats with your right hand. On 4 &, play Open hat above it in 16-pad mode or next to it in 8-pad mode with the same hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play every numbered beat on Kick L with your left hand; answer on each & on Hat R with your right hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play familiar lessons in sequence.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play four bars. Bar 2 shifts just one tom from a to & after beat 2. Bar 4 adds a high-tom answer on 4 & before the low tom on 4 a. Let the next kick start the phrase again. Loop bars 2 or 4 first, then turn the section loop off for a full run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play four hits from the selected kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play it cleaner to raise the tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play kick and clap together with your left hand on 2 and 4; keep the left wrist relaxed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play the pattern with me` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play the two-bar idea as a four-bar phrase.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play the two-bar idea as a four-bar phrase. Bar 3 adds one quiet closed hat on 2 a. In bar 4, replace the clap on 4 with a short snare answer on 4, 4 & and 4 a. Keep the kick under it, then return to 1. This is a straight-grid foundation; fine shuffle is not scored separately.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play the whole lesson without practice aids` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play to unlock` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play two eighth-note kicks with a steady right hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play with pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play without the pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Play:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Playback could not start. Press Play to try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Playback could not start. Press Record pattern to try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Playback run progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Playback speed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Played {score}% – try again or tomorrow` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Playing the track before the recording window.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pop and country` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Position` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Position {position}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Positions unused by the lesson can carry its additional instruments; the pad labels show each assignment.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice density {rung}/{total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice density {rung}/{total} · not counted` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice layer` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice layer · not counted` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice repeats automatically.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice result` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice setup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice tempo progression` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practice {n} bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practise` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practise at this tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practise bar 4 as a section, then finish a full run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practise this place` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Practise this section` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Prepare for:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Preparing recording…` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Play again to enable audio` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Play to retry` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Practice` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Practice again to repeat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Space` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Space with each click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Start again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press Stop to end the loop.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Press the controller button once. Learning does not start playback.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Preview kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Preview playing.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Preview sound` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Preview the sound, adjust its volume, then select Use this kit to play it.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Previous` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Previous kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Previous lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Previous settings kept.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Production tutorial · UNIIQU3 / Splice` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Production workshop · Side Brain (paid, free preview)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Progress backup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Progress backup, installation and version. Reset progress at the bottom.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Progress is saved in this browser only.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Progress is saved in this browser only. Download a backup now and then, and load it on another computer to continue there.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Progress kept: {n} of {total}. Keep practising at this tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Progress reset.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Progressive techno layers · Attack Magazine` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Pulse` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Punk fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Punk fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Punk fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Punk fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Punk fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Punk fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Punk song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Put the right hand halfway between left-hand beats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Put the rim on 2 & and on beat 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Quarter-note hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Quick transport` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Raise tempo after` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Read the sound license. Imported sounds stay only in this browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ready` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ready to install` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recalculate waveform` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recalibrate` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recent MIDI signals` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recommended sound kit for this genre:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recommended sound kit for this genre: {kit}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Record a short test of your pads, simultaneous hits and mapped controls.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Record a short test of your pads, simultaneous hits and mapped controls. The report includes MIDI signals and Practice results so a problem can be reproduced.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Record again` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Record at least eight of ten clicks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Record pads, simultaneous hits and mapped controls.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Record pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recorded hits: {count}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recorded sounds use 1–5 velocity layers and, where available, alternate recorded takes. House/Techno uses synthesized sounds. Keyboard input uses a fixed velocity. Samples load before the lesson count-in begins. All eight kits are included in the offline package; decoded buffers are reused during this session. Shared files are loaded once across kits. A closed hi-hat cuts off an open hi-hat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recorded sounds use 1–5 velocity layers and, where available, alternate recorded takes. House/Techno uses synthesized sounds. Keyboard input uses a fixed velocity. Samples load before the lesson count-in begins. In the online version, Acoustic, 808 and House are saved first; download other kits for offline use; decoded buffers are reused during this session. Shared files are loaded once across kits. A closed hi-hat cuts off an open hi-hat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recording bar {bar} of {bars}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recording cancelled. Nothing was saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recording is off.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recording is off. Test reports stay in this tab until you download them or reload.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Recording progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reggae fill` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Relative · 1 / 127 (2’s complement)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Relative · 1 / 65 (signed bit)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Relative · 65 / 63 (binary offset)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Relax the hand.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Remap all pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Remember a four-bar phrase and return to beat 1 after a short tom answer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Remove only the selected pad assignment.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Remove only the tempo knob assignment.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rename` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rename kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rename the selected local kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Repeat Practice automatically` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Repeat at the same tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Repeat details · {score}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Repeat slowly. Aim for 80% to pass; every guided lesson remains open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Repeat the groove across a visible two-bar phrase.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Repeating Practice · press Stop to finish` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Replace adds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Replace adds {ra}, changes {rc}, and removes {rr}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Replace assignments after confirmation.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Replaced progress:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Replaced progress: {n} added, {changed} changed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reposition the right hand calmly before beat 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Requirements` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reset filters` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reset progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reset taps` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rest without losing time` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Restarting` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Restarting with count-in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Restore` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Restore Auto` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Restore a hidden course or browse lessons to choose your next session.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Restore base sound` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Result` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Resume lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Retry sounds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Return to` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Return to 1 exactly with the click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Return to kick and hat together on bar 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Return to the kick on 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Return together on bar 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Return your right hand to the closed hat without rushing.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Return your right hand to the closed hat without rushing. Check the open-hat pad before starting; it sits above the closed-hat pad.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reverse knob direction` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reverse swaps the direction.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Review guided path` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Review in %lld days · practice only` | CS | Added the missing catalogue entry; existing translations retained. |
| `Review lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Review · step %lld of 4 · from memory at %lld BPM, 80 %` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Reviews after 7 days:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Revisit a favourite or work towards the target-tempo goals.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Right` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Right hand` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Right hand only` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Right hand rests during the answer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Right hand stops after 3 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Right hand stops after 3 &. Your left hand plays the snare on 4 and 4 &.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Right hand · ghost note, play softly` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock and punk` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 10` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 11` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 12` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 13` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 14` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 15` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 16` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 17` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 18` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 19` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 20` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 21` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 22` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 23` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 7` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 8` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock fill 9` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock halftime 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock halftime 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock halftime fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock halftime fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock halftime fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock halftime fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock recordings from Karoryfer Big Rusty Drums with VCSL percussion. The supplied audio files are unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock song 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Rock · Big Rusty + VCSL` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Royalty-free for personal and commercial projects; editing is allowed. Do not sell or redistribute the audio files on their own, even for free.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Royalty-free for use in your music. Do not redistribute the sample files.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Run accuracy` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Run complete` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Run complete · {done} of {total} bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Run details` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Run ended` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Run review` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `SOUND` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Safari may delete website data after 7 days without interaction; download backups regularly.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sample origins` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Save assigned sounds` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Save knob mapping` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Save mapping` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Save pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Save the selected tempo knob assignment.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Save the selected transport assignment.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saved audio` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saved kits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saved patterns` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saved seven-day review attempts and how many reached the passing score.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saved sounds: {saved} of {total}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saved tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saved timing for the selected input.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Saving changes…` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Score at least {score}%` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Scoring uses browser receipt time, including delivery jitter.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Scoring uses the device event timestamp, even if its clock differs.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Search lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section loop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section loop is on — does not count for lesson completion` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section loop off · Loop bars…` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section loop trainer` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section pass {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section practice does not complete the whole lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section practice does not complete the whole song.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section results` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Section scores show note timing and misses. Extra hits are counted in the total score.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Seems too slow? Try ×2 or ×3. Too fast? Try ÷2 or ÷3. Then listen with the metronome before using the estimate.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Select a section or play the whole song.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Select bar {bar} for section loop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Select bars, then press Practice.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Select bars, then press Practice. Section practice does not complete the whole lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Select the CC behavior, then save.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Select the sixteen-pad layout to play it.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Select the timestamp used for MIDI scoring.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Selected bars {from}–{to}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Selection and conversion notes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Series in progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Set a tempo or apply a checked estimate to get lesson suggestions.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Set anchor A here` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Set anchor B here` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Set tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Set the lower end of an absolute knob.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Set the track tempo and first beat to snap loops to complete bars. Variable tempo is not supported.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Set the upper end of an absolute knob.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Settings groups` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Settings sections` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Setup` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Several files match this instrument. Choose one; skip the others.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Short` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Short (16 bars)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Show badges` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Show daily training and spaced reviews.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Show more lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Show passed lessons, select another course or restore a hidden course on the left.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Shuffle song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Signal` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Six advanced lessons use one snare pad for both hands.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Skip this file` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Skipped {n} invalid song progress entries.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Slow down by 5–10 BPM and turn on “Play the pattern with me”.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Slower` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Slower by 1 BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Smack-a-Pad 808 — Fischer selection` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Smack-a-Pad Acoustic — AVL Black Pearl selection` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Smack-a-Pad Full — finger drumming course` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Snare R` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Snare and hat together` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Snare on two and four` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Song library` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Song map · bar {bar} of {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Song progress: Merge adds {a} versions and changes {b}. Replace adds {c}, changes {d}, and removes {e}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Song section results` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Song sections` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `SongBPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Songs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sort order` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sort:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 3` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 4` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 5` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 6` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 7` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 8` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul fill 9` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Soul motown fill` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sound and timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sound kit for pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sound kits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sound kits for lessons and offline sounds.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sound kits, your own sounds, offline sounds and latency calibration.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sounds are not ours. Share a kit only with sounds whose license allows redistribution.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sounds could not load. Try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sounds saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sounds stay only in this browser. Nothing is uploaded.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sources and sound details` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Space` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Space key` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Space key action` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sparse` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Speed garage 1 · the skippy top` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Speed garage 2 · fill and restart` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Speed garage 2 · fill, restart` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Speed garage production · The Producer School` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Spread improved from {a} to {b} ms.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Spread stayed at {b} ms.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Spread worsened from {a} to {b} ms.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Standard eight-pad layout.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Star 3: two reviews in Training · %lld of 2` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start 10-tap calibration` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start a run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start and stop from your keyboard or controller, and the tempo knob.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start at {bpm} BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start here` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start here · 24 guided lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start here · your first lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start keeps the current mode; Restart begins it again with a count-in.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start lesson 1` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start next lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start recording` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start slowly. Practise one section or a continuous range of sections.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start slowly: the last two snare hits are one sixteenth note apart.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start slowly; first listen to the two sounds answering each other.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start with a four-beat kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start with a four-beat kick. Put the rim on 2 & and on beat 4. Count every beat even though the rim gives the pattern a different shape.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start with the sounds of a built-in kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Start/stop buttons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Started` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Starting bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `State: all` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Static pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Steady timing offset. Try timing calibration.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Step for mapped MIDI tempo buttons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Stop ends playback.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Stop pattern` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Stop recording` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Stop recording; the report stays in this tab.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Stop whenever you like.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Stopped` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Stopped · before playback` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Storage space could not be checked. No changes were saved. Please try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Streak reset. Try the same section again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Strict timing (judge against the click)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Strike a pad to assign the selected position.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Strong and soft hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful repeat {n} of {total}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful repeat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful repeat. Automatic tempo is off.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful repeats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful repeats accumulate; a weaker repeat keeps your credit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful repeats {done} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful repetitions before raising tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful run: score {score}%, allowed errors used: {errors} of {limit}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful runs raise your tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Successful runs raise your tempo. A mistake keeps your progress.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Suggested count. Confirm it before applying.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Supported` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Sure? Unlock` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Swap the direction of tempo changes.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Swing and shuffle` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Switch from groove to a short snare fill on beat 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Switch the interface language; your saved data stays.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Switch to a clap on 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Switch to a clap on 2 and 4. Keep open hats on every & and add short closed hats on 1 a and 3 a. Bar 2 ends with one extra kick on 4 a. Listen to each layer first; this first exercise uses a straight grid.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Synth fallback` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Synth sounds in use — sample loading failed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Take the next step.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap at least four beats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap at the current playback speed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap every pad softly and firmly.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap every pad softly and firmly. Then strike two and three pads together.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap to the sound.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap {n} of {total} · {done} recorded.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap {n} of {total} · {done} recorded. Press Space with each click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap {n} of {total} · {done} recorded. Use one pad with each click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tap {n} recorded` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Taps were too uneven.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Taps were too uneven. Keep the pulse and try again; previous settings are unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Teaching` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Technique · all levels · easiest first` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Technique: all` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Techno song (layers)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Techno: kick and open hat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Techno: offbeat rim` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Techno: rolling hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Techno: syncopated rim` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo & learning` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo anchor A` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo anchor B` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo and sound` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo changed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo changed: {from} → {to} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo controls` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo controls work while a lesson is open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo estimate was inconclusive. Tap the beat instead.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo estimation failed. Try tapping or setting the tempo manually.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo from the internet is only an estimate (remixes and DJ versions often differ, or use half or double the tempo). Always check by listening with the metronome. The app sends nothing.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo goal reached` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo in range` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo increase` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo knob cleared.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo raised to {bpm} BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo will rise to {bpm} BPM at the next boundary.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo within 3 BPM of the range` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tempo: not set` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Temporary selection. Your default sound kit is unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Ten calibration taps` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tendency` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Test reports stay in this tab until you download them or reload.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tester preview` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tester preview · 120 / 595 lessons · all sound kits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The .mid file could not be downloaded. Try exporting the pattern again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The 24 guided lessons always stay open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The 24 guided lessons always stay open. Other modules can open progressively after a pass (80% or better), or you can keep every lesson open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The 808 remains available for other electronic genres and manual selection.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The Check game shows how well you play finger drums in general, not just in the lessons you have already practiced. You play a few new lessons near your level, once each and cold. The result is your baseline, and later games show whether you are improving.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The MIDI time is outside the supported range.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The Path` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The audio is unchanged; 65 files were selected and renamed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The auxiliary percussion has two recorded variants.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The chart appears after 3 completed runs.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The clap on 4 sits between the last two kicks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The clap on 4 sits between the last two kicks. Keep it independent; do not move either kick to the clap.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The connection was lost. Downloaded sounds are kept. Connect and try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The currently installed application build.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The default sound kit could not be saved. Try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The easiest unpassed lesson across all genres and techniques.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The eight-pad layout preserves the usual positions wherever possible.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The eight-pad layout preserves the usual positions wherever possible. Positions unused by the lesson can carry its additional instruments; the pad labels show each assignment. Six advanced lessons use one snare pad for both hands. Every hit and its timing stays intact. Map the eight physical pads once; their MIDI map is saved separately from the sixteen-pad layout.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The empty beats still take the same amount of time.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The extra left-hand kick is on the & of 2, after the left-hand snare.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The extra snare is a softer note, not an extra kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The extra snare is a softer note, not an extra kick. Count both bars and keep the five-kick shape unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The file stays only on this device.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The fill must end in time for the next kick on 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The final bar replaces the hat on 4 & with silence.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The final bar replaces the hat on 4 & with silence. An extra hat there counts as an extra hit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The final three kicks form a 3–3–2 grouping of sixteenth notes.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The final three kicks form a 3–3–2 grouping of sixteenth notes. These are dotted-eighth gaps, not evenly spaced triplets.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The first rim is between beats 2 and 3.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The first rim is between beats 2 and 3. The second rim lands together with the kick on beat 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The following two snares are not evenly spaced triplets.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The full course is now saved for offline use.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The genre` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The hat comes before the tom: & then a then the next kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The hat comes before the tom: & then a then the next kick. Think of three evenly spaced sixteenth positions.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The hat on 4 & comes first, then the rim, then the kick on the next 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The left hand rests during the fill.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The measured shift is over 200 ms.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The measured shift is over 200 ms. Check MIDI timing and audio output, then retry.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The next closed hat cuts the open sound.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The next unpassed lesson in the same genre as the last played lesson, easiest first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The next unpassed lesson using the same technique as the last played lesson, easiest first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The offbeat kicks must stay between hats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The offbeat kicks must stay between hats. Avoid dragging the snare forward to meet the following kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The open hat replaces the closed hit; it is not an extra hit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The practice progression is our suggestion.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The recording exceeded 2,000 hits. Nothing was saved; record a shorter pattern.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The remaining 475 are a preview of the full course.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The report includes MIDI signals and Practice results so a problem can be reproduced.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The right hand moves between Kick R and Open hat; the left hand keeps the tom pickups.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The rim is a sixteenth before the next kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The rim is a sixteenth before the next kick. Do not press rim and kick together.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The same eight-pad layout is used for the whole song.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The second kick is just before beat 3.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The second kick is just before beat 3. A silent downbeat is intentional; do not fill it with an extra kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The second rim lands together with the kick on beat 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The selected bars extend beyond the track. Choose an earlier start or fewer bars.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The selected bars repeat until Stop.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The slower starting tempo is for learning.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The snare on 4 must join the right-hand hat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The snare on 4 must join the right-hand hat. Use small taps; the burst must not pull the next bar early.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The target-tempo goal is optional for moving on.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The technique` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The timestamp/receipt difference is not measured sound latency; it may also reflect different clocks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The timestamp/receipt difference is not measured sound latency; it may also reflect different clocks. This records messages reported by the browser; MIDI cannot identify your fingers. Up to 3,000 entries; starting again clears the previous recording.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The tom lands on a, not on the next beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The tom lands on a, not on the next beat. Keep the hand relaxed; do not rush the following kick.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The track ended before recording finished. Nothing was saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The track plays one bar before recording. A–B jumps are suspended during recording.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `The two final kicks are only one sixteenth apart.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Then` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Then strike two and three pads together.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `There is not enough storage. Downloaded sounds are kept. Free some space and try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `These accumulate; a weaker run does not erase them.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `These are dotted-eighth gaps, not evenly spaced triplets.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `These subdivisions are actual equal triplets.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `These subdivisions are actual equal triplets. They differ from the Jersey 3–3–2 grouping. Listen first and count three equal parts per beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `They differ from the Jersey 3–3–2 grouping.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Think of three evenly spaced sixteenth positions.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This CC is assigned to the tempo knob.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This CC is assigned to the tempo knob. Clear the knob mapping first, or choose another control.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This ZIP contains an invalid file path.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This ZIP contains duplicate file paths. No changes were saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This ZIP contains more than one kit.json. Choose one kit at a time.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This ZIP is damaged or unsupported. Use a regular ZIP with store or deflate compression.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This ZIP is empty.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This adjusts scoring for your taps and current audio setup; it does not reduce sound latency or measure controller latency alone. Controller and keyboard profiles are separate. Repeat after changing speakers, headphones or MIDI timing mode. You can fine-tune the selected profile with the slider.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This audio file could not be decoded. It may be damaged or unsupported by this browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This audio file is damaged or unsupported by this browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This audio file is no longer available.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This browser could not save progress.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This browser could not save progress. Download a backup in Settings before closing.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This browser does not support MIDI controllers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This browser does not support MIDI controllers. On macOS, use Chrome, Edge or Firefox.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This browser does not support MIDI. Open the app in Chrome, Edge or another Chromium browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This does not complete the whole lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This exercise changes the previous clap layer to a snare layer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This file contains no playable audio.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This file is empty. Choose an audio file.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This file is not a Smack-a-Pad backup.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This hand already plays the entire lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This hand has no hits in this lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This includes delivery jitter; it is not a latency measurement.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This is a straight-grid foundation; fine shuffle is not scored separately.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This is an original footwork-inspired study.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This is an original performance variation, not a transcription of a record.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This is an original syncopation study.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This is optional and does not block the next lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This key reached its activation limit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This kit could not be loaded. Pads keep the current sound.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This kit is missing an audio file. No changes were saved.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This kit is not downloaded and you are offline.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This kit no longer exists.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This kit.json is invalid or too large.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This kit.json is not a supported Smack-a-Pad kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This lesson has 12 steps per bar: three equal parts per beat.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This lesson has 12 steps per bar: three equal parts per beat. Your right hand keeps hats on each beat. Your left hand plays kick on 1, the second triplet of 2, 3, and the third triplet of 3 and adds snare on 3.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This lesson has no density ladder.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This lesson is visible in the full course preview, but locked in this tester edition.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This page checks MIDI support in your current browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This pattern contains an invalid hit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This pattern is no longer available.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This pattern needs more than eight pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This pattern needs more than eight pads. Select the sixteen-pad layout to play it.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This purchase was refunded or disputed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This records messages reported by the browser; MIDI cannot identify your fingers.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This sound has a high peak level. Its volume has not been changed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This sound is missing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This sound is missing. Replace it or restore the base sound before duplicating this kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This sound is missing. Replace it or restore the base sound before exporting this kit.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This sound is not ready. Please try again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This sound is very quiet. Its volume has not been changed.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `This track is too short for a complete bar at this tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Three clean runs at goal tempo are an optional achievement; you can continue without them.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timestamps from this controller look delayed by ~` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing analysis` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing and pads are scored.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing and pads are scored. Hand and loudness are not verified.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing appears as you play.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing centering` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing is measured; the app cannot verify your hand or loudness.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing is scored; loudness is not.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing is scored; loudness is not. A keyboard cannot reproduce MIDI velocity.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing of the last hit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing trend` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing trend needs Training to be enabled.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Timing window` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Title, genre, technique…` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `To bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `To section` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Today: {done} of {total} done` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Today’s series` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Today’s training is complete` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Toggle` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Toggle button: every value change` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Toms` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Toms {count}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Too few hits to evaluate.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Too few taps. Record at least eight of ten clicks.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Total score {score}% · {wrong} wrong pad hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Track deleted.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Track tempo at 100 %` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Track volume` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Training always uses everything.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Training always uses full density.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Training complete → Home` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Training is off` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Training {index} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Transport controls work while a lesson is open.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Transport controls work while a lesson is open. Start keeps the current mode; Restart begins it again with a count-in. Stop ends playback.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Trap with hat roll` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Trap with sixteenth hats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Trap, two bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Treat the fill as part of the pulse; do not accelerate it.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Tried, not yet passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Triplet feel` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Triplet feel {count}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try Settings → Timing calibration.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try a tempo 10 BPM slower.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try again with a stable timing mode.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try all genres` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try easier lessons with similar pads. Then return to this lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try suggested kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try the next lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try the same section again.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try these first` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Try this tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Turn the knob slightly.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Turn the knob slightly. Learning will not change the tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Turn the knob to detect its MIDI signal.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Turn to {bpm} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Two hands` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Two separate attacks mean the hands are drifting apart.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Two-step garage with shaker` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Two-step garage with skip` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `UK funky & speed garage · 4 guided lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `UK funky 1 · syncopated rim` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `UK funky 1 · the syncopated rim` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `UK funky 2 · hats and rim` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `UK funky 2 · hats and rim together` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `UK funky drum example · UK Bass Tutorials` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Unavailable` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Undo tempo change` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Unlock lessons gradually or open the full library.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Unlock stage` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Unlock without completing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Unlocked. The full course is now saved for offline use.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Unsupported files skipped` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Up to 3,000 entries; starting again clears the previous recording.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Up to 64 MiB per file, 5 minutes, mono or stereo. Up to 256 MiB saved audio.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Up to three unplayed lessons, once each, at starting tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use Chrome, Edge or Firefox on a computer for a MIDI controller; keyboard input still works here.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use MIDI Learn, or enter the note or CC number manually.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use Start or Restart to play again` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use a channel from 1 to 16 and a number from 0 to 127.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use a kit name between 1 and 80 characters.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use a pattern name between 1 and 120 characters.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use an audio name between 1 and 120 characters.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use as default` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use browser receipt time?` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use channel 1–16, CC 0–127 and a BPM range between 40 and 220.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use channel 1–16, CC 0–127 and a BPM range between 40 and 220. Minimum must be lower than maximum.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use default controller notes or learn your own.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use estimate` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use full lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use one pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use one pad on your controller, or Space on your keyboard.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use one pad with each click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use small taps; the burst must not pull the next bar early.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use tap tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use the browser menu to install the app for offline use.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use the repeat count and BPM step above.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use this action for the current settings.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use this kit` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Use wired headphones or speakers; Bluetooth audio adds delay.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `VCSL + Swirly (drums from Acoustic)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Valid` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Variations` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Verse {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Version` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Version and licenses` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Versions` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Virtuosity CC0 license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Volume (dB)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Volume must be between −12 and +6 dB.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `WAV, MP3, OGG, M4A or AAC, if supported by your browser. Up to 10 MB and 8 seconds per sound, 100 MB in total and 20 kits.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Wait until the knob reaches the current tempo.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Watch for:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Watch the simultaneous hat/snare attacks on 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Waveform position` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Waveform ready.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `We recommend Wi-Fi.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Weakest bar: {bar}.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Weakest pad:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Weakest section:` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Web MIDI browser support` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Well-timed hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `What to complete` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `When slowed down, the metronome may lag slightly behind the track.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `White` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Whole song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Whole track` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `With pickup enabled, turn it to the current tempo first; the pad display shows the target.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Wood uses a stick click, Shaker uses maracas and Open hat uses the recorded hat swish.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Wood uses claves; Ride uses a short 808 cymbal setting.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `World` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `World keeps acoustic drums and adds recorded shaker, woodblock and cowbell; it does not change a snare into a conga.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `World percussion` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `World percussion · VCSL + Swirly (drums from Acoustic)` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `World uses Acoustic drums with percussion and bongos on the High tom / Low tom pads. Acoustic + World remains available manually. Pad names, assignments and lesson rhythms stay the same.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Wrong pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Wrong pad count` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `YOUR PACE` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `YOUR PRACTICE` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You are offline. Library websites need an internet connection; the instructions remain available.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You are using the free edition.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You can add the app to your Home Screen. Download a backup first and restore it in the installed app.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You can choose any palette manually.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You can continue to the next lesson.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You can save up to 100 patterns. Delete a pattern first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You can save up to 20 kits. Delete a kit first.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You can try faster.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You have passed every lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You play: left hand · machine plays right` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `You play: right hand · machine plays left` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your baseline for future check games.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your current browser has no Web MIDI support.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your current browser has no Web MIDI support. Use Chrome, Edge or Firefox on a computer for a MIDI controller; keyboard input still works here.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your current browser supports Web MIDI.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your current browser supports Web MIDI. Connect a controller and allow MIDI access when asked.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your default sound kit is in use.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your first groove` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your hands · {mode} pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your hits flash briefly` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your hits stay visible until the end of the bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your left hand keeps the Jersey kick and plays clap on 2 and 4. Your right hand plays eighth-note hats, then rests on the final 4 & of bar 2. Return together on bar 1.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your left hand plays kick on 3 and the & of 3, then the next snare on 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your left hand plays kick on every beat and adds clap on 2 and 4. Your right hand plays the offbeat hats.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your left hand plays kick; it plays Snare L on 3 and 3 a. Your right hand keeps hats on 2 and 4. This exercise changes the previous clap layer to a snare layer.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your next step` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your place and progress are saved in this browser.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your progress` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your progress and MIDI mappings stay unchanged.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your right hand keeps hats on 1, 2, 3 and 4. Your left hand plays kick on 1 and 3 and adds Snare L on 3. The slower starting tempo is for learning.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your right hand keeps quarter-note closed hats and adds Open hat on 2 & and 4 &, with left-hand kick. Your left hand keeps snare on 3. The next closed hat cuts the open sound.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your right hand keeps quarter-note hats. Your left hand plays kick on 1, 2 &, 3 & and 4 & and places the snare on 3. This is an original syncopation study.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your right hand keeps the pulse on Hat R. Your left hand alternates kick and snare.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your right hand plays Hat R on all four beats. Add Snare L with your left hand to the same click on beats 2 and 4.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your right hand plays High tom on 4 and Low tom on 4 &. Check the highlighted tom positions before starting.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your right hand plays eighth notes on Hat R. Your left hand joins on Kick L only on beats 1 and 3.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Your timing is centred.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Zoom` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Zoom in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `Zoom out` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `a score of at least` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `a successful Learning run or a score of at least` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `a successful Learning run or at least` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `added` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `after a clean repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `after a clean run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `after a successful repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `after a successful run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `after this` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `allowed errors: {used} of {limit}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `and removes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `at` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `at 60 and 80 BPM.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `at 60 and 80 BPM. Each pad should score separately.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `at least` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `at {bpm} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `auto timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `avg` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `avg {n} ms early` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `avg {n} ms late` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `bar {n} of {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `bars {from}–{to}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `beats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `boundary change` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `brush credits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `brush license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `brush source license · VCSL` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `brush source license · karoryfer.swirly-drums` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `by` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `by Google LLC, licensed under CC BY 4.0. Patterns were quantized, simplified and re-assigned to pads and hands. The 24 guided lessons are original Smack-a-Pad exercises. Lessons marked as standard patterns are common genre grooves.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `changed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `changes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `channel` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `channel {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `chg` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `clean full` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `clean repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `clean run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `clean runs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `combines AVL drums with Virtuosity shaker, low woodblock and cowbell.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `combines AVL drums with Virtuosity shaker, low woodblock and cowbell. The auxiliary percussion has two recorded variants. Pad names and lesson rhythms stay the same.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `completed courses hidden` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `connect a MIDI input` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `consecutive` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `consecutive clean full` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `consecutive clean repeats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `count` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `counts toward tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `does not count toward tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `early` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `event timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `exercises` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `existing default` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `extension` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `first beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `found · showing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `foundation` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `free edition` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `full lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `full run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `full test` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `genre exercises` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `ghost note, play softly` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `ghost notes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `good` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `guided` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `guided electronic lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `guided genre lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `hidden` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `hit the controller pad for` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `house credits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `house license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `in a full Practice run.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `invalid 16-pad mappings skipped` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `invalid 8-pad mappings skipped` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `invalid or unknown lesson entries skipped` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `knob at {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `last result` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `late` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `lesson` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `lesson bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `lesson bar {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `lesson {n} of {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `lessons and changes` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `lessons passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `level {range}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `loop bar 2, raise tempo after two successful repeats, then Stop.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `machine` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `minor error allowed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `missed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `missed hits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `more clean full` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `more consecutive clean full` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `ms. Use browser receipt time?` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `next` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `next +` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `next +{n} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `no hits recorded` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `not counted` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `now {bpm}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `now {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `off` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `on` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `one layer at a time` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `open Lesson settings to retry` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `or faster` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `pass {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `passed lessons hidden` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `passed {passed} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `perfect` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `phrase ending` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `physical pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `play the whole lesson without a loop.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `play without practice aids.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `playing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `progress kept` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `receipt clock` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `receipt timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `recorded` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `relative encoder` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `reliable result` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `removed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `repeat {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `repeats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `rest` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `reversed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `rock credits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `rock license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `rock source license · VCSL` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `rock source license · karoryfer.big-rusty-drums` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `runs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `same as bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `same as bar {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `saved tempo` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `scoring at least 90% with no missed hits or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `selected section` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `separate packs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `showing {n}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `spread {n} ms.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `stage` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `stages` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `stars {stars} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `streak reset` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `successful` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `successful repeat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `successful run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `synthesized` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `target-tempo goals` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `target-tempo goals in` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `timing` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `timing centred` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `to play` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `to start / stop` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `triplet feel` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `whole Path {passed} / {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `whole song` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `with each click.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `worldperc credits` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `worldperc license` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `worldperc source license · VCSL` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `worldperc source license · karoryfer.swirly-drums` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `wrong` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `wrong pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `wrong pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{bars} bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{count} exercises` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{difference} % compared with last time` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{done} / {total} clean runs in {mode}-pad mode.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{done} / {total} clean runs in {mode}-pad mode. Timing is measured; the app cannot verify your hand or loudness.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{done} / {total} completed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{done} / {total} consecutive clean runs in {mode}-pad mode.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{done} / {total} consecutive clean runs in {mode}-pad mode. Timing is measured; the app cannot verify your hand or loudness.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{done} of {total} bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{done} of {total} bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{foundation} foundation + {guided} guided genre lessons + {exercises} genre exercises` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{from} → {to} after a clean run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{from} → {to} after a successful run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{mapped} of {total} positions` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{mode}-pad mode` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{ms} ms early.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{ms} ms late.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} / {total} passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} / {total} passed, {goals} complete` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} bar` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} bar after this` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} bar to play` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} bars` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} bars after this` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} bars to play` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} beats` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} clean full run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} clean full runs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} clean run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} clean runs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} guided lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} included lessons · {extra} extension lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} invalid 16-pad mappings skipped.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} invalid 8-pad mappings skipped.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} invalid or unknown lesson entries skipped` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} invalid or unknown lesson entries skipped.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} lesson found` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} lessons found` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} missed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} more clean run at {bpm} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} more clean runs at {bpm} BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} of {total}` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} of {total} lessons passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} pad` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} runs` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} songs found` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} target-tempo goals` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n} wrong` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n}-bar run` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n}-day streak` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{n}/10 taps used` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{pads} pads` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{passed} / {total} PASSED` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{passed} / {total} lessons passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `{shown} of {total} lessons` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `−0.01 BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `−0.1 BPM` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `−1 beat` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `≥90%, no misses or wrong pads.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `≥90%, no misses or wrong pads. A weaker repeat resets the streak.` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |
| `✓ Passed` | EN, CS | Moved existing Czech TSV value; English keeps its key as the default text. |

## Format audit and open items

- No actual format-specifier mismatch was found. The test compares the complete printf tokens used by these catalogues, including lengths, positional markers, width, precision and escaped percent signs. Plain percentages followed by prose (for example `80 % in Play after me`) are literal text, not space-flag printf conversions.
- No ambiguous missing translation remains open. Runtime-provided lesson content is preserved through the full TSV migration; this ticket does not rewrite its wording or audit all non-localized UI literals.
- Final counts: 3221 English keys and 3224 Czech keys, with exactly the three documented Czech plural exceptions.

## Verification

- `xcodebuild build test` succeeded on the iPad (A16) simulator, iOS 27.0: 244 tests passed, zero failures. The command exited normally.
- Deletion check: temporarily removed `Instrument volumes` from English and ran the new catalogue test. It failed specifically because the key became an undocumented Czech-only key. Restored the English entry before the successful full suite.
- All 818 original English values and 819 original Czech values were verified unchanged; no TSV loader, resource, fallback or separate `String.LocalizationValue` lookup remains in app code or tests.

## Manual iPad check for Jakub

Switch between English and Czech and visit Home, Practice, Training, Settings and Help. Check for text in the wrong language, including the controller deletion prompt and practice progress. Check reminder wording for one, two to four, and five or more due lessons.
