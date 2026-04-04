//
//  MainTabView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MainTabView: View {
    let container: AppContainer
    let favoritesStore: FavoritesStore

    @EnvironmentObject private var preferences: AppPreferences
    @State private var selection: Tab = .movies
    @StateObject private var movieCoordinator = NavigationCoordinator<MovieRoute>()
    @StateObject private var favoritesCoordinator = NavigationCoordinator<FavoritesRoute>()
    @StateObject private var moviesViewModel: MovieSearchViewModel
    @StateObject private var favoritesViewModel: FavoritesViewModel

    init(container: AppContainer, favoritesStore: FavoritesStore) {
        self.container = container
        self.favoritesStore = favoritesStore
        _moviesViewModel = StateObject(wrappedValue: container.makeMovieSearchViewModel())
        _favoritesViewModel = StateObject(
            wrappedValue: container.makeFavoritesViewModel(
                favoritesStore: favoritesStore
            )
        )
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $movieCoordinator.path) {
                MoviesView(
                    viewModel: moviesViewModel,
                    openFavorites: {
                        selection = .favorites
                    }
                )
                .navigationDestination(for: MovieRoute.self) { route in
                    switch route {
                    case let .detail(movie):
                        MovieDetailView(
                            movie: movie,
                            networkService: container.networkService
                        )
                    }
                }
            }
            .environmentObject(movieCoordinator)
                .tag(Tab.movies)
                .tabItem {
                    Label(Localization.string("tab.movies"), systemImage: selection == .movies ? "movieclapper.fill" : "movieclapper")
                }

            NavigationStack(path: $favoritesCoordinator.path) {
                FavoritesView(
                    viewModel: favoritesViewModel
                )
                    .navigationDestination(for: FavoritesRoute.self) { route in
                        switch route {
                        case let .list(listID):
                            FavoriteListDetailView(
                                viewModel: container.makeFavoriteListDetailViewModel(
                                    listID: listID,
                                    favoritesStore: favoritesStore
                                )
                            )
                        case let .movie(movie):
                            MovieDetailView(
                                movie: movie,
                                networkService: container.networkService
                            )
                        }
                    }
            }
            .environmentObject(favoritesCoordinator)
                .tag(Tab.favorites)
                .tabItem {
                    Label(Localization.string("tab.favorites"), systemImage: selection == .favorites ? "rectangle.stack.badge.play.fill" : "rectangle.stack.badge.play")
                }

            SettingsView(viewModel: container.makeSettingsViewModel())
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
