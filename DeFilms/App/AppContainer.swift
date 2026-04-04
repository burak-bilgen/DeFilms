//
//  AppContainer.swift
//  DeFilms
//

import Foundation

final class AppContainer {
    let networkService: NetworkServiceProtocol
    let recentSearchRepository: RecentSearchRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol
    let sessionManager: AuthSessionManager
    let toastCenter: ToastCenter

    init(
        networkService: NetworkServiceProtocol = NetworkManager.shared,
        recentSearchRepository: RecentSearchRepositoryProtocol = RecentSearchRepository.shared,
        favoritesRepository: FavoritesRepositoryProtocol = FavoritesRepository.shared,
        sessionManager: AuthSessionManager = AuthSessionManager.shared,
        toastCenter: ToastCenter = ToastCenter.shared
    ) {
        self.networkService = networkService
        self.recentSearchRepository = recentSearchRepository
        self.favoritesRepository = favoritesRepository
        self.sessionManager = sessionManager
        self.toastCenter = toastCenter
    }

    func makeFavoritesStore() -> FavoritesStore {
        FavoritesStore(
            repository: favoritesRepository,
            sessionManager: sessionManager
        )
    }

    func makeMovieSearchViewModel() -> MovieSearchViewModel {
        MovieSearchViewModel(
            networkService: networkService,
            recentSearchRepository: recentSearchRepository,
            sessionManager: sessionManager
        )
    }

    func makeMovieDetailViewModel(movie: Movie) -> MovieDetailViewModel {
        MovieDetailViewModel(movie: movie, networkService: networkService)
    }

    func makeFavoritesViewModel(favoritesStore: FavoritesStore) -> FavoritesViewModel {
        FavoritesViewModel(favoritesStore: favoritesStore)
    }

    func makeFavoriteListDetailViewModel(
        listID: UUID,
        favoritesStore: FavoritesStore
    ) -> FavoriteListDetailViewModel {
        FavoriteListDetailViewModel(
            listID: listID,
            favoritesStore: favoritesStore
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            bundle: .main,
            sessionManager: sessionManager
        )
    }
}
