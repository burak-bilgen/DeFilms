import Foundation
import Testing
@testable import DeFilms

final class MockMovieCatalogService: MovieCatalogServicing {
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
        return try searchHandler(query, page)
    }

    func loadGenres() async throws -> [MovieGenre] {
        genres
    }

    func prefetchImages(for movies: [Movie]) async {}
}

final class MockMovieSearchHistoryService: MovieSearchHistoryServicing {
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

final class MockFavoritesRepository: FavoritesRepositoryProtocol {
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

final class MockKeychainService: KeychainServicing {
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

final class MockAuthSessionManager: AuthSessionManaging {
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

final class MockAuthFormService: AuthFormServicing {
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
final class MockMovieDetailService: MovieDetailServicing {
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

struct TestLocalizedError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

enum TestError: Error {
    case invalidResponseType
    case unexpectedEndpoint
}
