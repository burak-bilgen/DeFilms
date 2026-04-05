//
//  FavoritesFactory.swift
//  DeFilms
//

import Foundation

final class FavoritesFactory {
    private let favoritesService: FavoritesServicing
    private let sessionManager: AuthSessionManager

    init(
        favoritesRepository: FavoritesRepositoryProtocol,
        sessionManager: AuthSessionManager
    ) {
        self.favoritesService = FavoritesService(
            repository: favoritesRepository,
            sessionManager: sessionManager
        )
        self.sessionManager = sessionManager
    }

    func makeStore() -> FavoritesStore {
        FavoritesStore(
            favoritesService: favoritesService,
            sessionManager: sessionManager
        )
    }

    func makeFavoritesViewModel(favoritesStore: FavoritesStore) -> FavoritesViewModel {
        FavoritesViewModel(favoritesStore: favoritesStore)
    }

    func makeListDetailViewModel(
        listID: UUID,
        favoritesStore: FavoritesStore
    ) -> FavoriteListDetailViewModel {
        FavoriteListDetailViewModel(
            listID: listID,
            favoritesStore: favoritesStore
        )
    }
}
