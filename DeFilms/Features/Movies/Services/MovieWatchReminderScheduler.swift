import Foundation
import UserNotifications

enum MovieWatchReminderResult: Equatable {
    case scheduled(Date)
    case denied
    case failed
}

enum MovieWatchReminderOption: CaseIterable, Identifiable {
    case tonight
    case tomorrow
    case weekend

    var id: String {
        switch self {
        case .tonight:
            return "tonight"
        case .tomorrow:
            return "tomorrow"
        case .weekend:
            return "weekend"
        }
    }

    var title: String {
        switch self {
        case .tonight:
            return Localization.string("movies.reminder.option.tonight")
        case .tomorrow:
            return Localization.string("movies.reminder.option.tomorrow")
        case .weekend:
            return Localization.string("movies.reminder.option.weekend")
        }
    }

    var systemImage: String {
        switch self {
        case .tonight:
            return "moon.stars"
        case .tomorrow:
            return "sunset"
        case .weekend:
            return "calendar"
        }
    }
}

enum MovieWatchReminderScheduler {
    static func scheduleTonightReminder(for movie: Movie) async -> MovieWatchReminderResult {
        await scheduleReminder(for: movie, option: .tonight)
    }

    static func scheduleReminder(for movie: Movie, option: MovieWatchReminderOption) async -> MovieWatchReminderResult {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return .denied }

            let fireDate = nextDate(for: option)
            let content = UNMutableNotificationContent()
            content.title = Localization.string("movies.reminder.notification.title")
            content.body = Localization.string("movies.reminder.notification.body", movie.title)
            content.sound = .default
            content.userInfo = [
                "movieID": movie.id,
                "movieTitle": movie.title,
                "reminderOption": option.id
            ]

            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "movie-reminder-\(movie.id)-\(option.id)",
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

    private static func nextDate(for option: MovieWatchReminderOption) -> Date {
        switch option {
        case .tonight:
            return nextDate(hour: 20, minute: 0, dayOffset: 0)
        case .tomorrow:
            return nextDate(hour: 20, minute: 0, dayOffset: 1)
        case .weekend:
            return nextWeekendDate()
        }
    }

    private static func nextDate(hour: Int, minute: Int, dayOffset: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
        let targetDate = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: baseDate
        ) ?? now.addingTimeInterval(60 * 60)

        if targetDate > now {
            return targetDate
        }

        return calendar.date(byAdding: .day, value: 1, to: targetDate) ?? now.addingTimeInterval(60 * 60)
    }

    private static func nextWeekendDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let saturday = 7
        let daysUntilSaturday = (saturday - weekday + 7) % 7
        let offset = daysUntilSaturday == 0 && calendar.component(.hour, from: now) >= 20 ? 7 : daysUntilSaturday
        return nextDate(hour: 20, minute: 0, dayOffset: offset)
    }
}
