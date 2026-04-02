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
    @StateObject private var favoritesStore = FavoritesStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(favoritesStore)
        }
    }
}
