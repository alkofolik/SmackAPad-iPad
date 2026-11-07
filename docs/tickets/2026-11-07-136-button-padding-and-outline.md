# 136 — Buttons: room around the text, no second outline underneath, no wrapped labels

Status: ready-for-agent. Type: implementation. Depends on: 133 (same files; do right after 133, or in the same session). Source: Jakub, 2026-11-07, 13 screenshots: "All buttons are ugly, text is tight, and there is some outline under them."

## What is wrong (seen on the iPad)

1. **Text touches the edges.** "Hotovo", "Nastavení", "Naučit", "Zrušit přiřazení", "Obnovit nákupy", "Připojit Bluetooth MIDI", "Znovu připojit MIDI", "Další lekce": the label sits on the border, no inner padding.
2. **A second outline / shadow shape sits below the button**, offset from it (visible under "Hotovo", "Domů", "Naučit"). Looks like the bevel/shadow layer has a different frame than the face.
3. **"Domů" wraps to "Do / mů"** in Library, Intro and Training toolbars (button too narrow).
4. "Naučit" and "Zrušit přiřazení" overlap each other (Controller screen).

## Rules

1. Every text button: horizontal padding **16 pt** (compact 12 pt), vertical so the face is ≥ 44 pt. Label `lineLimit(1)`, never wraps, never truncates; the button grows to fit.
2. One shape: face, border, shadow and press flash share **one frame and one corner radius** (6 pt from 133). No extra stroke or shadow drawn outside or below the face. Check `PadControlBody`, `SkinBevel`, and toolbar wrappers (`.toolbar` items may add the system glass capsule — remove that background so only our pad shows).
3. Buttons in one row keep ≥ 8 pt gap and never overlap.
4. This ticket **may change button sizes** (133's "no layout change" rule does not apply here), but not screen layout otherwise.

## Places to check (all screenshots)

Today session ("Domů", "Pokračovat", "Přeskočit", "Konec na dnes"), Library toolbar ("Do mů", "Nastavení"), Intro screen toolbar, Training ("Do mů"), About / Controller / Badges / Settings ("Hotovo"), Controller ("Připojit Bluetooth MIDI", "Znovu připojit MIDI", "Naučit", "Zrušit přiřazení"), Settings › Nákupy ("Obnovit nákupy"), Practice result ("Znovu", "Další lekce"). Practice back button is ticket 139.

## Acceptance criteria

- [ ] No label touches its border; no label wraps or shows "…", Czech and English.
- [ ] No second outline/shadow under any button.
- [ ] "Domů" on one line on all screens, both orientations.
- [ ] Touch size ≥ 44 pt kept (ticket 130).
- [ ] Build succeeds. No new tests.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Flash, high.
- **Reasoning**: shared components + toolbar background quirks across many screens.

## Done rule

Stop after successful build. Commit (AGENTS.md); Jakub tests on the iPad.
