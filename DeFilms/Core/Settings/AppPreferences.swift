//
//  AppPreferences.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var tmdbLanguageCode: String {
        switch self {
        case .english:
            return "en-US"
        case .turkish:
            return "tr-TR"
        }
    }
}

final class AppPreferences: ObservableObject {
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Self.themeKey)
            AppLogger.log("Theme changed to \(selectedTheme.rawValue)", category: .theme, level: .success)
        }
    }

    @Published var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.languageKey)
            AppLogger.log("Language changed to \(selectedLanguage.rawValue)", category: .localization, level: .success)
        }
    }

    static let themeKey = "app.theme"
    static let languageKey = "app.language"

    static var persistedLanguage: AppLanguage {
        let languageValue = UserDefaults.standard.string(forKey: Self.languageKey)
        return AppLanguage(rawValue: languageValue ?? "") ?? .english
    }

    init() {
        let themeValue = UserDefaults.standard.string(forKey: Self.themeKey)
        let languageValue = UserDefaults.standard.string(forKey: Self.languageKey)

        selectedTheme = AppTheme(rawValue: themeValue ?? "") ?? .system
        selectedLanguage = AppLanguage(rawValue: languageValue ?? "") ?? .english
        AppLogger.log("Preferences loaded", category: .app)
    }

    var colorScheme: ColorScheme? {
        selectedTheme.colorScheme
    }

    var locale: Locale {
        selectedLanguage.locale
    }
}
