//
//  ReviewReminderScheduler.swift
//  SmackAPad
//
//  Schedules local review reminder notifications (Ticket 105).
//

import Foundation
import UserNotifications

/// Manages local notifications reminding the player of due spaced reviews.
public final class ReviewReminderScheduler: @unchecked Sendable {
    public static let shared = ReviewReminderScheduler()

    public static let identifierPrefix = "review-reminder-"

    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    /// Formats the notification body text according to app language and plural rules.
    public static func bodyText(count: Int, language: AppLanguage) -> String {
        switch language {
        case .czech:
            if count == 1 {
                return language.localized("1 lekce čeká na opakování")
            } else if count >= 2 && count <= 4 {
                return language.localized("%lld lekce čekají na opakování", count)
            } else {
                return language.localized("%lld lekcí čeká na opakování", count)
            }
        case .english:
            if count == 1 {
                return language.localized("1 lesson due for review")
            } else {
                return language.localized("%lld lessons due for review", count)
            }
        }
    }

    /// Asynchronously removes all pending review reminder notifications.
    public func cancelAllAsync() async {
        #if DEBUG
        guard !DebugProfileStorage.isActive else { return }
        #endif
        let requests = await center.pendingNotificationRequests()
        let idsToRemove = requests.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        if !idsToRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }

    /// Synchronously dispatches cancellation of all pending review reminder notifications.
    public func cancelAll() {
        Task {
            await cancelAllAsync()
        }
    }

    /// Synchronously dispatches a reschedule of review reminder notifications.
    public func reschedule() {
        Task {
            await rescheduleAsync()
        }
    }

    /// Asynchronously removes all pending review reminders and schedules ahead for the next 14 days
    /// whose forecast count > 0 at the user's chosen reminder time (skipping today if that time has passed).
    public func rescheduleAsync(
        now: Date = Date(),
        calendar: Calendar = .current,
        records: [Int: LessonProgress]? = nil,
        language: AppLanguage? = nil,
        enabled: Bool? = nil,
        hour: Int? = nil,
        minute: Int? = nil
    ) async {
        #if DEBUG
        // Keep the real profile's OS notifications on the real calendar during test scenarios.
        guard !DebugProfileStorage.isActive else { return }
        #endif
        let isEnabled = enabled ?? SettingsManager.shared.reviewReminderEnabled
        guard isEnabled else {
            await cancelAllAsync()
            return
        }

        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized ||
              settings.authorizationStatus == .provisional ||
              settings.authorizationStatus == .ephemeral else {
            await cancelAllAsync()
            return
        }

        await cancelAllAsync()

        let appLanguage = language ?? SettingsManager.shared.languagePreference
        let reminderHour = hour ?? SettingsManager.shared.reviewReminderHour
        let reminderMinute = minute ?? SettingsManager.shared.reviewReminderMinute
        let currentRecords = records ?? ProgressStore.shared.records
        let today = AppCalendar.dayString(from: now, timeZone: calendar.timeZone)

        // Forecast for the next 14 days starting from today
        let forecast = ReviewForecast.dueCounts(currentRecords, from: today, days: 14)

        // Check if chosen time has already passed today
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = reminderHour
        todayComponents.minute = reminderMinute
        todayComponents.second = 0
        let todayReminderDate = calendar.date(from: todayComponents) ?? now
        let todayTimePassed = todayReminderDate <= now

        for (day, count) in forecast {
            guard count > 0 else { continue }
            if day == today && todayTimePassed {
                continue
            }

            let parts = day.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 3 else { continue }

            var triggerComponents = DateComponents()
            triggerComponents.calendar = calendar
            triggerComponents.timeZone = calendar.timeZone
            triggerComponents.year = parts[0]
            triggerComponents.month = parts[1]
            triggerComponents.day = parts[2]
            triggerComponents.hour = reminderHour
            triggerComponents.minute = reminderMinute
            triggerComponents.second = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

            let content = UNMutableNotificationContent()
            content.title = "Smack-a-Pad"
            content.body = Self.bodyText(count: count, language: appLanguage)
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(Self.identifierPrefix)\(day)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }
}

/// Notification center delegate directing review notification taps to the Training screen.
@MainActor
public final class ReviewReminderDelegate: NSObject, @preconcurrency UNUserNotificationCenterDelegate {
    public static let shared = ReviewReminderDelegate()

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        if identifier.hasPrefix(ReviewReminderScheduler.identifierPrefix) {
            AppNavigation.shared.openTraining()
        }
        completionHandler()
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
