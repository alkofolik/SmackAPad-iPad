# 81 — Public support and privacy policy pages (EN + CS)

Status: parked (App Store release track, not scheduled). Source: Claude's pre-release audit, 2026-11-04.

## Why

App Store Connect requires a **Privacy Policy URL** and a **Support URL** for every app. They must be public web pages.

## Decision needed from Jakub first

Where to host. Recommended: a separate small **public** GitHub repository (e.g. `smack-a-pad-site`) with GitHub Pages; the app repo stays private. Alternative: any existing personal web hosting. The agent only prepares files.

## Rule

1. Create folder `site/` (to be copied to the hosting repo) with plain static HTML + one CSS file, three colours of the app (orange, black, white), IBM Plex Sans from the bundled font or system fallback, no JavaScript, no trackers, no external fonts.
2. Pages, each in English with a Czech version (`/cs/`):
   - `index.html` — app name, one-sentence description, App Store link placeholder.
   - `support.html` — contact e-mail placeholder `SUPPORT_EMAIL`, short FAQ: which controllers work (USB/Bluetooth MIDI, on-screen touch pads, hardware keyboard), how to restore purchases, how to back up progress, what Full unlock includes.
   - `privacy.html` — facts only (verify each against the code and report any mismatch):
     - no account, no analytics, no ads, no tracking, no data leaves the device;
     - practice progress and settings are stored locally on the iPad;
     - purchases are processed by Apple; the developer receives no payment or personal data;
     - Bluetooth is used only to connect MIDI controllers;
     - contact e-mail placeholder, effective date placeholder.
   - Controller of the data: name placeholder `DEVELOPER_NAME` (Jakub fills in; must match the App Store seller / DSA trader details).
3. `site/README.md`: how to publish on GitHub Pages in plain steps.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Store/StoreManager.swift`, `SmackAPad/Sources/Persistence/Persistence.swift` (storage only), `SmackAPad-Info.plist`, `docs/2026-11-02-iap-testing.md`.

## Acceptance criteria

- [ ] Pages open locally in Safari, readable on a phone width.
- [ ] Privacy text matches the code (report checked points).
- [ ] No placeholders other than those listed above.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, low. (Or Claude in the Smack-a-iPad chat for the texts.)

## Done rule

Do not commit. Jakub reviews texts, fills placeholders and publishes; then the URLs go into `AppLinks.swift` (ticket 80) and App Store Connect.
