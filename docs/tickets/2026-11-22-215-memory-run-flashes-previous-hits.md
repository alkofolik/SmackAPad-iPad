# 215 — From memory: previous run flashes at the end of the pattern when a new run starts

Status: resolved. Reported by Jakub on 2026-11-22: in From memory, at the start of a new run, pads from the previous run briefly flash at the end of the pattern. It does not disturb him much but looks odd.

## What is known

Two things can show at that moment and the agent must find out which one it is (screen recording or a debug overlay at 1/4 speed):

1. **Hidden pattern notes** reappearing: `NoteVisibility.derive` (`PatternField.swift` top) returns `.shown` when `running` is false or warm-up state changes; at a run boundary `running`/warm-up state may flip for a frame.
2. **Coloured played hits** of the last pass kept on purpose for smooth looping (`FeedbackWindow.strength`, `PlayedHit.isVisible`, history kept for 3 cycles in `PracticeSession.swift` ~line 1120).

## Rules

1. Reproduce first and write down which of the two it is (or both).
2. In From memory (notes hidden or faded) no note of the previous run may appear at a run boundary; coloured hits of the previous run may stay only in the smooth fade that already exists, and must not pop in again.
3. Normal play (notes shown) must look exactly as before.
4. Do not change scoring, the tape/playhead sampling (ticket 208) or the per-hit observation rule from ticket 209.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PatternField.swift` (`NoteVisibility`, `PlayedHit`, `PatternFeedback`), `SmackAPad/Sources/UI/PracticeSession.swift` (search: `playedHits`, `judgmentsByPass`, `memoryWarmUp`, `running`), `SmackAPad/Sources/UI/PracticeScreen.swift` (where `NoteVisibility.derive` is called), `docs/tickets/2026-11-18-209-playhead-stalls-on-every-pad-hit.md`.

## Cause found in the code

`NoteVisibility.derive` does not flip at a run boundary (`running` and warm-up state remain stable throughout continuous play).

The flash was caused by two issues in `StaticPattern`:
1. **Hidden pattern notes flashing**: `fadeProgress < 1` evaluated at the start of every run (`position * 15 / bpm < 0.25s`). In `.hidden`, Canvas 2 stroked black outlines around all pattern notes across the screen for 0.25 s; in `.faded`, it filled them with white and pad labels. In addition, `tail` on expected notes grabbed previous-run judgments (`judgments[pass - 1]`) at the end of the pattern in From memory.
2. **Coloured played hits popping in**: `PlayedHit` recorded during passes where notes were visible/faded (Pass 1 & 2) was kept in `playedHits`. When transitioning to Pass 3 (notes hidden), Canvas 3 turned on and drew hits from Pass 2 at the end of the pattern via `FeedbackWindow.strength`. Because they were not already drawn behind the playhead as `PlayedHit` in Pass 2, they popped in abruptly at the run boundary instead of being part of an existing visual tail.

Fix:
- `StaticPattern` receives `fromMemory`. When `fromMemory` is true, `tail` on expected notes is suppressed.
- For `visibility == .hidden`, Canvas 2 draws no expected notes (eliminating `fadeProgress < 1` outline flash). In `case .faded`, notes remain faded outlines without flashing white fills.
- `PlayedHit` records whether notes were hidden when struck (`hidden: Bool`). In `isVisible`, cross-pass tail visibility (`pass != currentPass`) is allowed only if `hidden` was true.

## Acceptance criteria

- [x] Cause written into this ticket.
- [x] No flash of previous-run notes or hits at a run boundary in From memory (static and scrolling view).
- [x] Normal play unchanged.
- [x] Build and tests pass.

### Manual iPad checks for Jakub

Play a 4-bar lesson From memory for several runs in the scrolling view and in the static view; watch the end of the pattern at each run start.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (reproduce, then fix). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
