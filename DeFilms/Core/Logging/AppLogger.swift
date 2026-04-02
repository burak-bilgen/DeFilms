//
//  AppLogger.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

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

        var emoji: String {
            switch self {
            case .app: return "🚀"
            case .network: return "🌐"
            case .persistence: return "💾"
            case .movie: return "🎬"
            case .search: return "🔎"
            case .auth: return "🔐"
            case .localization: return "🌍"
            case .theme: return "🎨"
            case .favorites: return "❤️"
            case .navigation: return "🧭"
            }
        }
    }

    enum Level {
        case info
        case success
        case warning
        case error

        var emoji: String {
            switch self {
            case .info: return "ℹ️"
            case .success: return "✅"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }

        var osLogType: OSLogType {
            switch self {
            case .info, .success:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            }
        }
    }

    private static let subsystem = "com.defilms.app"

    static func log(_ message: String, category: Category, level: Level = .info) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        logger.log(level: level.osLogType, "\(category.emoji) \(level.emoji) \(message)")
    }
}
