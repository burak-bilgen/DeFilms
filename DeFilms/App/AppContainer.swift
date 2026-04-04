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
    private let movieCatalogService: MovieCatalogServicing
    private let movieDetailService: MovieDetailServicing
    private let favoritesService: FavoritesServicing
    private let authFormService: AuthFormServicing

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
        self.movieCatalogService = TMDBMovieCatalogService(networkService: networkService)
        self.movieDetailService = TMDBMovieDetailService(
            networkService: networkService,
            imagePrefetcher: PosterImagePrefetcher()
        )
        self.favoritesService = FavoritesService(
            repository: favoritesRepository,
            sessionManager: sessionManager
        )
        self.authFormService = AuthFormService(sessionManager: sessionManager)
    }

    func makeFavoritesStore() -> FavoritesStore {
        FavoritesStore(
            favoritesService: favoritesService,
            sessionManager: sessionManager
        )
    }

    func makeMovieSearchViewModel() -> MovieSearchViewModel {
        MovieSearchViewModel(
            movieCatalogService: movieCatalogService,
            searchHistoryService: UserScopedMovieSearchHistoryService(
                repository: recentSearchRepository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )
    }

    func makeMovieDetailViewModel(movie: Movie) -> MovieDetailViewModel {
        MovieDetailViewModel(movie: movie, detailService: movieDetailService)
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
