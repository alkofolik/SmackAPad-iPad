# 154 — Controller presets without brand claims, no-controller hint, review notes

Status: ready. Blocked by: none. Source: AI panel round 1 (`docs/reviews/ai-panel/results/synthesis.md`, items 11 and 14; `round1-chatgpt.md` R3-01, R3-04, R3-06); `docs/2026-11-08-ai-panel-action-plan.md`, Batch 2. Approved by Jakub 2026-11-09.

## Goal

The app must not look as if it promises verified compatibility with a specific hardware brand. A player without a controller, and an App Review tester, must find at once that the app can be played without one.

## Decisions by Jakub (2026-11-09)

- No brand names anywhere in the app (neither "NI Maschine" nor "Akai"). Maschine hardware generally does not work on iOS.
- No list of tested controllers in the app, in the review notes or on the support page for now. The support page gets only a general sentence (rule 5). A list may come later, after TestFlight.

## Facts checked in the code (2026-11-09)

- `ControllerProfile.presets` in `SmackAPad/Sources/Data/LessonData.swift` holds `akaiMPD218` ("Akai MPD (36–51)"), `maschine` ("NI Maschine (36–51)") and `standard8`. The first two use the same note map (`standard16.noteMap`, 16 pads, notes 36–51), so they are one profile under two names.
- `ControllerSetupView.swift` footer: "Akai and Maschine presets use notes 36–51 starting from the bottom left. Use MIDI learn for other banks or mappings."
- When `midi.sources` is empty the screen shows only "Connect a USB controller or pair a Bluetooth MIDI controller." Touch pads exist only in portrait with a 16-pad profile (`PracticeScreen.swift` ~line 72); nothing tells the player so.
- Bluetooth is used only through Apple's pairing screen (`CABTMIDICentralViewController`, `ContentView.swift`). The usage text `INFOPLIST_KEY_NSBluetoothAlwaysUsageDescription` is set in `SmackAPad.xcodeproj/project.pbxproj` ("Connect Bluetooth MIDI controllers for finger drumming."). Czech text not verified.

## Rules

1. **One neutral preset.** Merge the Akai and Maschine presets into one profile named by its mapping, for example "16 pads, notes 36–51" (English and Czech). Find how the selected profile is stored (by name or by id) and migrate: a player who saved either old name must end up on the new profile with the same pad mapping. No player may lose a chosen profile or their MIDI-learn profiles.
2. **Footer text** under the presets says only that the preset is a note mapping starting from the bottom left pad and that MIDI learn handles other banks. No brand names, no wording that suggests tested or certified compatibility.
3. **Hint without controller.** When no MIDI source is connected, show one short line in the place where the "Connect a USB controller…" line is now, saying that the player can also use the on-screen pads in portrait orientation (16-pad profile). One line only, no new screen, no new icon. If it needs more, stop and report.
4. **Bluetooth.** Verify that the usage text exists and reads correctly in English and Czech (an `InfoPlist.strings` per language if the app is localised that way). Verify that refusing the Bluetooth permission leaves USB MIDI, touch pads and the hardware keyboard fully usable, and that the Bluetooth button shows a sensible state instead of failing silently. Fix only what actually fails and list what was wrong.
5. **Support page.** In `site/support.html` and `site/cs/support.html` the controller answer must say only that the app works with class-compliant USB and Bluetooth MIDI pad controllers, and also with on-screen pads and a hardware keyboard. No brands, no list. (Ticket 81 is still in progress; edit the files as they are and do not touch other text.)
6. **App Review notes.** Create `docs/store/review-notes.md` (English only; if ticket 83 has already created `docs/store/listing.md`, put the section there instead and say so). Content: no MIDI controller is needed for review; exact steps for touch pads (portrait, 16-pad profile, open an Intro lesson, tap the pads) and for a hardware keyboard; no login; free tier = Intro and Path stage 1, everything else unlocked by the non-consumable `cz.kju.SmackAPad.full`; Restore Purchases in Settings and in the purchase sheet; the app uses Bluetooth only to connect MIDI controllers. Check every step against the app before writing it. No brand names, no price.
7. English and Czech strings for everything new. No change to MIDI input, scoring, timing or purchase logic.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Data/LessonData.swift` (controller profiles), `SmackAPad/Sources/UI/ControllerSetupView.swift`, `SmackAPad/Sources/UI/ContentView.swift` (Bluetooth presenter), `SmackAPad/Sources/UI/PracticeScreen.swift` (touch pad condition), `SmackAPad/Sources/Persistence/Persistence.swift` (where the selected profile is stored), both `Localizable.strings`, `SmackAPad.xcodeproj/project.pbxproj` (Bluetooth key only), `site/support.html`, `site/cs/support.html`, `docs/2026-11-04-app-store-release-checklist.md`, `docs/tickets/2026-11-04-83-store-listing-copy.md`.

## Tests

- No controller profile name in the app (presets and string catalogues) contains "Maschine", "Akai" or another brand.
- A saved selection of the old "Akai MPD (36–51)" and of the old "NI Maschine (36–51)" both load as the new profile with the same note map (16 pads, notes 36–51).
- Existing MIDI-learn profiles and the 8-pad preset load unchanged.

## Acceptance criteria

- [ ] One neutral 16-pad preset replaces the two branded ones; old saved selections migrate (test).
- [ ] Footer text has no brands and no compatibility claim, English and Czech.
- [ ] With no controller connected the hint line shows; with a controller it does not.
- [ ] Bluetooth usage text verified in both languages; refusal leaves other input methods usable (report what was checked and what was fixed).
- [ ] Support pages have the general controller sentence, nothing else changed.
- [ ] `docs/store/review-notes.md` exists and every step in it was checked against the app.
- [ ] Full test suite passes before commit (AGENTS.md). No change to MIDI input, scoring or purchase logic.

## Manual iPad checks — Jakub

- [ ] Settings → controllers in English and Czech: one preset, new footer, hint line without a controller (and absent with one).
- [ ] An already saved profile still works after the update.
- [ ] Refuse the Bluetooth permission (iPadOS Settings), then use USB or touch pads.
- [ ] Portrait without a controller: Intro lesson is playable with the on-screen pads, following the review notes word by word.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **thinking medium** (small change to code and strings, one migration). Fallback: Gemini 3.8 Flash, high.
- **Reasoning**: limited scope; the care points are the profile migration and checking every review-note step against the app.

## Done rule

Stop after a successful build and a passing full test suite. Commit as AGENTS.md says; Jakub pushes and tests on the iPad. Report which Bluetooth/permission checks failed before, if any.
