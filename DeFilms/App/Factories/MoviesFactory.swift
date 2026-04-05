//
//  MoviesFactory.swift
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
