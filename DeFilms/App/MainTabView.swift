//
//  MainTabView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var selection: Tab = .movies
    @StateObject private var movieCoordinator = NavigationCoordinator<MovieRoute>()
    @StateObject private var favoritesCoordinator = NavigationCoordinator<FavoritesRoute>()
    @StateObject private var moviesViewModel = MovieSearchViewModel(
        networkService: NetworkManager.shared,
        recentSearchRepository: RecentSearchRepository.shared,
        sessionManager: AuthSessionManager.shared
    )

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $movieCoordinator.path) {
                MoviesView(
                    viewModel: moviesViewModel,
                    openFavorites: { selection = .favorites }
                )
                .navigationDestination(for: MovieRoute.self) { route in
                    switch route {
                    case let .detail(movie):
                        MovieDetailView(movie: movie)
                    }
                }
            }
            .environmentObject(movieCoordinator)
                .tag(Tab.movies)
                .tabItem {
                    Label(Localization.string("tab.movies"), systemImage: selection == .movies ? "movieclapper.fill" : "movieclapper")
                }

            NavigationStack(path: $favoritesCoordinator.path) {
                FavoritesView(viewModel: FavoritesViewModel(favoritesStore: favoritesStore))
                    .navigationDestination(for: FavoritesRoute.self) { route in
                        switch route {
                        case let .list(listID):
                            FavoriteListDetailView(
                                viewModel: FavoriteListDetailViewModel(
                                    listID: listID,
                                    favoritesStore: favoritesStore
                                )
                            )
                        case let .movie(movie):
                            MovieDetailView(movie: movie)
                        }
                    }
            }
            .environmentObject(favoritesCoordinator)
                .tag(Tab.favorites)
                .tabItem {
                    Label(Localization.string("tab.favorites"), systemImage: selection == .favorites ? "rectangle.stack.badge.play.fill" : "rectangle.stack.badge.play")
                }

            SettingsView()
                .tag(Tab.settings)
                .tabItem {
                    Label(Localization.string("tab.settings"), systemImage: selection == .settings ? "gearshape.fill" : "gearshape")
                }
        }
        .id(preferences.interfaceLayoutID)
        .tint(.primary)
    }
}

private enum Tab: Hashable {
    case movies
    case favorites
    case settings
}
