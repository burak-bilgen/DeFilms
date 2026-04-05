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
    let moviesFactory: MoviesFactory
    let favoritesFactory: FavoritesFactory
    let settingsFactory: SettingsFactory

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
        self.moviesFactory = MoviesFactory(
            networkService: networkService,
            recentSearchRepository: recentSearchRepository,
            sessionManager: sessionManager
        )
        self.favoritesFactory = FavoritesFactory(
            favoritesRepository: favoritesRepository,
            sessionManager: sessionManager
        )
        self.settingsFactory = SettingsFactory(sessionManager: sessionManager)
    }
}
