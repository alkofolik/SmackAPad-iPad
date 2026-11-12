# 167 — Button spacing across the app

Status: done (checked and passed by Jakub 2026-11-12). Approved by Jakub on 2026-11-10.

## Problem

On several screens buttons sit glued to each other (no visible gap), on the practice screen and elsewhere.

## Work

1. Add spacing tokens to `Theme.swift` if missing: a minimum gap between adjacent tappable controls (suggest 12 pt; 8 pt only inside a deliberate segmented control) and keep the 44 pt minimum target (48 pt where the toolbar already uses it).
2. Audit every screen: Home, Library (sidebar, filters, lesson rows), Practice (toolbar, transport, result card), Today, Training, Settings, Controller setup, Help/tutorial, purchase/paywall, intro. Look for `HStack`/`VStack` of buttons with spacing 0–6 or controls touching via padding/background.
3. Fix with the tokens. Do not redesign, change copy or colours, or move controls.
4. List every place you changed in the commit message and in a short table in the ticket log (screen, control group, before → after spacing).
5. Check portrait, landscape, narrow window, Czech (longer labels) and large text: buttons must wrap, not overlap.

## Agent assignment

Codex GPT-6.1 Sol, medium. Mechanical audit with clear rules.

## Done rule

Build, run the full test plan per `AGENTS.md`, take simulator screenshots of changed screens into `docs/design/previews/167/`, commit, stop for Jakub's iPad check.

## Log

### Spacing Changes

| Screen | Control Group | Before | After |
| :--- | :--- | :--- | :--- |
| **Practice** | Top bar: mode buttons (Learn / Practice / After me) | 0 pt | 8 pt (`Theme.Space.segmentedGap`) |
| **Practice** | Top bar: view mode buttons (Static / Scrolling) | 0 pt | 8 pt (`Theme.Space.segmentedGap`) |
| **Practice** | Top bar: help & tool icons (Info, Legend, ?, More) | 0 pt | 12 pt (`Theme.Space.controlGap`) |
| **Practice** | Top bar: tool group layout | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Practice** | Transport: stacked buttons (Start/Restart, Again/Next) | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Practice** | Transport: horizontal / vertical fallback buttons | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Practice** | Tempo popover: step buttons ([-5, -1, 1, 5]) | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Library** | Filters bar (Search, Filter menu, Chips, Clear) | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Library** | Sidebar: categories & intro rows touch target | min 30 pt | min 48 pt (`Theme.Size.touch`) |
| **Library** | Lesson row: row content to trailing controls | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Library** | Lesson row: vertical gap between cards | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Today** | Actions: primary action to secondary actions | 10 pt | 12 pt (`Theme.Space.controlGap`) |
| **Today** | Actions: Skip & Done buttons (with ViewThatFits wrap) | 10 pt | 12 pt (`Theme.Space.controlGap`) |
| **Training** | Band footer: "Not today" & "Start training" (with ViewThatFits wrap) | 10 pt | 12 pt (`Theme.Space.controlGap`) |
| **Training** | Next 7 days forecast strip | 6 pt | 8 pt (`Theme.Space.segmentedGap`) |
| **Training** | Waiting box chips (FlowLayout) | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Controller setup** | Mapping row: Learn & Clear buttons | 8 pt | 12 pt (`Theme.Space.controlGap`) |
| **Purchases** | Purchase controls: Unlock, Restore, Try again | 8 pt | 12 pt (`Theme.Space.controlGap`) |

### Screenshots Captured

Captured into `docs/design/previews/167/`:
- `01-practice.png`: Practice screen with new toolbar icon spacing and transport button gaps.
- `02-practice-result.png`: Practice screen with result card and 12 pt gap between "Again" and "Next lesson" buttons.
- `03-library.png`: Library screen with filter chips and lesson row spacing.
- `04-training.png`: Training screen with next 7 days strip, waiting box chips, and band footer buttons.
- `05-today.png`: Today session screen with Continue, Skip, and Done buttons.
- `06-controller-setup.png`: Controller setup with 12 pt gap between Learn and Clear buttons.
- `07-purchases.png`: Purchases screen with 12 pt gap between Unlock and Restore buttons.
