import Combine
import Foundation
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
    var browseContentError: Error?
    var genresError: Error?
    var searchHandler: (String, Int) throws -> MovieResponse
    private(set) var searchRequests: [(String, Int)] = []
    private(set) var browseLoadCount = 0
    private(set) var genresLoadCount = 0
    private(set) var prefetchedMovieBatches: [[Movie]] = []

    init(searchHandler: @escaping (String, Int) throws -> MovieResponse = { _, _ in
        MovieResponse(page: 1, results: [], totalPages: 1)
    }) {
        self.searchHandler = searchHandler
    }

    func loadBrowseContent() async throws -> MovieBrowseContent {
        browseLoadCount += 1
        if let browseContentError { throw browseContentError }
        return browseContent
    }

    func searchMovies(query: String, page: Int) async throws -> MovieResponse {
        searchRequests.append((query, page))
        return try searchHandler(query, page)
    }

    func loadGenres() async throws -> [MovieGenre] {
        genresLoadCount += 1
        if let genresError { throw genresError }
        return genres
    }

    func prefetchImages(for movies: [Movie]) async {
        prefetchedMovieBatches.append(movies)
    }
}

final class MockMovieSearchHistoryService: MovieSearchHistoryServicing {
    var history: [String] = []
    var loadHistoryError: Error?
    var saveHistoryError: Error?
    var clearHistoryError: Error?
    private(set) var didClearHistory = false
    private(set) var savedQueries: [String] = []

    init(history: [String] = []) {
        self.history = history
    }

    func loadSearchHistory() async throws -> [String] {
        if let loadHistoryError { throw loadHistoryError }
        return history
    }

    func saveSearch(_ query: String) async throws {
        if let saveHistoryError { throw saveHistoryError }
        savedQueries.append(query)
        history.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        history.insert(query, at: 0)
    }

    func clearSearchHistory() async throws {
        if let clearHistoryError { throw clearHistoryError }
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

    func fetchLists(for userIdentifier: String) async throws -> [FavoriteList] {
        lists
    }

    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) async throws {
        lastAdoptedUserIdentifier = userIdentifier
        lastLegacyUserIdentifiers = legacyUserIdentifiers
    }

    func createList(named name: String, userIdentifier: String) async throws -> FavoriteList {
        if let createListError { throw createListError }
        let list = FavoriteList(id: UUID(), name: name, movies: [])
        lists.append(list)
        return list
    }

    func renameList(listID: UUID, name: String, userIdentifier: String) async throws {
        if let renameListError { throw renameListError }
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].name = name
    }

    func deleteList(listID: UUID, userIdentifier: String) async throws {
        if let deleteListError { throw deleteListError }
        lists.removeAll { $0.id == listID }
    }

    func add(movie: Movie, to listID: UUID, userIdentifier: String) async throws {
        if let addMovieError { throw addMovieError }
    }

    func remove(movieID: Int, from listID: UUID, userIdentifier: String) async throws {
        if let removeMovieError { throw removeMovieError }
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].movies.removeAll { $0.id == movieID }
    }

    func remove(movieID: Int, userIdentifier: String) async throws {}

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) async throws {
        if let moveMovieError { throw moveMovieError }
    }
}

@MainActor
final class SpyFavoritesStore: FavoritesStoreManaging {
    @Published private var storedLists: [FavoriteList]

    private(set) var createdNames: [String] = []
    private(set) var renamedLists: [(UUID, String)] = []
    private(set) var deletedListIDs: [UUID] = []
    private(set) var addedMovies: [(Movie, UUID)] = []
    private(set) var removedMovies: [(Int, UUID)] = []
    private(set) var movedMovies: [(Int, UUID, UUID)] = []

    var createListResult: FavoriteList?
    var renameListResult = true

    init(lists: [FavoriteList] = []) {
        self.storedLists = lists
    }

    var lists: [FavoriteList] {
        storedLists
    }

    var listsPublisher: AnyPublisher<[FavoriteList], Never> {
        $storedLists.eraseToAnyPublisher()
    }

    func createList(named name: String) async -> FavoriteList? {
        createdNames.append(name)
        if let createListResult {
            storedLists.append(createListResult)
            return createListResult
        }
        return nil
    }

    func renameList(listID: UUID, name: String) async -> Bool {
        renamedLists.append((listID, name))
        if renameListResult, let index = storedLists.firstIndex(where: { $0.id == listID }) {
            storedLists[index].name = name
        }
        return renameListResult
    }

    func deleteList(listID: UUID) async {
        deletedListIDs.append(listID)
        storedLists.removeAll { $0.id == listID }
    }

    func add(movie: Movie, to listID: UUID) async {
        addedMovies.append((movie, listID))
    }

    func remove(movieID: Int, from listID: UUID) async {
        removedMovies.append((movieID, listID))
        guard let index = storedLists.firstIndex(where: { $0.id == listID }) else { return }
        storedLists[index].movies.removeAll { $0.id == movieID }
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) async {
        movedMovies.append((movieID, sourceListID, destinationListID))
    }

    func list(withID listID: UUID) -> FavoriteList? {
        storedLists.first { $0.id == listID }
    }

    func publish(lists: [FavoriteList]) {
        storedLists = lists
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

@MainActor
func waitUntil(
    timeoutNanoseconds: UInt64 = 500_000_000,
    condition: @escaping @MainActor () -> Bool
) async -> Bool {
    let start = DispatchTime.now().uptimeNanoseconds

    while DispatchTime.now().uptimeNanoseconds - start < timeoutNanoseconds {
        if condition() {
            return true
        }
        await Task.yield()
    }

    return condition()
}
