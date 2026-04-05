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
            },
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
            currentMovie: firstPageMovies[2],
            displayedMovies: viewModel.filteredSearchResults
        )

        #expect(viewModel.currentSearchPageNumber == 2)
        #expect(viewModel.searchResults.map(\.id) == [1, 2, 3, 4])
        #expect(catalogService.searchRequests == [("Villeneuve", 1), ("Villeneuve", 2)])
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
    func clearSearchHistoryEmptiesLocalHistoryAndCallsService() {
        let historyService = MockMovieSearchHistoryService(history: ["Arrival", "Dune"])
        let viewModel = MovieSearchViewModel(
            movieCatalogService: MockMovieCatalogService(),
            searchHistoryService: historyService,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )

        viewModel.clearSearchHistory()

        #expect(viewModel.searchHistory.isEmpty)
        #expect(historyService.didClearHistory)
    }
}

@MainActor
struct FavoritesViewModelTests {
    @Test
    func createRenameAndDeleteListUpdatesPublishedLists() {
        let repository = MockFavoritesRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(
                repository: repository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )
        let viewModel = FavoritesViewModel(favoritesStore: store)

        let created = viewModel.createList(named: "Weekend")
        #expect(created?.name == "Weekend")
        #expect(viewModel.lists.count == 1)

        let renamed = viewModel.renameList(listID: created!.id, name: "Weekend Picks")
        #expect(renamed)
        #expect(viewModel.lists.first?.name == "Weekend Picks")

        viewModel.deleteList(listID: created!.id)
        #expect(viewModel.lists.isEmpty)
    }

    @Test
    func storeAdoptsLegacyGuestListsIntoSignedInAccountScope() throws {
        let repository = MockFavoritesRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(
                repository: repository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )

        try sessionManager.signUp(email: "user@example.com", password: "secret1", confirmPassword: "secret1")

        #expect(repository.lastAdoptedUserIdentifier == sessionManager.currentUserIdentifier)
        #expect(repository.lastLegacyUserIdentifiers.contains("guest"))
        #expect(repository.lastLegacyUserIdentifiers.contains(sessionManager.guestUserIdentifier))
        #expect(repository.lastLegacyUserIdentifiers.contains("user@example.com"))
        _ = store
    }

    @Test
    func storeReturnsExistingListForDuplicateNameAndDoesNotCreateNewOne() {
        let repository = MockFavoritesRepository()
        repository.lists = [FavoriteList(id: UUID(), name: "Weekend", movies: [])]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(
                repository: repository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )

        let result = store.createList(named: " weekend ")

        #expect(result?.id == repository.lists.first?.id)
        #expect(repository.lists.count == 1)
    }

    @Test
    func storeRenameDuplicatePublishesDuplicateToast() {
        let first = FavoriteList(id: UUID(), name: "Weekend", movies: [])
        let second = FavoriteList(id: UUID(), name: "Sci-Fi", movies: [])
        let repository = MockFavoritesRepository()
        repository.lists = [first, second]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(
                repository: repository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )

        let didRename = store.renameList(listID: second.id, name: "Weekend")

        #expect(didRename == false)
        #expect(store.toastItem?.message == Localization.string("favorites.toast.duplicateList"))
    }

    @Test
    func storeRemoveFailurePublishesGenericToast() {
        let listID = UUID()
        let repository = MockFavoritesRepository(removeMovieError: FavoritesServiceError.persistenceFailure)
        repository.lists = [
            FavoriteList(
                id: listID,
                name: "Weekend",
                movies: [FavoriteMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)]
            )
        ]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(
                repository: repository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )

        store.remove(movieID: 7, from: listID)

        #expect(store.toastItem?.message == Localization.string("favorites.toast.genericError"))
        #expect(store.list(withID: listID)?.movies.count == 1)
    }

    @Test
    func storeDeleteFailurePublishesGenericToastAndKeepsList() {
        let list = FavoriteList(id: UUID(), name: "Weekend", movies: [])
        let repository = MockFavoritesRepository(deleteListError: FavoritesServiceError.persistenceFailure)
        repository.lists = [list]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(
                repository: repository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )

        store.deleteList(listID: list.id)

        #expect(store.toastItem?.message == Localization.string("favorites.toast.genericError"))
        #expect(store.list(withID: list.id) != nil)
    }

    @Test
    func storeMoveFailurePublishesGenericToast() {
        let sourceListID = UUID()
        let destinationListID = UUID()
        let repository = MockFavoritesRepository(moveMovieError: FavoritesServiceError.persistenceFailure)
        repository.lists = [
            FavoriteList(
                id: sourceListID,
                name: "Weekend",
                movies: [FavoriteMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)]
            ),
            FavoriteList(id: destinationListID, name: "Sci-Fi", movies: [])
        ]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(
                repository: repository,
                sessionManager: sessionManager
            ),
            sessionManager: sessionManager
        )

        store.move(movieID: 7, from: sourceListID, to: destinationListID)

        #expect(store.toastItem?.message == Localization.string("favorites.toast.genericError"))
        #expect(store.list(withID: sourceListID)?.movies.count == 1)
        #expect(store.list(withID: destinationListID)?.movies.isEmpty == true)
    }
}

