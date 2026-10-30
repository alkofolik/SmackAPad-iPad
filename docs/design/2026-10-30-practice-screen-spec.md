# Practice screen — specification (Jakub's decisions, 2026-10-30)

Status: approved by Jakub in conversation; this is the source of truth for the play screen. Ticket 11, DESIGN-BRIEF and SPEC §3.8 follow from it. Where older wording disagrees, this file wins.

## 1. Principle

The practice screen is where almost all time is spent. Everything else (Home, Library, results) adapts to it. One screen, no steps, no stops or countdowns between passes.

## 2. Anatomy (landscape iPad, 1180 x 820 pt reference)

- **Top bar:** back; lesson title + small subtitle (category, level); **Listen / Play** switch; **view switch** (static / scrolling, two icons); **From memory** toggle (eye icon); **Legend** button; **More tools** (settings, loop, pad-layout grid).
- **Status line (small):** BPM (tap to change, see §9), score, pass counter ("průchod 24"), hand legend (left = black, right = white).
- **Pattern field:** orange, dominant, takes all remaining height.
- **Controls, bottom right:** one large **START**. After start it becomes **STOP** (about 60 % of the footprint) and **RESTART** (the rest). Footprint about 380 x 72 pt, right-aligned. No pause. Minimum touch target 56 pt high.
- Summary strip after the run: see §7. The empty bottom-left area is reserved for it.

## 3. Modes

1. **Listen / Play** (switch above the main button)
   - **Listen:** plays the pattern with the lesson sound; the position moves; nothing is scored. The player may play along freely (their hits sound, are not judged).
   - **Play:** the lesson itself. Only the metronome and the player's own hits are heard. Scored. Lesson sound can be enabled in Settings (off by default).
2. **From memory** (toggle, chosen before START)
   - Before START the pattern is always visible; the player can read it, practise and optionally Listen. Listening is never required.
   - After START the countdown begins and the pattern disappears at that moment: the grid skeleton, counts and moving position stay, hit marks are hidden.
   - The toggle is locked during the run. After STOP or the end of the lesson the pattern is shown again.
   - The pattern is hidden **only** in From memory. In normal Play it stays visible throughout.

## 4. Run flow

START -> countdown (only here) -> pattern runs continuously. After a clean pass below `targetBpm` the tempo rises by the BPM step (1/2/5/10, Settings) and play continues without stopping or a countdown. STOP ends the run; RESTART starts again from the beginning (new countdown).

## 5. Pattern look

- Orange field `#FF6B00`; black and white only on it. Page: white with black text (light) or black with white text (dark).
- **One row per used pad** (only pads the lesson uses, never all 16). Row labels are **not** shown; the pad is identified by the **abbreviation inside the hit block** (HH, OH, SN, KD, CP, TM ...). Names and hand are in the **Legend** (button in the top bar): chip with abbreviation + name + left/right.
- **Hit = solid block** with the abbreviation. Hand by colour: **white = right, black = left**. The currently playing hit has a contrasting outline. A thin horizontal line runs through each row; empty steps are just that line.
- One column per sixteenth, count labels `1 e & a 2 e & a ...`; beat numbers larger. In dense layouts the `e & a` labels are hidden and only beat numbers stay.
- Position marker: black line with a white edge, over the whole row group.
- The current bar has a heavy left bracket. Other bars are not dimmed.

## 6. Two views, switchable

- Switched with the two icons at the top right. Scrolling always moves continuously.
- **Static:** setting for how many bars are visible: **1**, **2**, or **all** (up to 4), opened from the static icon (small menu), remembered.
  - 1 or 2 bars: the visible bars follow the playing position and change as the lesson goes on, no pause, no countdown; 2 bars page in pairs (1–2, then 3–4).
  - All: everything stays visible, only the position moves; 3–4 bars as a 2 x 2 grid.
- **Scrolling:** one continuous strip, fixed hit marker about one third from the left, the next repeat labelled "další průchod", thin overview strip of the whole lesson at the bottom with the current position.
- Scales: more pads = lower rows; more bars = grid in static, longer strip in scrolling. Lesson data today has 1–3 bars; 4 bars are for longer exercises later.

## 7. Feedback

- **No per-hit feedback** (no shapes, flashes, error marks).
- **Per bar:** one quiet word in the bar header after the bar ends: *čistý*, *předbíháš* (ahead), *zaostáváš* (behind), *nestejnoměrné* (uneven). Errors are not counted or shown. Same when the pattern is hidden. Data comes from the scoring bar summary (separate ticket).
- **End of run:** small summary strip with the score, the three stars and a "Detail" link. No separate results screen.

## 8. Stars (from the legacy app, verified in its source)

1. **Passed:** score at least 70 % (intro lessons 80 %), at any tempo.
2. **Goal tempo:** clean run at or above `targetBpm` (error limit by pattern length, SPEC §5.3).
3. **From memory:** at least 80 % at goal tempo with the pattern hidden.

Stars 2 and 3 need the goal tempo, so lowering the tempo can only earn star 1. Progress data must therefore store a memory flag next to `passed` and `mastery` (SPEC §4.3 currently lacks it).

## 9. Tempo

- Manual change only while stopped. Legacy used coarse -5 / +5 and fine -1 / +1 buttons; the purpose is to jump quickly (60 -> 90) or go back to the start to retrain.
- The current tempo is saved per lesson (`currentBpm`). The lesson's target is shown next to it (e.g. 80 -> 100 BPM).
- UI for this is not drawn yet.

## 10. Sizes and colours

- Three colours only (orange, black, white); light and dark variants. No status colours, no gradients, no shadows.
- Touch targets at least 44 pt, main controls at least 56 pt. Text at least 18 pt where possible; in dense layouts (4 bars, 6 pads) abbreviations drop to 12–14 pt, which is a known exception.
- Fonts in the mock-ups (Archivo, DM Mono) are placeholders; final type choice is open (must be embeddable by licence).

## 11. Open items

- Rule and thresholds for the four per-bar words (ticket "Bar Summary for the Scoring Engine").
- Content of "Detail".
- Czech / English wording (ticket 15).
- Tempo control UI and the Legend interaction (open/close) to be drawn.
- Final typography and whether dense layouts stay readable on the real iPad.
