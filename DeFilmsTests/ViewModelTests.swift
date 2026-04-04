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
}

@MainActor
struct FavoritesViewModelTests {
    @Test
    func createRenameAndDeleteListUpdatesPublishedLists() {
        let repository = MockFavoritesRepository()
        let store = FavoritesStore(
            repository: repository,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
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
        let store = FavoritesStore(repository: repository, sessionManager: sessionManager)

        try sessionManager.signUp(email: "user@example.com", password: "secret1", confirmPassword: "secret1")

        #expect(repository.lastAdoptedUserIdentifier == sessionManager.currentUserIdentifier)
        #expect(repository.lastLegacyUserIdentifiers.contains("guest"))
        #expect(repository.lastLegacyUserIdentifiers.contains(sessionManager.guestUserIdentifier))
        #expect(repository.lastLegacyUserIdentifiers.contains("user@example.com"))
        _ = store
    }
}

@MainActor
struct AuthFormViewModelTests {
    @Test
    func signInViewModelPublishesLocalizedErrorOnFailure() {
        let sessionManager = MockAuthSessionManager(signInError: AuthError.invalidCredentials)
        let viewModel = SignInViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"

        let result = viewModel.submit(using: sessionManager)

        #expect(result == false)
    }

    @Test
    func changePasswordViewModelClearsFieldsOnSuccess() {
        let sessionManager = MockAuthSessionManager()
        let viewModel = ChangePasswordViewModel()
        viewModel.currentPassword = "oldpass"
        viewModel.newPassword = "newpass"
        viewModel.confirmPassword = "newpass"

        let result = viewModel.submit(using: sessionManager)

        #expect(result)
        #expect(viewModel.currentPassword.isEmpty)
        #expect(viewModel.newPassword.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
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

    init(searchHandler: @escaping (String, Int) throws -> MovieResponse = { _, _ in
        MovieResponse(page: 1, results: [], totalPages: 1)
    }) {
        self.searchHandler = searchHandler
    }

    func loadBrowseContent() async throws -> MovieBrowseContent {
        browseContent
    }

    func searchMovies(query: String, page: Int) async throws -> MovieResponse {
        try searchHandler(query, page)
    }

    func loadGenres() async throws -> [MovieGenre] {
        genres
    }

    func prefetchImages(for movies: [Movie]) async {}
}

private final class MockMovieSearchHistoryService: MovieSearchHistoryServicing {
    var history: [String] = []

    func loadSearchHistory() throws -> [String] {
        history
    }

    func saveSearch(_ query: String) throws {
        history.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        history.insert(query, at: 0)
    }

    func clearSearchHistory() throws {
        history = []
    }
}

private final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    var lists: [FavoriteList] = []
    private(set) var lastAdoptedUserIdentifier: String?
    private(set) var lastLegacyUserIdentifiers: [String] = []

    func fetchLists(for userIdentifier: String) throws -> [FavoriteList] {
        lists
    }

    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) throws {
        lastAdoptedUserIdentifier = userIdentifier
        lastLegacyUserIdentifiers = legacyUserIdentifiers
    }

    func createList(named name: String, userIdentifier: String) throws -> FavoriteList {
        let list = FavoriteList(id: UUID(), name: name, movies: [])
        lists.append(list)
        return list
    }

    func renameList(listID: UUID, name: String, userIdentifier: String) throws {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].name = name
    }

    func deleteList(listID: UUID, userIdentifier: String) throws {
        lists.removeAll { $0.id == listID }
    }

    func add(movie: Movie, to listID: UUID, userIdentifier: String) throws {}

    func remove(movieID: Int, from listID: UUID, userIdentifier: String) throws {}

    func remove(movieID: Int, userIdentifier: String) throws {}

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) throws {}
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

private enum TestError: Error {
    case invalidResponseType
    case unexpectedEndpoint
}
