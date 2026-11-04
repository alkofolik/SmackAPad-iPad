# 75 — App name shows "SmackAPad" instead of "Smack-a-Pad"

Status: ready. Source: Jakub, 2026-11-04 (photo 4): the iPadOS status bar / app switcher and the home screen icon label read "SmackAPad".

## Cause

`SmackAPad-Info.plist` has no `CFBundleDisplayName`, so iPadOS falls back to the product name `SmackAPad`.

## Rule

- Add `CFBundleDisplayName` = `Smack-a-Pad` (and `INFOPLIST_KEY_CFBundleDisplayName` in the app target build settings if the target generates its Info.plist). Do not change `PRODUCT_NAME`, the bundle id, the target or the scheme.
- If an `InfoPlist.strings` exists for cs/en, set the same name there; otherwise do not create one.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad-Info.plist`, `SmackAPad.xcodeproj/project.pbxproj` (app target build settings only).

## Acceptance criteria

- [ ] Home screen icon label and the status bar read "Smack-a-Pad".
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)** (delete and reinstall if the label is cached).

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
