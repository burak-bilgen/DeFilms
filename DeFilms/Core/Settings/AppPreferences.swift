
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

@MainActor
final class AppPreferences: ObservableObject {
    private let defaults: UserDefaults
    private var languageChangeTask: Task<Void, Never>?
    private let minimumLanguageTransitionDuration = Duration.milliseconds(250)

    @Published var selectedTheme: AppTheme {
        didSet {
            defaults.set(selectedTheme.rawValue, forKey: Self.themeKey)
            AppLogger.log("Theme changed to \(selectedTheme.rawValue)", category: .theme, level: .success)
        }
    }

    @Published var selectedLanguage: AppLanguage {
        didSet {
            defaults.set(selectedLanguage.rawValue, forKey: Self.languageKey)
            AppLogger.log("Language changed to \(selectedLanguage.rawValue)", category: .localization, level: .success)
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            defaults.set(hasCompletedOnboarding, forKey: Self.onboardingKey)
        }
    }

    @Published private(set) var isApplyingLanguageChange = false
    @Published private(set) var interfaceLayoutRefreshToken = UUID()

    nonisolated static let themeKey = "app.theme"
    nonisolated static let languageKey = "app.language"
    nonisolated static let onboardingKey = "app.onboarding.completed"

    nonisolated static var persistedLanguage: AppLanguage {
        let languageValue = UserDefaults.standard.string(forKey: Self.languageKey)
        return AppLanguage(rawValue: languageValue ?? "") ?? .english
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let themeValue = defaults.string(forKey: Self.themeKey)
        let languageValue = defaults.string(forKey: Self.languageKey)

        selectedTheme = AppTheme(rawValue: themeValue ?? "") ?? .system
        selectedLanguage = AppLanguage(rawValue: languageValue ?? "") ?? .english
        hasCompletedOnboarding = defaults.bool(forKey: Self.onboardingKey)
        AppLayoutDirectionController.apply(selectedLanguage.layoutDirection)
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

    func applyLanguage(_ language: AppLanguage) async {
        guard selectedLanguage != language else { return }
        guard !isApplyingLanguageChange else { return }

        languageChangeTask?.cancel()
        let transitionStart = ContinuousClock.now

        isApplyingLanguageChange = true
        selectedLanguage = language
        AppLayoutDirectionController.apply(language.layoutDirection)
        interfaceLayoutRefreshToken = UUID()

        let task = Task { @MainActor [weak self] in
            await Task.yield()
            let elapsed = transitionStart.duration(to: .now)
            if elapsed < self?.minimumLanguageTransitionDuration ?? .zero {
                try? await Task.sleep(for: (self?.minimumLanguageTransitionDuration ?? .zero) - elapsed)
            }
            guard !Task.isCancelled else { return }
            self?.isApplyingLanguageChange = false
            self?.languageChangeTask = nil
        }

        languageChangeTask = task
        await task.value
    }
}
