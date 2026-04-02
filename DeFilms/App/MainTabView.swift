//
//  MainTabView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @State private var selection: Tab = .movies
    @StateObject private var moviesViewModel = MovieSearchViewModel(
        networkService: NetworkManager.shared,
        recentSearchRepository: RecentSearchRepository.shared,
        sessionManager: AuthSessionManager.shared
    )

    var body: some View {
        TabView(selection: $selection) {
            MoviesView(viewModel: moviesViewModel)
                .tag(Tab.movies)
                .tabItem {
                    Label(Localization.string("tab.movies"), systemImage: "movieclapper.fill")
                }

            FavoritesView()
                .tag(Tab.favorites)
                .tabItem {
                    Label(Localization.string("tab.favorites"), systemImage: "rectangle.stack.badge.play")
                }

            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label(Localization.string("tab.settings"), systemImage: "filemenu.and.selection")
                }
        }
        .id(preferences.selectedLanguage.rawValue)
        .tint(Color.accentColor)
    }
}

private enum Tab: Hashable {
    case movies
    case favorites
    case settings
}