@MainActor
struct AuthFormViewModelTests {
    @Test
    func signInViewModelPublishesLocalizedErrorOnFailure() {
        let authFormService = MockAuthFormService(signInError: AuthError.invalidCredentials)
        let viewModel = SignInViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.invalidCredentials"))
    }

    @Test
    func signUpViewModelPublishesLocalizedErrorOnFailure() {
        let authFormService = MockAuthFormService(signUpError: AuthError.accountExists)
        let viewModel = SignUpViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "secret1"
        viewModel.confirmPassword = "secret1"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.accountExists"))
    }

    @Test
    func signInViewModelFallsBackToGenericErrorForNonLocalizedFailure() {
        let authFormService = MockAuthFormService(signInError: TestError.unexpectedEndpoint)
        let viewModel = SignInViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.generic"))
    }

    @Test
    func changePasswordViewModelClearsFieldsOnSuccess() {
        let viewModel = ChangePasswordViewModel(authFormService: MockAuthFormService())
        viewModel.currentPassword = "oldpass"
        viewModel.newPassword = "newpass"
        viewModel.confirmPassword = "newpass"

        let result = viewModel.submit()

        #expect(result)
        #expect(viewModel.currentPassword.isEmpty)
        #expect(viewModel.newPassword.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
    }

    @Test
    func changePasswordViewModelPreservesFieldsOnFailure() {
        let viewModel = ChangePasswordViewModel(
            authFormService: MockAuthFormService(changePasswordError: AuthError.currentPasswordIncorrect)
        )
        viewModel.currentPassword = "oldpass"
        viewModel.newPassword = "newpass"
        viewModel.confirmPassword = "newpass"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.currentPassword == "oldpass")
        #expect(viewModel.newPassword == "newpass")
        #expect(viewModel.confirmPassword == "newpass")
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.currentPasswordIncorrect"))
    }
}

@MainActor
struct MovieDetailViewModelTests {
    @Test
    func loadPopulatesPayloadAndTrailerAvailability() async {
        let movie = Movie(
            id: 42,
            title: "Dune",
            overview: "Sci-fi epic",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2021-10-22",
            voteAverage: 8.1,
            genreIDs: [878]
        )
        let payload = MovieDetailPayload(
            detail: MovieDetail(
                id: 42,
                title: "Dune",
                overview: "Sci-fi epic",
                posterPath: "/poster.jpg",
                backdropPath: "/backdrop.jpg",
                releaseDate: "2021-10-22",
                voteAverage: 8.1,
                runtime: 155,
                imdbID: "tt1160419",
                genres: [MovieGenre(id: 878, name: "Science Fiction")]
            ),
            trailer: MovieVideo(key: "abc123", name: "Trailer", site: "YouTube", type: "Trailer", official: true),
            gallery: [MovieImageAsset(filePath: "/gallery.jpg")],
            directors: [MovieCrewMember(id: 1, name: "Denis Villeneuve", job: "Director", profilePath: nil, imdbID: nil)],
            cast: [MovieCastMember(id: 2, name: "Timothee Chalamet", character: "Paul", profilePath: nil, imdbID: nil)],
            streamingPlatforms: [MovieStreamingPlatform(id: 3, name: "Max", logoURL: nil, linkURL: nil)],
            similarMovies: [Movie(id: 99, title: "Arrival", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2016-11-11", voteAverage: 8.2, genreIDs: nil)]
        )
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: MockMovieDetailService(payload: payload)
        )

        await viewModel.load()

        #expect(viewModel.detail == payload.detail)
        #expect(viewModel.gallery == payload.gallery)
        #expect(viewModel.directors == payload.directors)
        #expect(viewModel.cast == payload.cast)
        #expect(viewModel.streamingPlatforms == payload.streamingPlatforms)
        #expect(viewModel.similarMovies == payload.similarMovies)
        #expect(viewModel.hasTrailer)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func loadFailurePublishesErrorToast() async {
        let movie = Movie(
            id: 17,
            title: "Blade Runner 2049",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2017-10-06",
            voteAverage: 8.0,
            genreIDs: nil
        )
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: MockMovieDetailService(error: TestLocalizedError(message: "Detail failed"))
        )

        await viewModel.load()

        #expect(viewModel.detail == nil)
        #expect(viewModel.errorMessage == "Detail failed")
        #expect(viewModel.toastItem?.message == "Detail failed")
        #expect(viewModel.isLoading == false)
    }

