//
//  MovieSearchServices.swift
//  DeFilms
//

import Foundation

struct MovieBrowseContent: Equatable {
    let trendingTodayMovies: [Movie]
    let trendingThisWeekMovies: [Movie]
    let popularMovies: [Movie]
    let upcomingMovies: [Movie]
    let nowPlayingMovies: [Movie]
    let topRatedMovies: [Movie]

    var allMovies: [Movie] {
        trendingTodayMovies +
            trendingThisWeekMovies +
            popularMovies +
            upcomingMovies +
            nowPlayingMovies +
            topRatedMovies
    }
}

protocol MovieCatalogServicing {
    func loadBrowseContent() async throws -> MovieBrowseContent
    func searchMovies(query: String, page: Int) async throws -> MovieResponse
    func loadGenres() async throws -> [MovieGenre]
    func prefetchImages(for movies: [Movie]) async
}

protocol MovieSearchHistoryServicing {
    func loadSearchHistory() throws -> [String]
    func saveSearch(_ query: String) throws
    func clearSearchHistory() throws
}

protocol MovieImagePrefetching {
    func prefetch(urls: [URL]) async
}

actor PosterImagePrefetcher: MovieImagePrefetching {
    func prefetch(urls: [URL]) async {
        await PosterImagePipeline.shared.prefetch(urls: urls)
    }
}

final class TMDBMovieCatalogService: MovieCatalogServicing {
    private let networkService: NetworkServiceProtocol
    private let imagePrefetcher: MovieImagePrefetching

    init(
        networkService: NetworkServiceProtocol,
        imagePrefetcher: MovieImagePrefetching = PosterImagePrefetcher()
    ) {
        self.networkService = networkService
        self.imagePrefetcher = imagePrefetcher
    }

    func loadBrowseContent() async throws -> MovieBrowseContent {
        async let trendingToday = fetchMovies(for: .trendingMovies(window: .day, page: 1))
        async let trendingThisWeek = fetchMovies(for: .trendingMovies(window: .week, page: 1))
        async let popular = fetchMovies(for: .popularMovies(page: 1))
        async let upcoming = fetchMovies(for: .upcomingMovies(page: 1))
        async let nowPlaying = fetchMovies(for: .nowPlayingMovies(page: 1))
        async let topRated = fetchMovies(for: .topRatedMovies(page: 1))

        return try await MovieBrowseContent(
            trendingTodayMovies: trendingToday,
            trendingThisWeekMovies: trendingThisWeek,
            popularMovies: popular,
            upcomingMovies: upcoming,
            nowPlayingMovies: nowPlaying,
            topRatedMovies: topRated
        )
    }

    func searchMovies(query: String, page: Int) async throws -> MovieResponse {
        try await networkService.request(
            endpoint: TMDBEndpoint.searchMovie(query: query, page: page)
        )
    }

    func loadGenres() async throws -> [MovieGenre] {
        let response: MovieGenreResponse = try await networkService.request(
            endpoint: TMDBEndpoint.genreList
        )
        return response.genres.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    func prefetchImages(for movies: [Movie]) async {
        let urls = movies.flatMap { movie in
            [movie.posterURL, movie.backdropURL].compactMap { $0 }
        }

        await imagePrefetcher.prefetch(urls: urls)
    }

    private func fetchMovies(for endpoint: TMDBEndpoint) async throws -> [Movie] {
        let response: MovieResponse = try await networkService.request(endpoint: endpoint)
        return response.results
    }
}

final class UserScopedMovieSearchHistoryService: MovieSearchHistoryServicing {
    private let repository: RecentSearchRepositoryProtocol
    private let sessionManager: AuthSessionManaging
    private let limit: Int

    init(
        repository: RecentSearchRepositoryProtocol,
        sessionManager: AuthSessionManaging,
        limit: Int = 10
    ) {
        self.repository = repository
        self.sessionManager = sessionManager
        self.limit = limit
    }

    func loadSearchHistory() throws -> [String] {
        try repository.fetchRecentSearches(
            for: sessionManager.currentUserIdentifier,
            limit: limit
        )
    }

    func saveSearch(_ query: String) throws {
        try repository.addSearch(
            query,
            for: sessionManager.currentUserIdentifier,
            limit: limit
        )
    }

    func clearSearchHistory() throws {
        try repository.clearRecentSearches(for: sessionManager.currentUserIdentifier)
    }
}
