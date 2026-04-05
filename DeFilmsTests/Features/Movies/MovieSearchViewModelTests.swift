import XCTest
@testable import DeFilms

@MainActor
final class MovieSearchViewModelTests: XCTestCase {
    func test_MovieSearchViewModel_initialState_matchesBrowseDefaults() {
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(),
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        XCTAssertEqual(viewModel.screenState, .browse)
        XCTAssertTrue(viewModel.shouldShowBrowseContent)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertTrue(viewModel.filteredSearchResults.isEmpty)
        XCTAssertFalse(viewModel.canLoadMoreSearchResults)
        XCTAssertEqual(viewModel.currentSearchPageNumber, 0)
    }

    func test_MovieSearchViewModel_emptyQuery_showsValidationErrorAndResetsSearchState() async {
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(),
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        await viewModel.search()

        XCTAssertEqual(viewModel.screenState, .browse)
        XCTAssertEqual(viewModel.errorMessage, Localization.string("movies.search.validation.empty"))
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }

    func test_MovieSearchViewModel_successfulSearch_storesHistoryResultsAndPrefetchesImages() async {
        let movie = Movie(
            id: 1,
            title: "Arrival",
            overview: "Test",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2016-11-11",
            voteAverage: 8.2,
            genreIDs: [18]
        )
        let historyService = MockMovieSearchHistoryService()
        let catalogService = MockMovieCatalogService(
            searchHandler: { query, page in
                guard query == "Arrival", page == 1 else {
                    throw TestError.unexpectedEndpoint
                }
                return MovieResponse(page: 1, results: [movie], totalPages: 1)
            }
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: historyService,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = " Arrival "

        await viewModel.search()

        XCTAssertEqual(viewModel.screenState, .loadedResults)
        XCTAssertEqual(viewModel.filteredSearchResults, [movie])
        XCTAssertEqual(historyService.history, ["Arrival"])
        XCTAssertEqual(historyService.savedQueries, ["Arrival"])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.canLoadMoreSearchResults)

        let didPrefetch = await waitUntil {
            catalogService.prefetchedMovieBatches.count == 1
        }
        XCTAssertTrue(didPrefetch)
        XCTAssertEqual(catalogService.prefetchedMovieBatches.first, [movie])
    }

