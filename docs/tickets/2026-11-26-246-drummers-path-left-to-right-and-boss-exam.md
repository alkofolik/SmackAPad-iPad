# 246 — Left-to-Right Path Flow, 2–7 Node Spacing & Dedicated Boss Exam Node

Status: done

## Goal

Ensure every Drummer's Path block flows strictly left-to-right without closed loops, supports 2 to 7 nodes with guaranteed `>= 115 pt` horizontal spacing and `<= 105 pt` label widths (fixing `19–25 + BOSS`), and renders the final `BOSS EXAM` as a dedicated stage exam node rather than overwriting the last regular lesson.

## Rules

1. **Strict Left-to-Right Flow (No Closed Loops):**
   - Replace `circuitLoop` with `steppedArc` across the 6 topologies (`signalLine`, `serpentine`, `diagonalClimb`, `chevronWave`, `splitFork`, `steppedArc`).
   - Every topology must enter on the left (node 0) and exit on the right (last node) in strictly ascending lesson order.
   - Blocks with fewer than 4 nodes (e.g. `31–32 + BOSS`, `55–57 + BOSS`) must never use `Split Fork`; clamp them to `Signal Line` or `Diagonal Climb`.
2. **Dynamic 2–7 Node Support (`>= 115 pt` Spacing, `<= 105 pt` Labels):**
   - Compute node coordinates dynamically for `2...7` nodes without hardcoded 6-node caps.
   - Guarantee at least `115 pt` horizontal center-to-center spacing (using horizontal scroll overflow if the container is narrower than required) and clamp label widths to `105 pt` with `lineLimit(2)`.
3. **Dedicated Stage `BOSS EXAM` Node:**
   - Keep the last regular lesson (e.g. lesson 32 or 57) as a normal numbered node before the Boss node.
   - Append a dedicated Boss node with top badge `STAGE BOSS · +1 KEY`, trophy/key icon + `BOSS EXAM` inside the box, and a clear stage exam label underneath (e.g. `Intro Stage Exam` / `Zkouška etapy · Úvod`).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Progression/DrummerPathMapModel.swift`, `SmackAPad/Sources/UI/Practice/DrummerPathMapView.swift`, `SmackAPadTests/DrummerPathTests.swift`.

## Tests

Update `DrummerPathTests` to verify no `circuitLoop`, `< 4`-node blocks resolve only `.signalLine`/`.diagonalClimb`, `nodes` preserve the final lesson before the dedicated Boss node, and run `SmackAPadTests` on the iPad simulator.

## Acceptance criteria

- [x] `DrummerStageTopology` contains `signalLine`, `serpentine`, `diagonalClimb`, `chevronWave`, `splitFork`, `steppedArc` (no `circuitLoop`), and `< 4`-node blocks never resolve `.splitFork`.
- [x] All 6 topologies flow strictly left-to-right for 2–7 nodes with `>= 115 pt` center spacing and `<= 105 pt` 2-line labels.
- [x] Final stage lesson stays a normal node and `BOSS EXAM` renders as a dedicated stage exam node with clear exam title and trophy/key icon.
- [x] App builds and `SmackAPadTests` passes on the iPad simulator.

### Manual iPad checks for Jakub

- Open `PATH`, check Intro `19–25 + BOSS` (7 nodes without overlap), check 2–3 node final blocks (no Split Fork), and verify the final lesson + dedicated `BOSS EXAM` node label.

## Agent assignment

Gemini 4 Hydrogen, thinking **medium**.

## Done rule

Build, run tests on the iPad simulator, commit on `release-polish`, and report changed files concisely.