    @Test
    func presentTrailerWithoutTrailerPublishesMissingTrailerToast() {
        let movie = Movie(
            id: 5,
            title: "No Trailer",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: nil,
            genreIDs: nil
        )
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: MockMovieDetailService()
        )

        viewModel.presentTrailer()

        #expect(viewModel.isTrailerPresented == false)
        #expect(viewModel.toastItem?.message == Localization.string("movies.detail.trailer.missing"))
    }

    @Test
    func reloadForLanguageChangeRequestsPayloadAgain() async {
        let movie = Movie(
            id: 33,
            title: "Reload Test",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 7.4,
            genreIDs: nil
        )
        let payload = MovieDetailPayload(
            detail: MovieDetail(
                id: 33,
                title: "Reload Test",
                overview: nil,
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2024-01-01",
                voteAverage: 7.4,
                runtime: 120,
                imdbID: nil,
                genres: []
            ),
            trailer: nil,
            gallery: [],
            directors: [],
            cast: [],
            streamingPlatforms: [],
            similarMovies: []
        )
        let detailService = MockMovieDetailService(payload: payload)
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: detailService
        )

        await viewModel.loadIfNeeded()
        await viewModel.reloadForLanguageChange()

        #expect(await detailService.loadCount == 2)
    }
}

private final class MockMovieCatalogService: MovieCatalogServicing {
    var browseContent = MovieBrowseContent(
        trendingTodayMovies: [],
        trendingThisWeekMovies: [],
        popularMovies: [],
        upcomingMovies: [],
        nowPlayingMovies: [],
        topRatedMovies: []
    )
    var genres: [MovieGenre] = []
    var searchHandler: (String, Int) throws -> MovieResponse
    private(set) var searchRequests: [(String, Int)] = []

    init(searchHandler: @escaping (String, Int) throws -> MovieResponse = { _, _ in
        MovieResponse(page: 1, results: [], totalPages: 1)
    }) {
        self.searchHandler = searchHandler
    }

    func loadBrowseContent() async throws -> MovieBrowseContent {
        browseContent
    }

    func searchMovies(query: String, page: Int) async throws -> MovieResponse {
        searchRequests.append((query, page))
        try searchHandler(query, page)
    }

    func loadGenres() async throws -> [MovieGenre] {
        genres
    }

    func prefetchImages(for movies: [Movie]) async {}
}

private final class MockMovieSearchHistoryService: MovieSearchHistoryServicing {
    var history: [String] = []
    private(set) var didClearHistory = false

    init(history: [String] = []) {
        self.history = history
    }

    func loadSearchHistory() throws -> [String] {
        history
    }

    func saveSearch(_ query: String) throws {
        history.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        history.insert(query, at: 0)
    }

    func clearSearchHistory() throws {
        didClearHistory = true
        history = []
    }
}