    func test_MovieSearchViewModel_paginationNearThreshold_appendsOnlyNewResults() async {
        let firstPageMovies = [
            Movie(id: 1, title: "Arrival", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2016-11-11", voteAverage: 8.2, genreIDs: nil),
            Movie(id: 2, title: "Sicario", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2015-09-18", voteAverage: 7.6, genreIDs: nil),
            Movie(id: 3, title: "Prisoners", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2013-09-20", voteAverage: 8.1, genreIDs: nil)
        ]
        let secondPageMovies = [
            firstPageMovies[2],
            Movie(id: 4, title: "Dune", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2021-10-22", voteAverage: 8.0, genreIDs: nil)
        ]
        let catalogService = MockMovieCatalogService(
            searchHandler: { query, page in
                guard query == "Villeneuve" else { throw TestError.unexpectedEndpoint }
                switch page {
                case 1:
                    return MovieResponse(page: 1, results: firstPageMovies, totalPages: 2)
                case 2:
                    return MovieResponse(page: 2, results: secondPageMovies, totalPages: 2)
                default:
                    throw TestError.unexpectedEndpoint
                }
            }
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = "Villeneuve"

        await viewModel.search()
        await viewModel.loadNextSearchPageIfNeeded(after: firstPageMovies[2], in: viewModel.filteredSearchResults)

        XCTAssertEqual(viewModel.currentSearchPageNumber, 2)
        XCTAssertEqual(viewModel.searchResults.map(\.id), [1, 2, 3, 4])
        XCTAssertEqual(catalogService.searchRequests.count, 2)
    }

    func test_MovieSearchViewModel_reloadForLanguageChange_withActiveSearch_reRunsSearch() async {
        let catalogService = MockMovieCatalogService(
            searchHandler: { query, page in
                MovieResponse(
                    page: page,
                    results: [Movie(id: page, title: query, overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2024-01-01", voteAverage: 7.0, genreIDs: nil)],
                    totalPages: 1
                )
            }
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = "Reload"

        await viewModel.search()
        await viewModel.reloadForLanguageChange(to: .turkish)

        XCTAssertEqual(catalogService.searchRequests.count, 2)
        XCTAssertEqual(viewModel.screenState, .loadedResults)
    }

    func test_MovieSearchViewModel_clearSearchHistory_emptiesHistoryAndCallsService() async {
        let historyService = MockMovieSearchHistoryService(history: ["Arrival", "Dune"])
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(),
            searchHistoryService: historyService,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        await viewModel.clearSearchHistory()

        XCTAssertTrue(viewModel.searchHistory.isEmpty)
        XCTAssertTrue(historyService.didClearHistory)
    }

    func test_MovieSearchViewModel_loadBrowseContentIfNeeded_populatesSectionsOnlyOncePerLanguage() async {
        let browseMovie = Movie(id: 9, title: "Dune", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2021-10-22", voteAverage: 8.0, genreIDs: nil)
        let catalogService = MockMovieCatalogService()
        catalogService.browseContent = MovieBrowseContent(
            trendingTodayMovies: [browseMovie],
            trendingThisWeekMovies: [],
            popularMovies: [],
            upcomingMovies: [],
            nowPlayingMovies: [],
            topRatedMovies: []
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        await viewModel.loadBrowseContentIfNeeded(for: .english)
        await viewModel.loadBrowseContentIfNeeded(for: .english)

        XCTAssertEqual(viewModel.screenState, .browse)
        XCTAssertEqual(viewModel.browseSections.count, 1)
        XCTAssertEqual(viewModel.browseSections.first?.movies, [browseMovie])
        XCTAssertEqual(catalogService.browseLoadCount, 1)
    }

    func test_MovieSearchViewModel_browseFailure_setsErrorStateWithoutLeakingBrowseData() async {
        let catalogService = MockMovieCatalogService()
        catalogService.browseContentError = TestLocalizedError(message: "Browse failed")
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        await viewModel.loadBrowseContentIfNeeded(for: .english)

        XCTAssertEqual(viewModel.screenState, .error(message: "Browse failed"))
        XCTAssertEqual(viewModel.errorMessage, "Browse failed")
        XCTAssertTrue(viewModel.browseSections.isEmpty)
        XCTAssertEqual(viewModel.toastItem?.message, "Browse failed")
    }

    func test_MovieSearchViewModel_duplicateSearchWithoutForce_doesNotRepeatRequest() async {
        let catalogService = MockMovieCatalogService(
            searchHandler: { query, page in
                MovieResponse(page: page, results: [Movie(id: 1, title: query, overview: nil, posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: nil, genreIDs: nil)], totalPages: 1)
            }
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = "Arrival"

        await viewModel.search()
        await viewModel.search()

        XCTAssertEqual(catalogService.searchRequests.count, 1)
    }

    func test_MovieSearchViewModel_clearSearch_resetsStateFiltersAndPagination() async {
        let movie = Movie(id: 1, title: "Arrival", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2016-11-11", voteAverage: 8.2, genreIDs: [18])
        let catalogService = MockMovieCatalogService(
            searchHandler: { _, _ in
                MovieResponse(page: 1, results: [movie], totalPages: 3)
            }
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = "Arrival"
        viewModel.filterYear = "2016"
        viewModel.minRating = 7
        viewModel.selectedGenreID = 18
        viewModel.sortOption = .ratingDesc

        await viewModel.search()
        viewModel.clearSearch()

        XCTAssertTrue(viewModel.query.isEmpty)
        XCTAssertEqual(viewModel.screenState, .browse)
        XCTAssertTrue(viewModel.shouldShowBrowseContent)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertEqual(viewModel.currentSearchPageNumber, 0)
        XCTAssertTrue(viewModel.filterYear.isEmpty)
        XCTAssertEqual(viewModel.minRating, 0)
        XCTAssertNil(viewModel.selectedGenreID)
        XCTAssertEqual(viewModel.sortOption, .relevance)
    }

    func test_MovieSearchViewModel_filteredSearchResults_appliesFiltersAndSorting() async {
        let catalogService = MockMovieCatalogService(
            searchHandler: { _, _ in
                MovieResponse(
                    page: 1,
                    results: [
                        Movie(id: 1, title: "Dune", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2021-10-22", voteAverage: 8.0, genreIDs: [878]),
                        Movie(id: 2, title: "Arrival", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2016-11-11", voteAverage: 7.9, genreIDs: [18, 878]),
                        Movie(id: 3, title: "Sicario", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2015-09-18", voteAverage: 7.6, genreIDs: [80])
                    ],
                    totalPages: 1
                )
            }
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = "Sci-Fi"
        viewModel.filterYear = "2016"
        viewModel.minRating = 7.5
        viewModel.selectedGenreID = 878
        viewModel.sortOption = .titleAsc

        await viewModel.search()

        XCTAssertEqual(viewModel.filteredSearchResults.map(\.id), [2])
    }

    func test_MovieSearchViewModel_clearSearchHistoryFailure_keepsHistoryAndShowsGenericToast() async {
        let historyService = MockMovieSearchHistoryService(history: ["Arrival"])
        historyService.clearHistoryError = TestError.unexpectedEndpoint
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(),
            searchHistoryService: historyService,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        let didLoadHistory = await waitUntil {
            viewModel.searchHistory == ["Arrival"]
        }
        XCTAssertTrue(didLoadHistory)

        await viewModel.clearSearchHistory()

        XCTAssertEqual(viewModel.searchHistory, ["Arrival"])
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("movies.search.error.generic"))
    }

    func test_MovieSearchViewModel_loadGenresIfNeeded_failureMapsLocalizedError() async {
        let catalogService = MockMovieCatalogService()
        catalogService.genresError = TestLocalizedError(message: "Genres unavailable")
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        await viewModel.loadGenresIfNeeded()

        XCTAssertTrue(viewModel.genres.isEmpty)
        XCTAssertEqual(viewModel.errorMessage, "Genres unavailable")
        XCTAssertEqual(viewModel.toastItem?.message, "Genres unavailable")
    }
}
