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
    @Published private(set) var isSearchActive = false
    @Published private(set) var isLoadingNextSearchPage = false
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
    private var lastLoadedLanguage: AppLanguage?
    private var lastExecutedSearchQuery: String?
    private var currentSearchPage = 0
    private var totalSearchPages = 1
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

        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                Task { @MainActor in
                    await self.handleDebouncedQueryChange(newValue)
                }
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
        !isSearchActive
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
        case .dateAsc:
            results.sort { ($0.releaseDateValue ?? .distantFuture) < ($1.releaseDateValue ?? .distantFuture) }
        case .dateDesc:
            results.sort { ($0.releaseDateValue ?? .distantPast) > ($1.releaseDateValue ?? .distantPast) }
        case .ratingDesc:
            results.sort { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
        }

        return results
    }

    var canLoadMoreSearchResults: Bool {
        isSearchActive && currentSearchPage < totalSearchPages
    }

    func loadBrowseContentIfNeeded(for language: AppLanguage) async {
        guard !hasLoadedBrowseContent || lastLoadedLanguage != language else { return }
        await loadBrowseContent()
    }

    func reloadBrowseContent() async {
        hasLoadedBrowseContent = false
        await loadBrowseContent()
    }

    func search(force: Bool = false) async {
        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else {
            let message = Localization.string("movies.search.validation.empty")
            errorMessage = message
            resetSearchPagination()
            searchResults = []
            isSearchActive = false
            screenState = .browse
            ToastCenter.shared.showError(message)
            return
        }

        guard force || searchText != lastExecutedSearchQuery else { return }

        query = searchText
        isSearchActive = true
        screenState = .searching

        do {
            AppLogger.log("Search started for '\(searchText)'", category: .search)
            let response: MovieResponse = try await networkService.request(
                endpoint: TMDBEndpoint.searchMovie(query: searchText, page: 1)
            )
            applySearchPage(response, appendResults: false)
            lastExecutedSearchQuery = searchText
            lastLoadedLanguage = AppPreferences.persistedLanguage
            try recentSearchRepository.addSearch(searchText, for: sessionManager.currentUserIdentifier, limit: historyLimit)
            loadHistory()
            screenState = filteredSearchResults.isEmpty ? .emptyResults : .loadedResults
            AppLogger.log("Search completed with \(response.results.count) results", category: .search, level: .success)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.search.error.generic")
            errorMessage = message
            searchResults = []
            resetSearchPagination()
            screenState = .error(message: message)
            ToastCenter.shared.showError(message)
            AppLogger.log("Search failed for '\(searchText)'", category: .search, level: .error)
        }
    }

    func clearSearch() {
        query = ""
        searchResults = []
        lastExecutedSearchQuery = nil
        resetSearchPagination()
        isSearchActive = false
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

    func reloadForLanguageChange(to language: AppLanguage) async {
        guard lastLoadedLanguage != language else { return }
        hasLoadedBrowseContent = false
        genres = []
        errorMessage = nil
        lastExecutedSearchQuery = nil
        resetSearchPagination()

        if shouldShowBrowseContent {
            await loadBrowseContent()
        } else {
            await search(force: true)
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
            lastLoadedLanguage = AppPreferences.persistedLanguage
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

    private func handleDebouncedQueryChange(_ value: String) async {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedValue.isEmpty else { return }
        await search()
    }

    func loadNextSearchPageIfNeeded(currentMovie: Movie, displayedMovies: [Movie]) async {
        guard canLoadMoreSearchResults, !isLoadingNextSearchPage else { return }
        guard let currentIndex = displayedMovies.firstIndex(where: { $0.id == currentMovie.id }) else { return }

        let prefetchBuffer = min(max(displayedMovies.count / 4, 6), 12)
        let thresholdIndex = max(displayedMovies.count - prefetchBuffer, 0)
        guard currentIndex >= thresholdIndex else { return }

        await loadNextSearchPage()
    }

    private func loadNextSearchPage() async {
        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty, currentSearchPage < totalSearchPages else { return }

        isLoadingNextSearchPage = true
        defer { isLoadingNextSearchPage = false }

        do {
            let nextPage = currentSearchPage + 1
            let response: MovieResponse = try await networkService.request(
                endpoint: TMDBEndpoint.searchMovie(query: searchText, page: nextPage)
            )

            applySearchPage(response, appendResults: true)
        } catch {
            AppLogger.log("Pagination failed for '\(searchText)'", category: .search, level: .error)
        }
    }

    private func fetchMovies(for endpoint: TMDBEndpoint) async throws -> [Movie] {
        let response: MovieResponse = try await networkService.request(endpoint: endpoint)
        return response.results
    }

    private func resetSearchPagination() {
        currentSearchPage = 0
        totalSearchPages = 1
    }

    private func applySearchPage(_ response: MovieResponse, appendResults: Bool) {
        currentSearchPage = response.page
        totalSearchPages = max(response.totalPages, 1)

        if appendResults {
            let existingMovieIDs = Set(searchResults.map(\.id))
            searchResults.append(contentsOf: response.results.filter { !existingMovieIDs.contains($0.id) })
        } else {
            searchResults = response.results
        }
    }
}

enum MovieSortOption: String, CaseIterable, Identifiable {
    case titleAsc
    case titleDesc
    case dateAsc
    case dateDesc
    case ratingDesc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .titleAsc:
            return Localization.string("movies.sort.titleAsc")
        case .titleDesc:
            return Localization.string("movies.sort.titleDesc")
        case .dateAsc:
            return Localization.string("movies.sort.dateAsc")
        case .dateDesc:
            return Localization.string("movies.sort.dateDesc")
        case .ratingDesc:
            return Localization.string("movies.sort.ratingDesc")
        }
    }
}
