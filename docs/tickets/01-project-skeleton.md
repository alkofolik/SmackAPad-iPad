# 01 — Project Skeleton

Status: ready-for-agent

## Goal

Create the Xcode project, folder structure, and minimal app entry point for a native SwiftUI iPad app.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§1 Goals, §3 Architecture overview, §12 iPadOS 17 minimum)
- `docs/DECISIONS.md` (§12 iPadOS 17)

## Tasks

1. The Xcode project `SmackAPad` already exists (Jakub created it in Xcode). Do NOT create a new project and never edit `project.pbxproj` by hand. Only verify that the deployment target is iPadOS 17 and the project is iPad-only; if not, tell Jakub which setting to change in Xcode.
2. Inside the app target's folder created by Xcode (`SmackAPad/`, a synchronized folder: files created on disk appear in Xcode automatically), set up the folder structure matching the architecture modules (paths relative to that folder):
   - `Sources/App/` — app entry point
   - `Sources/MIDI/` — MIDI input (placeholder)
   - `Sources/Audio/` — audio engine (placeholder)
   - `Sources/Data/` — lesson data, models
   - `Sources/Scoring/` — scoring engine (placeholder)
   - `Sources/Calibration/` — calibration (placeholder)
   - `Sources/Persistence/` — settings, progress
   - `Sources/Progression/` — category unlock logic
   - `Sources/UI/` — screens (library, play, settings, calibration, intro)
   - `Resources/` — bundled assets (samples, JSON data, localisation)
3. Keep the Xcode-generated `SmackAPadApp.swift`; make `ContentView` a minimal placeholder.
4. Ensure the project builds and runs in the simulator (blank screen is fine).

## Acceptance criteria

- [ ] Xcode project opens, builds, and runs on iPad simulator (iPadOS 17+).
- [ ] Folder structure matches the module layout above.
- [ ] Deployment target is iPadOS 17, iPad-only.
- [ ] `.gitignore` covers Xcode build artifacts, DerivedData, `.DS_Store`.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: Straightforward project setup, no complex logic.

## Done rule

Stop after successful build; Jakub tests on iPad.
