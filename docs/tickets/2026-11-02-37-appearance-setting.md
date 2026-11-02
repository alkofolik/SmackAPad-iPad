# 37 — Light / dark mode in the main Settings

Status: ready. Source: Jakub's test 2026-11-02 (feedback round 5).

## Problem

Light and dark mode can be set only on the practice screen. Settings does not offer it, so it is not clear how to set it.

## Goal

One app-wide setting **Appearance** (Light / Dark / System) in Settings. The control on the practice screen and the one in Settings are the same setting, kept in sync.

## Rules

- Keep the stored value of the existing setting; migrate it if its format has to change, so nobody loses their choice.
- Applies to the whole app, not only practice.
- Texts in `en` and `cs`.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/SettingsView.swift`, `UI/Theme.swift`, `UI/PracticeScreen.swift`, `Persistence/Persistence.swift`, localisation catalogs.

## Acceptance criteria

- [x] Settings has Appearance; changing it changes every screen at once.
- [x] The practice-screen toggle and Settings always show the same value.
- [x] Value survives restart.
- [x] Both languages; build and tests pass.
- [ ] **iPad test (Jakub)**: switch in Settings, open practice and library; switch on practice, return to Settings.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), **medium**. Small, well-defined change.

## Done rule

Stop after successful build; Jakub tests on iPad. Claude commits afterwards.
