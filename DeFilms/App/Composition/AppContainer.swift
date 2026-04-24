//
//  AppContainer.swift
//  DeFilms
//

import Foundation

final class AppContainer {
    let persistenceController: PersistenceController
    let keychainService: KeychainServicing
    let networkService: NetworkServiceProtocol
    let recentSearchRepository: RecentSearchRepository
    let favoritesRepository: FavoritesRepository
    let sessionManager: AuthSessionManager
    let toastCenter: ToastCenter
    let moviesFactory: MoviesFactory
    let favoritesFactory: FavoritesFactory
    let settingsFactory: SettingsFactory

    init(
        persistenceController: PersistenceController = PersistenceController(),
        keychainService: KeychainServicing = KeychainService(),
        networkService: NetworkServiceProtocol? = nil,
        recentSearchRepository: RecentSearchRepository? = nil,
        favoritesRepository: FavoritesRepository? = nil,
        sessionManager: AuthSessionManager? = nil,
        toastCenter: ToastCenter = ToastCenter()
    ) {
        let resolvedNetworkService = networkService ?? NetworkManager()
        let resolvedRecentSearchRepository = recentSearchRepository ?? RecentSearchRepository(
            persistenceController: persistenceController
        )
        let resolvedFavoritesRepository = favoritesRepository ?? FavoritesRepository(
            persistenceController: persistenceController
        )
        let resolvedSessionManager = sessionManager ?? AuthSessionManager(
            keychainService: keychainService
        )

        self.persistenceController = persistenceController
        self.keychainService = keychainService
        self.networkService = resolvedNetworkService
        self.recentSearchRepository = resolvedRecentSearchRepository
        self.favoritesRepository = resolvedFavoritesRepository
        self.sessionManager = resolvedSessionManager
        self.toastCenter = toastCenter
        self.moviesFactory = MoviesFactory(
            networkService: resolvedNetworkService,
            recentSearchRepository: resolvedRecentSearchRepository,
            sessionManager: resolvedSessionManager
        )
        self.favoritesFactory = FavoritesFactory(
            favoritesRepository: resolvedFavoritesRepository,
            sessionManager: resolvedSessionManager
        )
        self.settingsFactory = SettingsFactory(
            sessionManager: resolvedSessionManager,
            favoritesRepository: resolvedFavoritesRepository,
            recentSearchRepository: resolvedRecentSearchRepository
        )
    }
}
