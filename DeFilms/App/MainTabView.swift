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
        _moviesViewModel = StateObject(wrappedValue: container.moviesFactory.makeSearchViewModel())
        _favoritesViewModel = StateObject(
            wrappedValue: container.favoritesFactory.makeFavoritesViewModel(
                favoritesStore: favoritesStore
            )
        )
    }

    var body: some View {
        TabView(selection: $selection) {
            moviesTab
                .tag(Tab.movies)
                .tabItem {
                    Label(Localization.string("tab.movies"), systemImage: selection == .movies ? "movieclapper.fill" : "movieclapper")
                }

            favoritesTab
                .tag(Tab.favorites)
                .tabItem {
                    Label(Localization.string("tab.favorites"), systemImage: selection == .favorites ? "rectangle.stack.badge.play.fill" : "rectangle.stack.badge.play")
                }

            settingsTab
                .tag(Tab.settings)
                .tabItem {
                    Label(Localization.string("tab.settings"), systemImage: selection == .settings ? "gearshape.fill" : "gearshape")
                }
        }
        .id(preferences.interfaceLayoutID)
        .tint(.primary)
    }

    private var moviesTab: some View {
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
                    MovieDetailView(viewModel: container.moviesFactory.makeDetailViewModel(movie: movie))
                }
            }
        }
        .environmentObject(movieCoordinator)
    }

    private var favoritesTab: some View {
        NavigationStack(path: $favoritesCoordinator.path) {
            FavoritesView(
                viewModel: favoritesViewModel
            )
            .navigationDestination(for: FavoritesRoute.self) { route in
                switch route {
                case let .list(listID):
                    FavoriteListDetailView(
                        viewModel: container.favoritesFactory.makeListDetailViewModel(
                            listID: listID,
                            favoritesStore: favoritesStore
                        )
                    )
                case let .movie(movie):
                    MovieDetailView(viewModel: container.moviesFactory.makeDetailViewModel(movie: movie))
                }
            }
        }
        .environmentObject(favoritesCoordinator)
    }

    private var settingsTab: some View {
        SettingsView(
            container: container,
            viewModel: container.settingsFactory.makeSettingsViewModel()
        )
    }
}

private enum Tab: Hashable {
    case movies
    case favorites
    case settings
}
