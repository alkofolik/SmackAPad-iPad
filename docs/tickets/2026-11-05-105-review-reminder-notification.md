# 105 — Review reminder notification (opt-in)

Status: ready-for-agent. Depends on: 98. Source: Jakub, 2026-11-05 ("notification: yes"), `docs/2026-11-05-training-push-proposal.md` §3.3.

## Goal

A once-a-day local notification tells the player that lessons are due for review. Off by default; the player turns it on.

## Rules

1. **Setting** in the Training/practice part of Settings: toggle "Review reminder" / "Připomínka opakování", default **off**, and a time picker "Time" / "Čas", default 18:00, shown only when the toggle is on.
2. Turning it on asks for notification permission (`UNUserNotificationCenter`, alert + sound, no app icon badge). Denied → the toggle goes back off and a line below says "Notifications are turned off in iPad Settings." / "Upozornění jsou vypnutá v Nastavení iPadu."
3. **Forecast** (pure function, reused by ticket 107): `ReviewForecast.dueCounts(records, from: today, days: n) -> [(day, count)]`. A day's count = lessons whose due day ≤ that day and that are not settled; overdue reviews count on today and on each later day until played (they keep waiting, as ticket 98 says).
4. **Scheduling**: local notifications cannot see the future progress, so the app schedules ahead. On app launch, on going to background, and after every recorded run: remove all pending review reminders, then schedule one notification for each of the next 14 days whose forecast count > 0, at the chosen time (skip today if that time has passed). Identifier per day (`review-reminder-YYYY-MM-DD`).
5. **Text**: title "Smack-a-Pad", body "%lld lessons due for review" / "%lld lekcí čeká na opakování" (Czech plural forms: 1 lekce čeká, 2–4 lekce čekají, 5+ lekcí čeká). Language = app language setting.
6. Tapping the notification opens the app on the **Training** screen.
7. Turning the toggle off removes all pending review reminders.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/SettingsView.swift`, `SmackAPad/Sources/App/SmackAPadApp.swift` (launch, scene phase), `SmackAPad/Sources/UI/ContentView.swift` (opening Training), `SmackAPad/Sources/Persistence/Persistence.swift` (review fields, where runs are recorded), `SmackAPad/Sources/Progression/ReviewScheduler.swift`, both `Localizable.strings`.

## Tasks

1. `ReviewForecast` pure function.
2. Notification scheduler (permission, schedule ahead, remove), setting UI, open-on-tap.
3. Texts in `en` and `cs`.
4. Unit tests (only these): forecast counts a lesson due in 3 days only from day 3; an overdue lesson counts on today and later days; settled lessons never count.

## Acceptance criteria

- [x] Toggle off by default; turning on asks for permission; denied shows the sentence.
- [x] With a review due tomorrow, a notification arrives tomorrow at the chosen time; none on days with nothing due.
- [x] Tapping it opens Training.
- [x] Toggle off removes pending reminders.
- [x] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: set the time two minutes ahead on a day with a due review, lock the iPad, wait for the notification, tap it.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: system permission and scheduling ahead must be right; the forecast is shared with ticket 107.

## Done rule

Stop after successful build and tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
