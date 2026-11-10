# Debug test scenarios

In a Debug build, open **Settings → Developer → Test scenarios**. Tap the **TEST** marker to return to the menu. The menu can save the current profile under a custom name and apply or delete saved copies.

| Scenario | Starting progress |
| --- | --- |
| `fresh` | Empty profile with first-run guidance |
| `introDone` | Two stars on every Intro lesson |
| `stage1Done` | Intro and the first Path stage completed with two stars |
| `awaitingStar3` | Four two-star lessons whose next successful review earns star three |
| `reviewDueToday` | Four three-star lessons due for review today |
| `advanced` | Most of the Path completed, with mixed review dates and earned badges |

Select **Real**, **Free**, or **Full** access and set a day shift from −30 to +60. Apply those choices to the current progress with **Apply overrides**, or pick a built-in scenario to start it with those choices. Saved snapshots bring back their own access and day shift. Local notifications keep their real schedule.

Confirming a profile change closes the app. Open it again to finish switching before any progress or settings load. The first test change (including an override by itself) saves your real profile in `Documents/DebugSnapshots/_real/state.plist`. Test progress and settings use separate storage, so Release continues to open the real profile. Select **Restore my real profile** and reopen to return to the current real data. These snapshots live in the app's data and are removed if you delete the app and its data.

In Xcode, open **Product → Scheme → Edit Scheme → Run → Arguments** and add `-debugScenario <id>`, `-debugDayOffset <n>` or `-debugAccess free|full`. For example, use `-debugScenario reviewDueToday -debugDayOffset 3 -debugAccess full` to seed reviews for the shifted day. Xcode reapplies these arguments every time it launches the app. Disable them when you want to continue the current test profile or launch the restored real profile.

## iPad checks

- Open `fresh` and check the first-practice pulse and one-time legend. Tap the **TEST** marker in practice and check its position in portrait and landscape.
- Open `reviewDueToday` and check the Today plan, Training queue, and starting a review from Library or Home. Apply a day shift and check which reviews are due.
- Save a custom snapshot, switch to another scenario, and reapply the saved snapshot. Restore the real profile and confirm the original progress, badges and settings have returned.

## Date sources

- Reviews, Today plans, progress days and training streaks already use `AppCalendar.today()`. Badge earning in `BadgeStore.awardSilently` and `BadgeStore.evaluate` now also uses the app calendar.
- Real dates are used for `ReviewReminderScheduler.rescheduleAsync` and `SettingsManager.defaultReminderTime` (OS reminders), `ProgressStore.backupUnreadableProgress` (backup names), `PracticeSession` pad flashes, `FeedbackWindow` result timing, and the diagnostic clocks in `BluetoothTimingDiagnostics`, `AudioEngine`, `AppNavigation` and `TrainingScreen`. The practice and MIDI clocks continue to use system timing.
