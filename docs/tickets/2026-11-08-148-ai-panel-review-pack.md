# 148 — Review pack for the AI panel

Status: ready-for-agent. Blocked by: none. Source: Jakub, 2026-11-08 (AI panel, `docs/reviews/ai-panel/README.md`).

## Goal

Three outside AIs (ChatGPT, Claude, Gemini) will review the app in their chat apps. They cannot run it; they only see what we give them. Write the shared written materials so every reviewer starts from the same accurate picture. No code changes.

## Deliverables

1. `docs/reviews/ai-panel/pack/00-brief.md` — English, 2–3 pages, written for an outsider who has never seen the project. Sections:
   - **What it is** — one paragraph: native SwiftUI iPad finger-drumming trainer, played on an external MIDI pad controller (USB or Bluetooth), touch pads only a bonus, navigation by touch.
   - **Who it is for** — beginner to intermediate finger drummers.
   - **Screens and main flow** — Home, Library (Path, Genres, Techniques), Intro exercises, Practice (Listen / Play / From memory), Training (reviews), Today session, badges, Settings, controller mapping, calibration, purchase. One or two lines each; how a player moves between them.
   - **Learning system** — stars 1–3 and what earns each (star 3 = two passed reviews in Training), tempo progression, Training due list, badges.
   - **Content** — number of lessons, categories, what is free versus Full.
   - **Business model** — free download, one-time non-consumable Full unlock, possible paid packs later; no account, no tracking, no ads.
   - **Current state** — what works, what is not done before 1.0 (from the release checklist section C/E).
   - **Decided** — a bullet list of deliberate decisions reviewers should not re-argue (from `docs/DECISIONS.md` and ADRs; short, one line each).
   - **Planned after 1.0** — one line per item from `docs/2026-11-05-post-v1-plan.md`, so reviewers do not suggest them as new.
   - **How it was built** — the developer cannot program; all code by AI agents from tickets.
   Do not mention which reviewer gets which role. Do not say who the developer is.
2. `docs/reviews/ai-panel/pack/shot-list.md` — Czech, for Jakub: a numbered list of screenshots to take on the iPad (English UI, light mode, landscape unless stated), one per screen and important state (e.g. empty Training, lesson with locks, run result with timing detail, purchase sheet, controller learn). File name for each, e.g. `03-practice-play-running.png`. Plus 3 screen recordings, each under 2 minutes, with what to show: (a) first launch to first finished lesson, (b) a Play run with a tempo rise and the result, (c) Training review and From memory. Remind Jakub to turn on sound in the recording (Control Centre → long press record → microphone off, app sound is recorded).

## Files to read

`AGENTS.md`, this ticket, `docs/reviews/ai-panel/README.md`, `docs/SPEC.md`, `docs/CONTEXT.md`, `docs/DECISIONS.md`, `docs/adr/` (titles and decisions only), `docs/DESIGN-BRIEF.md`, `docs/2026-11-04-app-store-release-checklist.md`, `docs/2026-11-05-post-v1-plan.md`, `docs/tickets/2026-11-07-143-star-3-through-two-reviews.md`, `docs/tickets/2026-11-07-144-training-list-order-and-waiting.md`, `SmackAPad/Resources/Data/` (to count lessons and free ones: `intro.json`, `lessons-core.json`, `electronic-path.json`, `genre-extensions.json`, count lessons and their `access` values; `badges.json` for badge count). If the docs disagree with each other, newer tickets win; list any contradiction at the end of `00-brief.md` under "Notes for the developer" so Jakub can fix it before sending.

## Acceptance criteria

- [ ] Both files exist; brief is English, shot list Czech.
- [ ] Every fact in the brief comes from the listed files; nothing invented.
- [ ] No code, test or project file changed.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: careful reading and summarising of many docs, no code.

## Done rule

Stop when both files are written. Commit (AGENTS.md); Jakub pushes.
