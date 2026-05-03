
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
    @Published private(set) var criticallyAcclaimedMovies: [Movie] = []
    @Published private(set) var hiddenGemMovies: [Movie] = []
    @Published private(set) var actionAdventureMovies: [Movie] = []
    @Published private(set) var familyNightMovies: [Movie] = []
    @Published private(set) var searchResults: [Movie] = []
    @Published private(set) var genres: [MovieGenre] = []
    @Published private(set) var screenState: MoviesScreenState = .browse
    @Published private(set) var searchHistory: [String] = []
    @Published private(set) var toastItem: ToastItem?
    @Published private(set) var loadingBrowseSectionIDs: Set<String> = []
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
    private var activeBrowseSectionRequestIDs: [String: UUID] = [:]
    private var activeGenreRequestID = UUID()
    private var activeSearchHistoryRequestID = UUID()
    private var browseSectionPages: [String: Int] = [:]
    private var browseSectionTotalPages: [String: Int] = [:]

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
            MovieBrowseSection(id: "now-playing", movies: nowPlayingMovies),
            MovieBrowseSection(id: "popular", movies: popularMovies),
            MovieBrowseSection(id: "top-rated", movies: topRatedMovies),
            MovieBrowseSection(id: "critically-acclaimed", movies: criticallyAcclaimedMovies),
            MovieBrowseSection(id: "hidden-gems", movies: hiddenGemMovies),
            MovieBrowseSection(id: "action-adventure", movies: actionAdventureMovies),
            MovieBrowseSection(id: "family-night", movies: familyNightMovies),
            MovieBrowseSection(id: "upcoming", movies: upcomingMovies),
            MovieBrowseSection(id: "trending-week", movies: trendingThisWeekMovies)
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

    func loadAICandidateMovies(matching prompt: String, aiSearchPlan: MovieAISearchPlan? = nil) async throws -> [Movie] {
        let searchPlan = MovieAICandidateSearchPlan(prompt: prompt, aiSearchPlan: aiSearchPlan)
        guard !searchPlan.isEmpty else { return [] }

        var rankedCandidates = MovieAICandidateRanker(searchPlan: searchPlan)
        var keywords: [MovieKeyword] = []

        for query in searchPlan.movieQueries {
            let response = try await movieCatalogService.searchMovies(query: query, page: 1)
            rankedCandidates.add(response.results, sourceBoost: 8)
        }

        for query in searchPlan.keywordQueries {
            let response = try await movieCatalogService.searchKeywords(query: query, page: 1)
            keywords.append(contentsOf: response.results.prefix(3))
        }

        let keywordIDs = keywords.uniquedByID().prefix(12).map(\.id)
        if !keywordIDs.isEmpty {
            let response = try await movieCatalogService.discoverMovies(
                keywordIDs: Array(keywordIDs),
                matchMode: .any,
                page: 1
            )
            rankedCandidates.add(response.results, sourceBoost: 14)
        }

        let focusedKeywordIDs = keywords.uniquedByID().prefix(4).map(\.id)
        if focusedKeywordIDs.count > 1 {
            let response = try await movieCatalogService.discoverMovies(
                keywordIDs: Array(focusedKeywordIDs),
                matchMode: .all,
                page: 1
            )
            rankedCandidates.add(response.results, sourceBoost: 28)
        }

        for keywordPair in focusedKeywordIDs.adjacentPairs().prefix(4) {
            let response = try await movieCatalogService.discoverMovies(
                keywordIDs: [keywordPair.0, keywordPair.1],
                matchMode: .all,
                page: 1
            )
            rankedCandidates.add(response.results, sourceBoost: 22)
        }

        let uniqueMovies = rankedCandidates.movies(limit: 72)
        Task {
            await self.movieCatalogService.prefetchImages(for: uniqueMovies)
        }
        return uniqueMovies
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
            criticallyAcclaimedMovies = browseContent.criticallyAcclaimedMovies
            hiddenGemMovies = browseContent.hiddenGemMovies
            actionAdventureMovies = browseContent.actionAdventureMovies
            familyNightMovies = browseContent.familyNightMovies
            resetBrowseSectionPagination()
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

    func isLoadingMoreBrowseSection(_ sectionID: String) -> Bool {
        loadingBrowseSectionIDs.contains(sectionID)
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

    func loadNextBrowseSectionPageIfNeeded(after currentMovie: Movie, in section: MovieBrowseSection) async {
        guard shouldShowBrowseContent else { return }
        guard loadingBrowseSectionIDs.contains(section.id) == false else { return }
        guard let currentIndex = section.movies.firstIndex(where: { $0.id == currentMovie.id }) else { return }

        let prefetchBuffer = min(max(section.movies.count / 4, 5), 10)
        let thresholdIndex = max(section.movies.count - prefetchBuffer, 0)
        guard currentIndex >= thresholdIndex else { return }

        let currentPage = browseSectionPages[section.id, default: 1]
        let totalPages = browseSectionTotalPages[section.id, default: 500]
        guard currentPage < totalPages else { return }

        await loadNextBrowseSectionPage(sectionID: section.id, currentPage: currentPage)
    }

    func loadNextSearchPageIfNeeded(after currentMovie: Movie, in displayedMovies: [Movie]) async {
        guard canLoadMoreSearchResults, !isLoadingNextSearchPage else { return }
        guard let currentIndex = displayedMovies.firstIndex(where: { $0.id == currentMovie.id }) else { return }

        let prefetchBuffer = min(max(displayedMovies.count / 4, 6), 12)
        let thresholdIndex = max(displayedMovies.count - prefetchBuffer, 0)
        guard currentIndex >= thresholdIndex else { return }

        await loadNextSearchPage()
    }

    private func loadNextBrowseSectionPage(sectionID: String, currentPage: Int) async {
        let requestID = UUID()
        activeBrowseSectionRequestIDs[sectionID] = requestID

        withAnimation(.easeInOut(duration: 0.2)) {
            _ = loadingBrowseSectionIDs.insert(sectionID)
        }

        defer {
            if activeBrowseSectionRequestIDs[sectionID] == requestID {
                activeBrowseSectionRequestIDs[sectionID] = nil
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                _ = loadingBrowseSectionIDs.remove(sectionID)
            }
        }

        do {
            let nextPage = currentPage + 1
            let response = try await movieCatalogService.loadBrowseSection(sectionID: sectionID, page: nextPage)
            guard activeBrowseSectionRequestIDs[sectionID] == requestID else { return }

            browseSectionPages[sectionID] = response.page
            browseSectionTotalPages[sectionID] = max(response.totalPages, response.page)
            appendBrowseMovies(response.results, to: sectionID)

            Task {
                await self.movieCatalogService.prefetchImages(for: response.results)
            }
        } catch {
            AppLogger.log("Browse section pagination failed", category: .movie, level: .error)
        }
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

    private func appendBrowseMovies(_ movies: [Movie], to sectionID: String) {
        guard !movies.isEmpty else { return }

        withAnimation(.easeOut(duration: 0.24)) {
            switch sectionID {
            case "trending-today":
                trendingTodayMovies.appendUniqueMovies(movies)
            case "trending-week":
                trendingThisWeekMovies.appendUniqueMovies(movies)
            case "popular":
                popularMovies.appendUniqueMovies(movies)
            case "upcoming":
                upcomingMovies.appendUniqueMovies(movies)
            case "now-playing":
                nowPlayingMovies.appendUniqueMovies(movies)
            case "top-rated":
                topRatedMovies.appendUniqueMovies(movies)
            case "critically-acclaimed":
                criticallyAcclaimedMovies.appendUniqueMovies(movies)
            case "hidden-gems":
                hiddenGemMovies.appendUniqueMovies(movies)
            case "action-adventure":
                actionAdventureMovies.appendUniqueMovies(movies)
            case "family-night":
                familyNightMovies.appendUniqueMovies(movies)
            default:
                break
            }
        }
    }

    private func resetBrowseSectionPagination() {
        browseSectionPages = Dictionary(uniqueKeysWithValues: browseSections.map { ($0.id, 1) })
        browseSectionTotalPages = [:]
        activeBrowseSectionRequestIDs = [:]
        loadingBrowseSectionIDs = []
    }

}

struct MovieAICandidateSearchPlan {
    let movieQueries: [String]
    let keywordQueries: [String]
    let rankingTerms: [String]
    let rankingPhrases: [String]

    var isEmpty: Bool {
        movieQueries.isEmpty && keywordQueries.isEmpty
    }

    init(prompt: String, aiSearchPlan: MovieAISearchPlan? = nil) {
        let normalized = prompt
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else {
            movieQueries = []
            keywordQueries = []
            rankingTerms = []
            rankingPhrases = []
            return
        }

        let words = normalized
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
        let terms = Self.priorityTerms(from: words)
        let expandedTerms = Self.expandedKeywordTerms(from: terms)
        let phrases = Self.contiguousPhrases(from: terms, maxLength: 3)
        let aiTitleQueries = aiSearchPlan?.titleQueries ?? []
        let aiKeywordQueries = aiSearchPlan?.keywordQueries ?? []
        let aiTerms = aiSearchPlan?.semanticTerms ?? []
        let aiPhrases = aiSearchPlan?.semanticPhrases ?? []

        movieQueries = (
            aiTitleQueries +
                [normalized] +
                terms
        )
        .uniqued()
        .prefix(10)
        .map { $0 }

        keywordQueries = (
            aiKeywordQueries +
                aiPhrases +
                [normalized] +
                phrases +
                terms +
                expandedTerms +
                aiTerms
        )
        .uniqued()
        .prefix(32)
        .map { $0 }

        rankingTerms = (aiTerms + terms + expandedTerms).uniqued()
        rankingPhrases = (aiPhrases + [normalized] + phrases + expandedTerms.filter { $0.contains(" ") }).uniqued()
    }

    private static func priorityTerms(from words: [String]) -> [String] {
        var terms: [String] = []
        let stopWords: Set<String> = [
            "a", "an", "and", "about", "around", "for", "give", "i", "ile", "ilgili",
            "movie", "movies", "film", "films", "filmler", "with", "the", "to", "want",
            "ben", "bana", "bir", "listele", "oner"
        ]

        for word in words where !stopWords.contains(word) && word.count > 2 {
            terms.append(word)
            if word.hasSuffix("ies"), word.count > 4 {
                terms.append(String(word.dropLast(3)) + "y")
            } else if word.hasSuffix("s"), word.count > 3 {
                terms.append(String(word.dropLast()))
            }
        }

        return terms
    }

    private static func expandedKeywordTerms(from terms: [String]) -> [String] {
        let expansions: [String: [String]] = [
            "alien": ["extraterrestrial", "space", "invasion", "creature"],
            "aliens": ["extraterrestrial", "space", "invasion", "creature"],
            "apocalypse": ["post-apocalyptic", "end of world", "dystopia", "wasteland", "survival"],
            "apocalyptic": ["post-apocalyptic", "end of world", "dystopia", "wasteland", "survival"],
            "car": ["car chase", "vehicle", "road movie", "race", "racing"],
            "cars": ["car chase", "vehicle", "road movie", "race", "racing"],
            "desert": ["wasteland", "sandstorm", "survival", "road movie"],
            "ghost": ["haunting", "supernatural", "spirit"],
            "haunted": ["haunting", "supernatural", "ghost"],
            "robot": ["android", "artificial intelligence", "machine"],
            "robots": ["android", "artificial intelligence", "machine"],
            "space": ["outer space", "space travel", "planet", "spaceship"],
            "vampire": ["vampire", "supernatural", "blood"],
            "vampires": ["vampire", "supernatural", "blood"],
            "zombie": ["zombie apocalypse", "undead", "survival horror", "infection"],
            "zombies": ["zombie apocalypse", "undead", "survival horror", "infection"]
        ]

        return terms.flatMap { term in
            expansions[term, default: []]
        }
    }

    private static func contiguousPhrases(from words: [String], maxLength: Int) -> [String] {
        guard words.count > 1 else { return [] }

        var phrases: [String] = []
        for startIndex in words.indices {
            let upperBound = min(words.count, startIndex + maxLength)
            guard startIndex + 1 < upperBound else { continue }

            for endIndex in (startIndex + 2)...upperBound {
                phrases.append(words[startIndex..<endIndex].joined(separator: " "))
            }
        }

        return phrases
    }
}

private struct MovieAICandidateRanker {
    private struct RankedMovie {
        var movie: Movie
        var score: Double
    }

    private let searchPlan: MovieAICandidateSearchPlan
    private var rankedMovies: [Int: RankedMovie] = [:]

    init(searchPlan: MovieAICandidateSearchPlan) {
        self.searchPlan = searchPlan
    }

    mutating func add(_ movies: [Movie], sourceBoost: Double) {
        for movie in movies {
            let score = sourceBoost + lexicalScore(for: movie) + ratingScore(for: movie)
            if var existing = rankedMovies[movie.id] {
                existing.score += score * 0.45
                existing.movie = merge(existing.movie, with: movie)
                rankedMovies[movie.id] = existing
            } else {
                rankedMovies[movie.id] = RankedMovie(movie: movie, score: score)
            }
        }
    }

    func movies(limit: Int) -> [Movie] {
        rankedMovies.values
            .sorted {
                if $0.score == $1.score {
                    return ($0.movie.voteAverage ?? 0) > ($1.movie.voteAverage ?? 0)
                }
                return $0.score > $1.score
            }
            .prefix(limit)
            .map(\.movie)
    }

    private func lexicalScore(for movie: Movie) -> Double {
        let title = movie.title.lowercased()
        let overview = (movie.overview ?? "").lowercased()
        var score: Double = 0

        for phrase in searchPlan.rankingPhrases where phrase.count > 3 {
            if title.contains(phrase) {
                score += 18
            }
            if overview.contains(phrase) {
                score += 7
            }
        }

        for term in searchPlan.rankingTerms where term.count > 2 {
            if title.contains(term) {
                score += 8
            }
            if overview.contains(term) {
                score += 3
            }
        }

        return score
    }

    private func ratingScore(for movie: Movie) -> Double {
        guard let rating = movie.voteAverage else { return 0 }
        return min(max(rating - 5, 0), 4)
    }

    private func merge(_ existing: Movie, with incoming: Movie) -> Movie {
        Movie(
            id: existing.id,
            title: existing.title,
            overview: existing.overview ?? incoming.overview,
            posterPath: existing.posterPath ?? incoming.posterPath,
            backdropPath: existing.backdropPath ?? incoming.backdropPath,
            releaseDate: existing.releaseDate ?? incoming.releaseDate,
            voteAverage: existing.voteAverage ?? incoming.voteAverage,
            genreIDs: existing.genreIDs ?? incoming.genreIDs
        )
    }
}

private extension Array where Element == Movie {
    mutating func appendUniqueMovies(_ movies: [Movie]) {
        var seenIDs = Set(map(\.id))
        append(contentsOf: movies.filter { seenIDs.insert($0.id).inserted })
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

private extension Array where Element == MovieKeyword {
    func uniquedByID() -> [MovieKeyword] {
        var seen = Set<Int>()
        return filter { seen.insert($0.id).inserted }
    }
}

private extension Array where Element == Int {
    func adjacentPairs() -> [(Int, Int)] {
        guard count > 1 else { return [] }
        return zip(self, dropFirst()).map { ($0, $1) }
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
