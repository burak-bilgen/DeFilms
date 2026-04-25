
import Combine
import Foundation
import SwiftUI

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
    @Published var sortOption: MovieSortOption = .relevance
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
    @Published private(set) var toastItem: ToastItem?
    @Published var errorMessage: String?

    private let movieCatalogService: MovieCatalogServicing
    private let searchHistoryService: MovieSearchHistoryServicing
    private let sessionManager: AuthSessionManager
    private var hasLoadedBrowseContent = false
    private var lastLoadedLanguage: AppLanguage?
    private var lastExecutedSearchQuery: String?
    private var currentSearchPage = 0
    private var totalSearchPages = 1
    private var cancellables: Set<AnyCancellable> = []
    private var activeSearchRequestID = UUID()
    private var activeBrowseRequestID = UUID()
    private var activeGenreRequestID = UUID()
    private var activeSearchHistoryRequestID = UUID()

    init(
        movieCatalogService: MovieCatalogServicing,
        searchHistoryService: MovieSearchHistoryServicing,
        sessionManager: AuthSessionManager
    ) {
        self.movieCatalogService = movieCatalogService
        self.searchHistoryService = searchHistoryService
        self.sessionManager = sessionManager

        sessionManager.$session
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.refreshSearchHistory()
                }
            }
            .store(in: &cancellables)

        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self else { return }
                Task { @MainActor in
                    await self.searchIfNeeded(afterDebounce: newValue)
                }
            }
            .store(in: &cancellables)

        Task { @MainActor in
            await refreshSearchHistory()
        }
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

        let releaseYearText = filterYear.trimmingCharacters(in: .whitespacesAndNewlines)
        if let year = Int(releaseYearText), releaseYearText.count == 4 {
            results = results.filter { $0.releaseYear == String(year) }
        }

        if minRating > 0 {
            results = results.filter { ($0.voteAverage ?? 0) >= minRating }
        }

        if let selectedGenreID {
            results = results.filter { ($0.genreIDs ?? []).contains(selectedGenreID) }
        }

        switch sortOption {
        case .relevance:
            break
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

    var currentSearchPageNumber: Int {
        currentSearchPage
    }

    func loadBrowseContentIfNeeded(for language: AppLanguage) async {
        guard !hasLoadedBrowseContent || lastLoadedLanguage != language else { return }
        await loadBrowseContent()
    }

    func refreshBrowseContent() async {
        hasLoadedBrowseContent = false
        await loadBrowseContent()
    }

    func search(force: Bool = false) async {
        let requestID = UUID()
        activeSearchRequestID = requestID

        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else {
            let message = Localization.string("movies.search.validation.empty")
            errorMessage = message
            resetSearchPagination()
            searchResults = []
            isSearchActive = false
            screenState = .browse
            toastItem = .error(message)
            return
        }

        guard force || searchText != lastExecutedSearchQuery else { return }

        query = searchText
        isSearchActive = true
        screenState = .searching

        do {
            AppLogger.log("Search started", category: .search)
            let response = try await movieCatalogService.searchMovies(query: searchText, page: 1)
            guard activeSearchRequestID == requestID else { return }
            updateSearchResults(with: response, appendingResults: false)
            lastExecutedSearchQuery = searchText
            lastLoadedLanguage = AppPreferences.persistedLanguage
            try await searchHistoryService.saveSearch(searchText)
            guard activeSearchRequestID == requestID else { return }
            await refreshSearchHistory()
            screenState = filteredSearchResults.isEmpty ? .emptyResults : .loadedResults
            Task {
                await self.movieCatalogService.prefetchImages(for: response.results)
            }
            AppLogger.log("Search completed with \(response.results.count) results", category: .search, level: .success)
        } catch {
            guard activeSearchRequestID == requestID else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.search.error.generic")
            errorMessage = message
            searchResults = []
            resetSearchPagination()
            screenState = .error(message: message)
            toastItem = .error(message)
            AppLogger.log("Search failed", category: .search, level: .error)
        }
    }

    func clearSearch() {
        activeSearchRequestID = UUID()
        query = ""
        searchResults = []
        lastExecutedSearchQuery = nil
        resetSearchPagination()
        isSearchActive = false
        resetFiltersAndSort()
        screenState = .browse
    }

    func search(usingRecentQuery recentQuery: String) async {
        query = recentQuery
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
        sortOption = .relevance
    }

    func clearSearchHistory() async {
        do {
            try await searchHistoryService.clearSearchHistory()
            searchHistory = []
        } catch {
            toastItem = .error(Localization.string("movies.search.error.generic"))
        }
    }

    func loadGenresIfNeeded() async {
        guard genres.isEmpty else { return }
        let requestID = UUID()
        activeGenreRequestID = requestID

        do {
            let loadedGenres = try await movieCatalogService.loadGenres()
            guard activeGenreRequestID == requestID else { return }
            genres = loadedGenres
            AppLogger.log("Genres loaded", category: .movie, level: .success)
        } catch {
            guard activeGenreRequestID == requestID else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.filter.error")
            errorMessage = message
            toastItem = .error(message)
            AppLogger.log("Failed to load genres", category: .movie, level: .error)
        }
    }

    private func loadBrowseContent() async {
        let requestID = UUID()
        activeBrowseRequestID = requestID
        screenState = .loadingBrowse

        do {
            AppLogger.log("Browse loading started", category: .movie)
            let browseContent = try await movieCatalogService.loadBrowseContent()
            guard activeBrowseRequestID == requestID else { return }
            trendingTodayMovies = browseContent.trendingTodayMovies
            trendingThisWeekMovies = browseContent.trendingThisWeekMovies
            popularMovies = browseContent.popularMovies
            upcomingMovies = browseContent.upcomingMovies
            nowPlayingMovies = browseContent.nowPlayingMovies
            topRatedMovies = browseContent.topRatedMovies
            hasLoadedBrowseContent = true
            lastLoadedLanguage = AppPreferences.persistedLanguage
            screenState = .browse
            Task {
                await self.movieCatalogService.prefetchImages(for: browseContent.allMovies)
            }
            AppLogger.log("Browse loading completed", category: .movie, level: .success)
        } catch {
            guard activeBrowseRequestID == requestID else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.browse.error")
            errorMessage = message
            screenState = .error(message: message)
            toastItem = .error(message)
            AppLogger.log("Browse loading failed", category: .movie, level: .error)
        }
    }

    func clearToast() {
        toastItem = nil
    }

    private func refreshSearchHistory() async {
        let requestID = UUID()
        activeSearchHistoryRequestID = requestID

        let history = (try? await searchHistoryService.loadSearchHistory()) ?? []
        guard activeSearchHistoryRequestID == requestID else { return }
        searchHistory = history
    }

    private func searchIfNeeded(afterDebounce value: String) async {
        let searchText = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !searchText.isEmpty else { return }
        await search()
    }

    func loadNextSearchPageIfNeeded(after currentMovie: Movie, in displayedMovies: [Movie]) async {
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

        let requestID = activeSearchRequestID

        isLoadingNextSearchPage = true
        defer { isLoadingNextSearchPage = false }

        do {
            let nextPage = currentSearchPage + 1
            let response = try await movieCatalogService.searchMovies(
                query: searchText,
                page: nextPage
            )
            guard activeSearchRequestID == requestID else { return }
            guard query.trimmingCharacters(in: .whitespacesAndNewlines) == searchText else { return }

            updateSearchResults(with: response, appendingResults: true)
            Task {
                await self.movieCatalogService.prefetchImages(for: response.results)
            }
        } catch {
            AppLogger.log("Pagination failed", category: .search, level: .error)
        }
    }

    private func resetSearchPagination() {
        currentSearchPage = 0
        totalSearchPages = 1
    }

    private func updateSearchResults(with response: MovieResponse, appendingResults: Bool) {
        currentSearchPage = response.page
        totalSearchPages = max(response.totalPages, 1)

        if appendingResults {
            let existingMovieIDs = Set(searchResults.map(\.id))
            let newResults = response.results.filter { !existingMovieIDs.contains($0.id) }
            withAnimation(.easeOut(duration: 0.24)) {
                searchResults.append(contentsOf: newResults)
            }
        } else {
            searchResults = response.results
        }
    }

}

enum MovieSortOption: String, CaseIterable, Identifiable {
    case relevance
    case titleAsc
    case titleDesc
    case dateAsc
    case dateDesc
    case ratingDesc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .relevance:
            return Localization.string("movies.sort.relevance")
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