private final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    var lists: [FavoriteList] = []
    var createListError: Error?
    var renameListError: Error?
    var deleteListError: Error?
    var addMovieError: Error?
    var removeMovieError: Error?
    var moveMovieError: Error?
    private(set) var lastAdoptedUserIdentifier: String?
    private(set) var lastLegacyUserIdentifiers: [String] = []

    init(
        createListError: Error? = nil,
        renameListError: Error? = nil,
        deleteListError: Error? = nil,
        addMovieError: Error? = nil,
        removeMovieError: Error? = nil,
        moveMovieError: Error? = nil
    ) {
        self.createListError = createListError
        self.renameListError = renameListError
        self.deleteListError = deleteListError
        self.addMovieError = addMovieError
        self.removeMovieError = removeMovieError
        self.moveMovieError = moveMovieError
    }

    func fetchLists(for userIdentifier: String) throws -> [FavoriteList] {
        lists
    }

    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) throws {
        lastAdoptedUserIdentifier = userIdentifier
        lastLegacyUserIdentifiers = legacyUserIdentifiers
    }

    func createList(named name: String, userIdentifier: String) throws -> FavoriteList {
        if let createListError { throw createListError }
        let list = FavoriteList(id: UUID(), name: name, movies: [])
        lists.append(list)
        return list
    }

    func renameList(listID: UUID, name: String, userIdentifier: String) throws {
        if let renameListError { throw renameListError }
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].name = name
    }

    func deleteList(listID: UUID, userIdentifier: String) throws {
        if let deleteListError { throw deleteListError }
        lists.removeAll { $0.id == listID }
    }

    func add(movie: Movie, to listID: UUID, userIdentifier: String) throws {
        if let addMovieError { throw addMovieError }
    }

    func remove(movieID: Int, from listID: UUID, userIdentifier: String) throws {
        if let removeMovieError { throw removeMovieError }
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].movies.removeAll { $0.id == movieID }
    }

    func remove(movieID: Int, userIdentifier: String) throws {}

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) throws {
        if let moveMovieError { throw moveMovieError }
    }
}

private final class MockKeychainService: KeychainServicing {
    private var storage: [String: Data] = [:]

    func data(for account: String) throws -> Data? {
        storage[account]
    }

    func save(_ data: Data, for account: String) throws {
        storage[account] = data
    }

    func delete(account: String) throws {
        storage.removeValue(forKey: account)
    }
}

private final class MockAuthSessionManager: AuthSessionManaging {
    var session: AuthSession?
    var isSignedIn: Bool { session != nil }
    var currentUserIdentifier: String { session?.userIdentifier ?? guestUserIdentifier }
    var guestUserIdentifier: String = "guest-device-id"
    var legacyUserIdentifiers: [String] {
        var identifiers = ["guest", guestUserIdentifier]
        if let session {
            identifiers.append(session.email.lowercased())
        }
        return identifiers.filter { $0 != currentUserIdentifier }
    }

    var signUpError: Error?
    var signInError: Error?
    var changePasswordError: Error?
    private(set) var didSignOut = false

    init(
        session: AuthSession? = AuthSession(email: "user@example.com", token: "token", userIdentifier: "user-id"),
        signUpError: Error? = nil,
        signInError: Error? = nil,
        changePasswordError: Error? = nil
    ) {
        self.session = session
        self.signUpError = signUpError
        self.signInError = signInError
        self.changePasswordError = changePasswordError
    }

    func signUp(email: String, password: String, confirmPassword: String) throws {
        if let signUpError { throw signUpError }
    }

    func signIn(email: String, password: String) throws {
        if let signInError { throw signInError }
        session = AuthSession(email: email, token: "token", userIdentifier: "user-id")
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws {
        if let changePasswordError { throw changePasswordError }
    }

    func signOut() {
        didSignOut = true
        session = nil
    }
}

private final class MockAuthFormService: AuthFormServicing {
    var signUpError: Error?
    var signInError: Error?
    var changePasswordError: Error?

    init(
        signUpError: Error? = nil,
        signInError: Error? = nil,
        changePasswordError: Error? = nil
    ) {
        self.signUpError = signUpError
        self.signInError = signInError
        self.changePasswordError = changePasswordError
    }

    func signIn(email: String, password: String) throws -> String {
        if let signInError { throw signInError }
        return Localization.string("auth.toast.signedIn")
    }

    func signUp(email: String, password: String, confirmPassword: String) throws -> String {
        if let signUpError { throw signUpError }
        return Localization.string("auth.toast.accountCreated")
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws -> String {
        if let changePasswordError { throw changePasswordError }
        return Localization.string("auth.changePassword.success")
    }
}

@MainActor
private final class MockMovieDetailService: MovieDetailServicing {
    var payload: MovieDetailPayload?
    var error: Error?
    private(set) var loadCount = 0

    init(payload: MovieDetailPayload? = nil, error: Error? = nil) {
        self.payload = payload
        self.error = error
    }

    func loadPayload(for movie: Movie) async throws -> MovieDetailPayload {
        loadCount += 1
        if let error { throw error }
        guard let payload else { throw TestError.unexpectedEndpoint }
        return payload
    }
}

private struct TestLocalizedError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

private enum TestError: Error {
    case invalidResponseType
    case unexpectedEndpoint
}
