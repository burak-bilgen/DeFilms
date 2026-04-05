import Foundation
import Testing
@testable import DeFilms

@MainActor
struct MovieSearchViewModelTests {
    @Test
    func emptyQueryShowsValidationError() async {
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(),
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        await viewModel.search()

        #expect(viewModel.screenState == .browse)
        #expect(viewModel.errorMessage == Localization.string("movies.search.validation.empty"))
        #expect(viewModel.searchResults.isEmpty)
    }

    @Test
    func successfulSearchStoresHistoryAndResults() async throws {
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
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(
                searchHandler: { query, page in
                    guard query == "Arrival", page == 1 else {
                        throw TestError.unexpectedEndpoint
                    }
                    return MovieResponse(page: 1, results: [movie], totalPages: 1)
                }
            ),
            searchHistoryService: historyService,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = " Arrival "

        await viewModel.search()

        #expect(viewModel.screenState == .loadedResults)
        #expect(viewModel.filteredSearchResults == [movie])
        #expect(historyService.history == ["Arrival"])
    }

    @Test
    func paginationAppendsOnlyNewResultsNearThreshold() async {
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
                if page == 1 {
                    return MovieResponse(page: 1, results: firstPageMovies, totalPages: 2)
                }
                if page == 2 {
                    return MovieResponse(page: 2, results: secondPageMovies, totalPages: 2)
                }
                throw TestError.unexpectedEndpoint
            }
        )
        let viewModel = MovieSearchViewModel(
            movieCatalogService: catalogService,
            searchHistoryService: MockMovieSearchHistoryService(),
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = "Villeneuve"

        await viewModel.search()
        await viewModel.loadNextSearchPageIfNeeded(
            after: firstPageMovies[2],
            in: viewModel.filteredSearchResults
        )

        #expect(viewModel.currentSearchPageNumber == 2)
        #expect(viewModel.searchResults.map(\.id) == [1, 2, 3, 4])
        #expect(catalogService.searchRequests.count == 2)
    }

    @Test
    func reloadForLanguageChangeReRunsActiveSearch() async {
        let catalogService = MockMovieCatalogService(
            searchHandler: { query, page in
                MovieResponse(
                    page: page,
                    results: [
                        Movie(id: page, title: query, overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2024-01-01", voteAverage: 7.0, genreIDs: nil)
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
        viewModel.query = "Reload"

        await viewModel.search()
        await viewModel.reloadForLanguageChange(to: .turkish)

        #expect(catalogService.searchRequests.count == 2)
        #expect(viewModel.screenState == .loadedResults)
    }

    @Test
    func clearSearchHistoryEmptiesLocalHistoryAndCallsService() async {
        let historyService = MockMovieSearchHistoryService(history: ["Arrival", "Dune"])
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(),
            searchHistoryService: historyService,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        await viewModel.clearSearchHistory()

        #expect(viewModel.searchHistory.isEmpty)
        #expect(historyService.didClearHistory)
    }
}
