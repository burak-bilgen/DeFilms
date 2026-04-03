//
//  MovieSearchViewModel.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation

enum MoviesScreenState: Equatable {
    case browse
    case loadingBrowse
    case searching
    case loadedResults
    case emptyResults
    case error(message: String)
}

struct MovieBrowseSection: Identifiable, Equatable {
    let id: String
    let movies: [Movie]
}

@MainActor
final class MovieSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var filterYear: String = ""
    @Published var minRating: Double = 0
    @Published var selectedGenreID: Int?
    @Published var sortOption: MovieSortOption = .titleAsc
    @Published private(set) var popularMovies: [Movie] = []
    @Published private(set) var upcomingMovies: [Movie] = []
    @Published private(set) var nowPlayingMovies: [Movie] = []
    @Published private(set) var topRatedMovies: [Movie] = []
    @Published private(set) var trendingTodayMovies: [Movie] = []
    @Published private(set) var trendingThisWeekMovies: [Movie] = []
    @Published private(set) var searchResults: [Movie] = []
    @Published private(set) var genres: [MovieGenre] = []
    @Published private(set) var screenState: MoviesScreenState = .browse
    @Published private(set) var searchHistory: [String] = []
    @Published var errorMessage: String?

    private let networkService: NetworkServiceProtocol
    private let recentSearchRepository: RecentSearchRepositoryProtocol
    private let sessionManager: AuthSessionManager
    private let historyLimit = 10
    private var hasLoadedBrowseContent = false
    private var cancellables: Set<AnyCancellable> = []

    init(
        networkService: NetworkServiceProtocol,
        recentSearchRepository: RecentSearchRepositoryProtocol,
        sessionManager: AuthSessionManager
    ) {
        self.networkService = networkService
        self.recentSearchRepository = recentSearchRepository
        self.sessionManager = sessionManager

        sessionManager.$session
            .sink { [weak self] _ in
                self?.loadHistory()
            }
            .store(in: &cancellables)

        loadHistory()
    }

    var browseSections: [MovieBrowseSection] {
        [
            MovieBrowseSection(id: "trending-today", movies: trendingTodayMovies),
            MovieBrowseSection(id: "trending-week", movies: trendingThisWeekMovies),
            MovieBrowseSection(id: "popular", movies: popularMovies),
            MovieBrowseSection(id: "upcoming", movies: upcomingMovies),
            MovieBrowseSection(id: "now-playing", movies: nowPlayingMovies),
            MovieBrowseSection(id: "top-rated", movies: topRatedMovies)
        ]
        .filter { !$0.movies.isEmpty }
    }

    var shouldShowBrowseContent: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var filteredSearchResults: [Movie] {
        var results = searchResults

        let trimmedYear = filterYear.trimmingCharacters(in: .whitespacesAndNewlines)
        if let year = Int(trimmedYear), trimmedYear.count == 4 {
            results = results.filter { $0.releaseYear == String(year) }
        }

        if minRating > 0 {
            results = results.filter { ($0.voteAverage ?? 0) >= minRating }
        }

        if let selectedGenreID {
            results = results.filter { ($0.genreIDs ?? []).contains(selectedGenreID) }
        }

        switch sortOption {
        case .titleAsc:
            results.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleDesc:
            results.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .dateDesc:
            results.sort { ($0.releaseDateValue ?? .distantPast) > ($1.releaseDateValue ?? .distantPast) }
        case .ratingDesc:
            results.sort { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
        }

        return results
    }

    func loadBrowseContentIfNeeded() async {
        guard !hasLoadedBrowseContent else { return }
        await loadBrowseContent()
    }

    func reloadBrowseContent() async {
        hasLoadedBrowseContent = false
        await loadBrowseContent()
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            let message = Localization.string("movies.search.validation.empty")
            errorMessage = message
            searchResults = []
            screenState = .browse
            ToastCenter.shared.showError(message)
            return
        }

        query = trimmedQuery
        screenState = .searching

        do {
            AppLogger.log("Search started for '\(trimmedQuery)'", category: .search)
            let response: MovieResponse = try await networkService.request(
                endpoint: TMDBEndpoint.searchMovie(query: trimmedQuery, page: 1)
            )
            searchResults = response.results
            try recentSearchRepository.addSearch(trimmedQuery, for: sessionManager.currentUserIdentifier, limit: historyLimit)
            loadHistory()
            screenState = filteredSearchResults.isEmpty ? .emptyResults : .loadedResults
            AppLogger.log("Search completed with \(response.results.count) results", category: .search, level: .success)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.search.error.generic")
            errorMessage = message
            searchResults = []
            screenState = .error(message: message)
            ToastCenter.shared.showError(message)
            AppLogger.log("Search failed for '\(trimmedQuery)'", category: .search, level: .error)
        }
    }

    func clearSearch() {
        query = ""
        searchResults = []
        resetFiltersAndSort()
        screenState = .browse
    }

    func selectRecentSearch(_ item: String) async {
        query = item
        await search()
    }

    func clearError() {
        errorMessage = nil
        if shouldShowBrowseContent {
            screenState = .browse
        }
    }

    func reloadForLanguageChange() async {
        hasLoadedBrowseContent = false

        if shouldShowBrowseContent {
            await loadBrowseContent()
        } else {
            await search()
        }
    }

    func resetFiltersAndSort() {
        filterYear = ""
        minRating = 0
        selectedGenreID = nil
        sortOption = .titleAsc
    }

    func loadGenresIfNeeded() async {
        guard genres.isEmpty else { return }

        do {
            let response: MovieGenreResponse = try await networkService.request(endpoint: TMDBEndpoint.genreList)
            genres = response.genres.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            AppLogger.log("Loaded genres", category: .movie, level: .success)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.filter.error")
            errorMessage = message
            ToastCenter.shared.showError(message)
            AppLogger.log("Genre loading failed", category: .movie, level: .error)
        }
    }

    private func loadBrowseContent() async {
        screenState = .loadingBrowse

        do {
            AppLogger.log("Browse loading started", category: .movie)
            trendingTodayMovies = try await fetchMovies(for: TMDBEndpoint.trendingMovies(window: .day, page: 1))
            trendingThisWeekMovies = try await fetchMovies(for: TMDBEndpoint.trendingMovies(window: .week, page: 1))
            popularMovies = try await fetchMovies(for: TMDBEndpoint.popularMovies(page: 1))
            upcomingMovies = try await fetchMovies(for: TMDBEndpoint.upcomingMovies(page: 1))
            nowPlayingMovies = try await fetchMovies(for: TMDBEndpoint.nowPlayingMovies(page: 1))
            topRatedMovies = try await fetchMovies(for: TMDBEndpoint.topRatedMovies(page: 1))
            hasLoadedBrowseContent = true
            screenState = .browse
            AppLogger.log("Browse loading completed", category: .movie, level: .success)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.browse.error")
            errorMessage = message
            screenState = .error(message: message)
            ToastCenter.shared.showError(message)
            AppLogger.log("Browse loading failed", category: .movie, level: .error)
        }
    }

    private func loadHistory() {
        searchHistory = (try? recentSearchRepository.fetchRecentSearches(for: sessionManager.currentUserIdentifier, limit: historyLimit)) ?? []
    }

    private func fetchMovies(for endpoint: TMDBEndpoint) async throws -> [Movie] {
        let response: MovieResponse = try await networkService.request(endpoint: endpoint)
        return response.results
    }
}

enum MovieSortOption: String, CaseIterable, Identifiable {
    case titleAsc
    case titleDesc
    case dateDesc
    case ratingDesc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAsc:
            return Localization.string("movies.sort.titleAsc")
        case .titleDesc:
            return Localization.string("movies.sort.titleDesc")
        case .dateDesc:
            return Localization.string("movies.sort.dateDesc")
        case .ratingDesc:
            return Localization.string("movies.sort.ratingDesc")
        }
    }
}
