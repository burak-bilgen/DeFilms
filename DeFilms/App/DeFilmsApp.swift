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
    @StateObject private var preferences: AppPreferences
    @StateObject private var sessionManager: AuthSessionManager
    @StateObject private var favoritesStore: FavoritesStore
    @StateObject private var toastCenter: ToastCenter
    private let persistenceController = PersistenceController.shared

    init() {
        let preferences = AppPreferences()
        let authManager = AuthSessionManager.shared
        let toastCenter = ToastCenter.shared
        _preferences = StateObject(wrappedValue: preferences)
        _sessionManager = StateObject(wrappedValue: authManager)
        _toastCenter = StateObject(wrappedValue: toastCenter)
        _favoritesStore = StateObject(
            wrappedValue: FavoritesStore(
                repository: FavoritesRepository.shared,
                sessionManager: authManager
            )
        )
        AppLogger.log("Application configured", category: .app, level: .success)
    }

    var body: some Scene {
        WindowGroup {
            AppEntryView()
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
}
