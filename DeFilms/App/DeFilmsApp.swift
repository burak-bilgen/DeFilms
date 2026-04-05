//
//  DeFilmsApp.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI
import Foundation

@main
struct DeFilmsApp: App {
    private let container: AppContainer
    @StateObject private var preferences: AppPreferences
    @StateObject private var sessionManager: AuthSessionManager
    @StateObject private var favoritesStore: FavoritesStore
    @StateObject private var toastCenter: ToastCenter
    private let persistenceController = PersistenceController.shared

    init() {
        Self.configureLaunchStateIfNeeded()
        let container = AppContainer()
        let preferences = AppPreferences()
        let authManager = container.sessionManager
        let toastCenter = container.toastCenter
        self.container = container
        _preferences = StateObject(wrappedValue: preferences)
        _sessionManager = StateObject(wrappedValue: authManager)
        _toastCenter = StateObject(wrappedValue: toastCenter)
        _favoritesStore = StateObject(wrappedValue: container.favoritesFactory.makeStore())
        AppLogger.log("Application configured", category: .app, level: .success)
    }

    var body: some Scene {
        WindowGroup {
            AppEntryView(
                container: container,
                favoritesStore: favoritesStore
            )
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environment(\.locale, preferences.locale)
                .environment(\.layoutDirection, preferences.layoutDirection)
                .preferredColorScheme(preferences.colorScheme)
                .environmentObject(preferences)
                .environmentObject(sessionManager)
                .environmentObject(favoritesStore)
                .environmentObject(toastCenter)
                .toast(item: $toastCenter.item, duration: 1.8)
        }
    }

    private static func configureLaunchStateIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        let defaults = UserDefaults.standard

        if arguments.contains("UITest.ResetState") {
            defaults.removeObject(forKey: AppPreferences.onboardingKey)
            defaults.removeObject(forKey: AppPreferences.languageKey)
            defaults.removeObject(forKey: AppPreferences.themeKey)
            try? PersistenceController.shared.resetAllData()
            AuthSessionManager.shared.resetForUITesting()
        }

        if arguments.contains("UITest.SkipOnboarding") {
            defaults.set(true, forKey: AppPreferences.onboardingKey)
        }

        if arguments.contains("UITest.Theme.Dark") {
            defaults.set(AppTheme.dark.rawValue, forKey: AppPreferences.themeKey)
        } else if arguments.contains("UITest.Theme.Light") {
            defaults.set(AppTheme.light.rawValue, forKey: AppPreferences.themeKey)
        }

        if arguments.contains("UITest.Locale.Arabic") {
            defaults.set(AppLanguage.arabic.rawValue, forKey: AppPreferences.languageKey)
        } else if arguments.contains("UITest.Locale.Turkish") {
            defaults.set(AppLanguage.turkish.rawValue, forKey: AppPreferences.languageKey)
        } else if arguments.contains("UITest.Locale.English") {
            defaults.set(AppLanguage.english.rawValue, forKey: AppPreferences.languageKey)
        }

        if arguments.contains("UITest.SeedSignedInSession") {
            AuthSessionManager.shared.seedSignedInSessionForUITesting()
        }

        seedUITestContentIfNeeded(arguments: arguments)
    }

    private static func seedUITestContentIfNeeded(arguments: [String]) {
        let sessionManager = AuthSessionManager.shared
        let favoritesRepository = FavoritesRepository.shared
        let recentSearchRepository = RecentSearchRepository.shared

        if arguments.contains("UITest.SeedFavorites") {
            let seededLists = [
                FavoriteList(
                    id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                    name: "Weekend Watchlist",
                    movies: [
                        FavoriteMovie(id: 1001, title: "Dune", posterPath: nil, releaseDate: "2021-10-22", voteAverage: 8.0),
                        FavoriteMovie(id: 1002, title: "Arrival", posterPath: nil, releaseDate: "2016-11-11", voteAverage: 7.9)
                    ]
                ),
                FavoriteList(
                    id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
                    name: "Rewatch Soon",
                    movies: [
                        FavoriteMovie(id: 1003, title: "Blade Runner 2049", posterPath: nil, releaseDate: "2017-10-06", voteAverage: 8.1)
                    ]
                )
            ]

            try? favoritesRepository.replaceListsForUITesting(
                seededLists,
                userIdentifier: sessionManager.currentUserIdentifier
            )
        }

        if arguments.contains("UITest.SeedSearchHistory") {
            try? recentSearchRepository.replaceSearchesForUITesting(
                ["Dune", "Arrival", "Blade Runner 2049"],
                userIdentifier: sessionManager.currentUserIdentifier
            )
        }
    }
}
