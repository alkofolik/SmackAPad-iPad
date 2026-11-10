# 167 — Button spacing across the app

Status: ready-for-agent. Approved by Jakub on 2026-11-10.

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
