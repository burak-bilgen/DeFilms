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
        if ProcessInfo.processInfo.arguments.contains("UITest.MockMovies") {
            self.movieCatalogService = UITestMovieCatalogService()
            self.movieDetailService = UITestMovieDetailService()
        } else {
            self.movieCatalogService = TMDBMovieCatalogService(networkService: networkService)
            self.movieDetailService = TMDBMovieDetailService(
                networkService: networkService,
                imagePrefetcher: PosterImagePrefetcher()
            )
        }
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

private struct UITestMovieCatalogService: MovieCatalogServicing {
    private let featuredMovie = Movie(
        id: 1001,
        title: "Dune",
        overview: "A deterministic UI test movie.",
        posterPath: nil,
        backdropPath: nil,
        releaseDate: "2021-10-22",
        voteAverage: 8.0,
        genreIDs: [878]
    )

    private let supportingMovie = Movie(
        id: 1002,
        title: "Arrival",
        overview: "A deterministic UI test movie.",
        posterPath: nil,
        backdropPath: nil,
        releaseDate: "2016-11-11",
        voteAverage: 7.9,
        genreIDs: [18, 878]
    )

    func loadBrowseContent() async throws -> MovieBrowseContent {
        MovieBrowseContent(
            trendingTodayMovies: [featuredMovie],
            trendingThisWeekMovies: [supportingMovie],
            popularMovies: [featuredMovie, supportingMovie],
            upcomingMovies: [featuredMovie],
            nowPlayingMovies: [supportingMovie],
            topRatedMovies: [featuredMovie]
        )
    }

    func searchMovies(query: String, page: Int) async throws -> MovieResponse {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let results: [Movie]

        if normalizedQuery.contains("dune") {
            results = [featuredMovie]
        } else if normalizedQuery.contains("arrival") {
            results = [supportingMovie]
        } else {
            results = [featuredMovie, supportingMovie]
        }

        return MovieResponse(page: page, results: results, totalPages: 1)
    }

    func loadGenres() async throws -> [MovieGenre] {
        [
            MovieGenre(id: 18, name: "Drama"),
            MovieGenre(id: 878, name: "Science Fiction")
        ]
    }

    func prefetchImages(for movies: [Movie]) async {}
}

@MainActor
private final class UITestMovieDetailService: MovieDetailServicing {
    func loadPayload(for movie: Movie) async throws -> MovieDetailPayload {
        let detail = MovieDetail(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.posterPath,
            backdropPath: movie.backdropPath,
            releaseDate: movie.releaseDate,
            voteAverage: movie.voteAverage,
            runtime: 155,
            imdbID: "tt1160419",
            genres: [MovieGenre(id: 878, name: "Science Fiction")]
        )

        return MovieDetailPayload(
            detail: detail,
            trailer: MovieVideo(key: "abc123", name: "Trailer", site: "YouTube", type: "Trailer", official: true),
            gallery: [],
            directors: [MovieCrewMember(id: 1, name: "Denis Villeneuve", job: "Director", profilePath: nil)],
            cast: [MovieCastMember(id: 2, name: "Timothee Chalamet", character: "Paul Atreides", profilePath: nil)],
            streamingPlatforms: [],
            similarMovies: []
        )
    }
}
