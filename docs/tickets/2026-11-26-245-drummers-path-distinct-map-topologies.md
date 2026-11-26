# 245 — Distinct Signal-Path Topologies Across Drummer's Path Stages & Blocks

Status: done

## Goal

Ensure every stage and every block/page on the **Drummer's Path** (`PATH`) screen displays a visually distinct, deterministic signal-path topology across a rich 6-shape hardware palette while guaranteeing smooth Bézier patch-cable routing and zero label overlap.

## Rules

1. **Six Distinct Hardware Map Topologies (`DrummerStageTopology`):**
   - `signalLine`: sleek horizontal or gently undulating signal bus with smooth Bézier arcs.
   - `serpentine`: dual-row snake (top row left-to-right, smooth outer U-turn curve, bottom row right-to-left).
   - `diagonalClimb`: rising staircase / diagonal crescendo from lower-left up to upper-right Boss.
   - `splitFork`: splits after node 2 into parallel upper/lower branches (nodes 3 & 4 stacked) before merging into the pre-Boss / Boss output.
   - `chevronWave`: alternating high/low V/W wave connected by curved patch cables.
   - `circuitLoop`: perimeter U/loop circuit with a tapped center-bridge node inside the loop.
2. **Unique Deterministic Selection Per `(stageId, pageIndex)`:**
   - Compute topology deterministically from `(stageId, pageIndex)` using a stable hash (not `Hashable`) and enforce that neither consecutive blocks within a stage nor consecutive stages ever share the same topology.
   - Multi-block stages' final block containing `BOSS EXAM` prefers `diagonalClimb` or `splitFork` so stage climaxes look distinct from opening blocks.
3. **Smooth Patch Cables & Collision-Free Labels:**
   - Render all patch cables using smooth `Path.addCurve` cubic Bézier paths with rounded 8 pt junction tangents and bounded turnarounds so cables never cross label text below nodes.
   - Anchor node titles strictly below node boxes with fixed computed column widths and `lineLimit(2)` so multi-line labels never collide in `splitFork`, `chevronWave`, or `circuitLoop`.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Progression/DrummerPathMapModel.swift`, `SmackAPad/Sources/UI/Practice/DrummerPathMapView.swift`, `SmackAPadTests/DrummerPathTests.swift`.

## Tests

Update topology tests in `DrummerPathTests` for the 6 topologies, deterministic `(stageId, pageIndex)` resolution, non-repeating adjacent blocks/stages, and Boss-block preference, then run `SmackAPadTests` on the iPad simulator.

## Acceptance criteria

- [x] `DrummerStageTopology` exposes all 6 cases (`signalLine`, `serpentine`, `diagonalClimb`, `splitFork`, `chevronWave`, `circuitLoop`) with English and Czech titles and symbols.
- [x] Pure topology resolver produces deterministic layouts from `(stageId, pageIndex)`, prevents consecutive blocks and adjacent stages from repeating, and prefers `diagonalClimb` / `splitFork` for multi-block final Boss pages.
- [x] All 6 topologies render cleanly for 4–7 nodes with curved Bézier patch cables and non-overlapping 2-line labels.
- [x] App builds and `SmackAPadTests` passes on the iPad simulator.

### Manual iPad checks for Jakub

- Open `PATH`, switch between stages (Intro 25 lessons + Rock/Funk/Jazz/Electronics) and Intro blocks `1–6` … `19–25 + BOSS`, and confirm each block/stage renders a distinct shape with smooth cables and zero overlapping labels.

## Agent assignment

Gemini 4 Hydrogen, thinking **medium**.

## Done rule

Build, run tests on the iPad simulator, commit on `release-polish`, and report changed files concisely.
