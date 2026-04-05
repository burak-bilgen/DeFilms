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

        guard arguments.contains("UITest.ResetState") else { return }

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: AppPreferences.onboardingKey)
        defaults.removeObject(forKey: AppPreferences.languageKey)
        defaults.removeObject(forKey: AppPreferences.themeKey)
    }
}
