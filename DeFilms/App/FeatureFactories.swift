//
//  FeatureFactories.swift
//  DeFilms
//

import Foundation

final class MoviesFactory {
    private let movieCatalogService: MovieCatalogServicing
    private let movieDetailService: MovieDetailServicing
    private let recentSearchRepository: RecentSearchRepositoryProtocol
    private let sessionManager: AuthSessionManager

    init(
        networkService: NetworkServiceProtocol,
        recentSearchRepository: RecentSearchRepositoryProtocol,
        sessionManager: AuthSessionManager
    ) {
        self.movieCatalogService = TMDBMovieCatalogService(networkService: networkService)
        self.movieDetailService = TMDBMovieDetailService(
            networkService: networkService,
            imagePrefetcher: PosterImagePrefetcher()
        )
        self.recentSearchRepository = recentSearchRepository
        self.sessionManager = sessionManager
    }

    func makeSearchViewModel() -> MovieSearchViewModel {
        MovieSearchViewModel(
            movieCatalogService: movieCatalogService,
            searchHistoryService: UserScopedMovieSearchHistoryService(
                repository: recentSearchRepository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )
    }

    func makeDetailViewModel(movie: Movie) -> MovieDetailViewModel {
        MovieDetailViewModel(movie: movie, detailService: movieDetailService)
    }
}

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

final class SettingsFactory {
    private let sessionManager: AuthSessionManager
    private let authFormService: AuthFormServicing

    init(sessionManager: AuthSessionManager) {
        self.sessionManager = sessionManager
        self.authFormService = AuthFormService(sessionManager: sessionManager)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            bundle: .main,
            sessionManager: sessionManager
        )
    }

    func makeSignInViewModel() -> SignInViewModel {
        SignInViewModel(authFormService: authFormService)
    }

    func makeSignUpViewModel() -> SignUpViewModel {
        SignUpViewModel(authFormService: authFormService)
    }

    func makeChangePasswordViewModel() -> ChangePasswordViewModel {
        ChangePasswordViewModel(authFormService: authFormService)
    }
}
