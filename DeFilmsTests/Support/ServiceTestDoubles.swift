import XCTest
@testable import DeFilms

final class ServiceTestFavoritesRepository: FavoritesRepositoryProtocol {
    var lists: [FavoriteList] = []
    private(set) var lastAdoptedUserIdentifier: String?
    private(set) var lastLegacyUserIdentifiers: [String] = []

    func fetchLists(for userIdentifier: String) async throws -> [FavoriteList] {
        lists
    }

    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) async throws {
        lastAdoptedUserIdentifier = userIdentifier
        lastLegacyUserIdentifiers = legacyUserIdentifiers
    }

    func createList(named name: String, userIdentifier: String) async throws -> FavoriteList {
        let list = FavoriteList(id: UUID(), name: name, movies: [])
        lists.append(list)
        return list
    }

    func renameList(listID: UUID, name: String, userIdentifier: String) async throws {}
    func deleteList(listID: UUID, userIdentifier: String) async throws {}
    func deleteLists(for userIdentifiers: [String]) async throws {}
    func add(movie: Movie, to listID: UUID, userIdentifier: String) async throws {}
    func remove(movieID: Int, from listID: UUID, userIdentifier: String) async throws {}
    func remove(movieID: Int, userIdentifier: String) async throws {}
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) async throws {}
}

final class ServiceTestAuthSessionManager: AuthSessionManaging {
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
        session = nil
    }

    func deleteSignedInAccount() throws {
        session = nil
    }
}

final class MockMovieDetailNetworkService: NetworkServiceProtocol {
    var detail: MovieDetail?
    var images: MovieImageResponse?
    var credits: MovieCreditsResponse?
    var videos: MovieVideoResponse?
    var watchProviders: MovieWatchProvidersResponse?
    var similar: MovieResponse?

    func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let value: Any

        switch endpoint {
        case let endpoint as TMDBEndpoint:
            switch endpoint {
            case .movieDetails:
                value = try unwrap(detail)
            case .movieImages:
                value = try unwrap(images)
            case .movieCredits:
                value = try unwrap(credits)
            case .movieVideos:
                value = try unwrap(videos)
            case .movieWatchProviders:
                value = try unwrap(watchProviders)
            case .similarMovies:
                value = try unwrap(similar)
            default:
                throw ServiceTestError.unexpectedEndpoint
            }
        default:
            throw ServiceTestError.unexpectedEndpoint
        }

        guard let typedValue = value as? T else {
            throw ServiceTestError.invalidResponseType
        }
        return typedValue
    }

    private func unwrap<Value>(_ value: Value?) throws -> Value {
        guard let value else { throw ServiceTestError.missingStub }
        return value
    }
}

actor MockMovieImagePrefetcher: MovieImagePrefetching {
    func prefetch(urls: [URL]) async {}
}

enum ServiceTestError: Error {
    case invalidResponseType
    case unexpectedEndpoint
    case missingStub
}
