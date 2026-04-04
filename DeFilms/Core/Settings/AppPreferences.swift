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
    case arabic = "ar"

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
        case .arabic:
            return "ar-SA"
        }
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .arabic:
            return .rightToLeft
        case .english, .turkish:
            return .leftToRight
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

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey)
        }
    }

    static let themeKey = "app.theme"
    static let languageKey = "app.language"
    static let onboardingKey = "app.onboarding.completed"

    static var persistedLanguage: AppLanguage {
        let languageValue = UserDefaults.standard.string(forKey: Self.languageKey)
        return AppLanguage(rawValue: languageValue ?? "") ?? .english
    }

    init() {
        let themeValue = UserDefaults.standard.string(forKey: Self.themeKey)
        let languageValue = UserDefaults.standard.string(forKey: Self.languageKey)

        selectedTheme = AppTheme(rawValue: themeValue ?? "") ?? .system
        selectedLanguage = AppLanguage(rawValue: languageValue ?? "") ?? .english
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        AppLogger.log("Preferences loaded", category: .app)
    }

    var colorScheme: ColorScheme? {
        selectedTheme.colorScheme
    }

    var locale: Locale {
        selectedLanguage.locale
    }

    var layoutDirection: LayoutDirection {
        selectedLanguage.layoutDirection
    }

    var interfaceLayoutID: String {
        "\(selectedLanguage.rawValue)-\(layoutDirection == .rightToLeft ? "rtl" : "ltr")"
    }
}
