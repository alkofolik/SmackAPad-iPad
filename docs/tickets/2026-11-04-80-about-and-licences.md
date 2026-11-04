# 80 — Settings: "About" section with sample credits, version, support and privacy links

Status: parked (App Store release track, not scheduled). Depends on 81 only for the final URLs (placeholders are fine until then). Source: Claude's pre-release audit, 2026-11-04.

## Why

- The Acoustic kit uses AVL Drumkits samples under **CC BY-SA 3.0**; its licence requires keeping the author's information in the release. Today the credits exist only as text files inside `samples.bundle`, nothing is visible to the user. CC0 kits need no credit, but naming them is good practice.
- App Review and users expect a visible support contact and privacy policy link.
- Settings already has an "IBM Plex Sans / SIL Open Font License 1.1" section; this ticket folds it into one tidy "About" section.

## Rule

1. Replace the standalone IBM Plex Sans section in `SettingsView` with one section **About** (cs: **O aplikaci**) at the bottom, containing rows:
   - App name and version: `Smack-a-Pad 1.0 (1)` read from the bundle (`CFBundleShortVersionString`, `CFBundleVersion`).
   - **Support** → opens `AppLinks.support` in Safari.
   - **Privacy policy** → opens `AppLinks.privacy`.
   - **Sound and font credits** → a pushed screen listing per sound kit: kit name, authors, source, licence name (taken from the existing `CREDITS*`/`LICENSE*` files or a new small `credits.json`; do not hand-type licence texts into Swift). AVL entry must show: "Glen MacArthur (AVL Drumkits), CC BY-SA 3.0, bandshed.net/avldrumkits" and the full original notice. IBM Plex Sans with the OFL text moves here (reuse `FontLicenceView`).
2. New `AppLinks.swift` with two `static let` URL constants; placeholders `https://example.com/support` and `https://example.com/privacy` plus a `// TODO ticket 81` comment.
3. Same look as other Settings rows (Theme fonts, three colours). English + Czech strings.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/SettingsView.swift`, `SmackAPad/Resources/samples.bundle/*/CREDITS*` and `LICENSE*`, `SmackAPad/Resources/samples.bundle/provenance.json` (if present), localisation catalogs.

## Acceptance criteria

- [ ] Settings → About shows version, Support, Privacy policy, Credits.
- [ ] Credits list every bundled kit; AVL attribution and notice are complete.
- [ ] Links open in Safari (no in-app web view needed).
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: EN/CS, light/dark, portrait/landscape.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests, Claude commits afterwards.
