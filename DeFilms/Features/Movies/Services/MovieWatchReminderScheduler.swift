import Foundation
import UserNotifications

enum MovieWatchReminderResult: Equatable {
    case scheduled(Date)
    case denied
    case failed
}

enum MovieWatchReminderScheduler {
    static func scheduleTonightReminder(for movie: Movie) async -> MovieWatchReminderResult {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return .denied }

            let fireDate = nextTonightDate()
            let content = UNMutableNotificationContent()
            content.title = Localization.string("movies.reminder.notification.title")
            content.body = Localization.string("movies.reminder.notification.body", movie.title)
            content.sound = .default

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "movie-reminder-\(movie.id)",
                content: content,
                trigger: trigger
            )

            try await center.add(request)
            return .scheduled(fireDate)
        } catch {
            AppLogger.log("Failed to schedule movie reminder", category: .app, level: .error)
            return .failed
        }
    }

    private static func nextTonightDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let todayAtEight = calendar.date(
            bySettingHour: 20,
            minute: 0,
            second: 0,
            of: now
        ) ?? now.addingTimeInterval(60 * 60)

        if todayAtEight > now {
            return todayAtEight
        }

        return calendar.date(byAdding: .day, value: 1, to: todayAtEight) ?? now.addingTimeInterval(60 * 60)
    }
}
