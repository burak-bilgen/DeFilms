
import OSLog

enum AppLogger {
    enum Category: String {
        case app = "app"
        case network = "network"
        case persistence = "persistence"
        case movie = "movie"
        case search = "search"
        case auth = "auth"
        case localization = "localization"
        case theme = "theme"
        case favorites = "favorites"
        case navigation = "navigation"
    }

    enum Level {
        case info
        case success
        case warning
        case error

        var osLogType: OSLogType {
            switch self {
            case .info:
                return .info
            case .success:
                return .default
            case .warning:
                return .default
            case .error:
                return .error
            }
        }

        var shouldLogInCurrentConfiguration: Bool {
            switch self {
            case .warning, .error:
                return true
            case .info, .success:
                #if DEBUG
                return true
                #else
                return false
                #endif
            }
        }
    }

    private static let subsystem = "com.defilms.app"
    private static let loggerCache = LoggerCache()

    static func log(_ message: String, category: Category, level: Level = .info) {
        guard level.shouldLogInCurrentConfiguration else { return }
        let logger = loggerCache.logger(for: category, subsystem: subsystem)
        logger.log(level: level.osLogType, "\(message, privacy: .private(mask: .hash))")
    }
}

private final class LoggerCache: @unchecked Sendable {
    private var loggers: [AppLogger.Category: Logger] = [:]
    private let lock = NSLock()

    func logger(for category: AppLogger.Category, subsystem: String) -> Logger {
        lock.lock()
        defer { lock.unlock() }

        if let logger = loggers[category] {
            return logger
        }

        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = logger
        return logger
    }
}
