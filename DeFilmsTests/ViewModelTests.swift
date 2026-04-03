import Foundation
import Testing
@testable import DeFilms

@MainActor
struct MovieSearchViewModelTests {
    @Test
    func emptyQueryShowsValidationError() async {
        let viewModel = MovieSearchViewModel(
            networkService: MockNetworkService(),
            recentSearchRepository: MockRecentSearchRepository(),
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
        let repository = MockRecentSearchRepository()
        let viewModel = MovieSearchViewModel(
            networkService: MockNetworkService { endpoint in
                guard endpoint.path == "/search/movie" else {
                    throw TestError.unexpectedEndpoint
                }

                return MovieResponse(results: [movie])
            },
            recentSearchRepository: repository,
            sessionManager: AuthSessionManager(keychainService: MockKeychainService())
        )
        viewModel.query = " Arrival "

        await viewModel.search()

        #expect(viewModel.screenState == .loadedResults)
        #expect(viewModel.filteredSearchResults == [movie])
        #expect(repository.history == ["Arrival"])
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
        #expect(viewModel.errorMessage == Localization.string("auth.error.invalidCredentials"))
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
        #expect(viewModel.successMessage == Localization.string("auth.changePassword.success"))
        #expect(viewModel.currentPassword.isEmpty)
        #expect(viewModel.newPassword.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
    }
}

private struct MockNetworkService: NetworkServiceProtocol {
    var handler: (Endpoint) throws -> Any = { _ in MovieResponse(results: []) }

    func request<T>(endpoint: Endpoint) async throws -> T where T : Decodable {
        let value = try handler(endpoint)
        guard let typedValue = value as? T else {
            throw TestError.invalidResponseType
        }
        return typedValue
    }
}

private final class MockRecentSearchRepository: RecentSearchRepositoryProtocol {
    var history: [String] = []

    func fetchRecentSearches(for userIdentifier: String, limit: Int) throws -> [String] {
        Array(history.prefix(limit))
    }

    func addSearch(_ query: String, for userIdentifier: String, limit: Int) throws {
        history.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        history.insert(query, at: 0)
        history = Array(history.prefix(limit))
    }
}

private final class MockFavoritesRepository: FavoritesRepositoryProtocol {
    var lists: [FavoriteList] = []

    func fetchLists(for userIdentifier: String) throws -> [FavoriteList] {
        lists
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
    var currentUserIdentifier: String { session?.email ?? "guest" }

    var signUpError: Error?
    var signInError: Error?
    var changePasswordError: Error?
    private(set) var didSignOut = false

    init(
        session: AuthSession? = AuthSession(email: "user@example.com", token: "token"),
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
        session = AuthSession(email: email, token: "token")
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
