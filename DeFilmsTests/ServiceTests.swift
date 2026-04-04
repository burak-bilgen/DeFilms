import XCTest
@testable import DeFilms

@MainActor
final class FavoritesServiceTests: XCTestCase {
    func testCreateListRejectsDuplicateNamesCaseInsensitively() throws {
        let service = FavoritesService(
            repository: MockFavoritesRepository(),
            sessionManager: MockAuthSessionManager()
        )
        let existing = [FavoriteList(id: UUID(), name: "Weekend", movies: [])]

        XCTAssertThrowsError(
            try service.createList(named: " weekend ", existingLists: existing)
        ) { error in
            XCTAssertEqual(error as? FavoritesServiceError, .duplicateListName)
        }
    }

    func testLoadListsAdoptsLegacyIdentifiersBeforeFetching() throws {
        let repository = MockFavoritesRepository()
        repository.lists = [FavoriteList(id: UUID(), name: "Sci-Fi", movies: [])]
        let sessionManager = MockAuthSessionManager(
            session: AuthSession(email: "user@example.com", token: "token", userIdentifier: "user-id")
        )
        let service = FavoritesService(repository: repository, sessionManager: sessionManager)

        let lists = try service.loadLists()

        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(repository.lastAdoptedUserIdentifier, "user-id")
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("guest"))
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("guest-device-id"))
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("user@example.com"))
    }
}

@MainActor
final class AuthFormServiceTests: XCTestCase {
    func testSignInReturnsLocalizedSuccessMessage() throws {
        let sessionManager = MockAuthSessionManager()
        let service = AuthFormService(sessionManager: sessionManager)

        let message = try service.signIn(email: "user@example.com", password: "password")

        XCTAssertEqual(message, Localization.string("auth.toast.signedIn"))
        XCTAssertEqual(sessionManager.session?.email, "user@example.com")
    }

    func testChangePasswordPropagatesUnderlyingError() {
        let sessionManager = MockAuthSessionManager(changePasswordError: AuthError.invalidPasswordFormat)
        let service = AuthFormService(sessionManager: sessionManager)

        XCTAssertThrowsError(
            try service.changePassword(
                currentPassword: "old",
                newPassword: "new",
                confirmPassword: "new"
            )
        ) { error in
            XCTAssertEqual(error as? AuthError, .invalidPasswordFormat)
        }
    }
}

@MainActor
final class MovieDetailServiceTests: XCTestCase {
    func testLoadPayloadCombinesPrimaryDetailSections() async throws {
        let movie = Movie(
            id: 42,
            title: "Arrival",
            overview: "Test",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2016-11-11",
            voteAverage: 8.2,
            genreIDs: [18]
        )
        let network = MockMovieDetailNetworkService()
        network.detail = MovieDetail(
            id: 42,
            title: "Arrival",
            overview: "Expanded",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2016-11-11",
            voteAverage: 8.4,
            runtime: 116,
            imdbID: "tt2543164",
            genres: [MovieGenre(id: 18, name: "Drama")]
        )
        network.images = MovieImageResponse(
            backdrops: [MovieImageAsset(filePath: "/gallery.jpg")],
            posters: []
        )
        network.credits = MovieCreditsResponse(
            cast: [
                MovieCastMember(id: 1, name: "Amy Adams", character: "Louise", profilePath: nil),
                MovieCastMember(id: 2, name: "Jeremy Renner", character: "Ian", profilePath: nil)
            ],
            crew: [
                MovieCrewMember(id: 3, name: "Denis Villeneuve", job: "Director", profilePath: nil)
            ]
        )
        network.videos = MovieVideoResponse(
            results: [MovieVideo(key: "abc", name: "Trailer", site: "YouTube", type: "Trailer", official: true)]
        )
        network.watchProviders = MovieWatchProvidersResponse(
            id: 42,
            results: [
                "US": MovieWatchProviderRegion(
                    link: URL(string: "https://example.com"),
                    flatrate: [MovieWatchProvider(providerID: 10, providerName: "Netflix", logoPath: "/logo.png")],
                    rent: nil,
                    buy: nil
                )
            ]
        )
        network.similar = MovieResponse(
            page: 1,
            results: [
                movie,
                Movie(id: 99, title: "Sicario", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2015-01-01", voteAverage: 7.6, genreIDs: nil)
            ],
            totalPages: 1
        )
        network.personExternalIDs = [
            1: PersonExternalIDsResponse(imdbID: "nm0010736"),
            2: PersonExternalIDsResponse(imdbID: "nm0719637"),
            3: PersonExternalIDsResponse(imdbID: "nm0898288")
        ]

        let service = TMDBMovieDetailService(
            networkService: network,
            imagePrefetcher: MockMovieImagePrefetcher()
        )

        let payload = try await service.loadPayload(for: movie)

        XCTAssertEqual(payload.detail.title, "Arrival")
        XCTAssertEqual(payload.gallery.count, 1)
        XCTAssertEqual(payload.cast.count, 2)
        XCTAssertEqual(payload.directors.count, 1)
        XCTAssertEqual(payload.trailer?.key, "abc")
        XCTAssertEqual(payload.streamingPlatforms.first?.name, "Netflix")
        XCTAssertEqual(payload.similarMovies.map(\.id), [99])
        XCTAssertEqual(payload.directors.first?.imdbID, "nm0898288")
        XCTAssertEqual(payload.cast.first?.imdbID, "nm0010736")
    }
}

private final class MockMovieDetailNetworkService: NetworkServiceProtocol {
    var detail: MovieDetail?
    var images: MovieImageResponse?
    var credits: MovieCreditsResponse?
    var videos: MovieVideoResponse?
    var watchProviders: MovieWatchProvidersResponse?
    var similar: MovieResponse?
    var personExternalIDs: [Int: PersonExternalIDsResponse] = [:]

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
            case let .personExternalIDs(personID):
                value = try unwrap(personExternalIDs[personID])
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

private actor MockMovieImagePrefetcher: MovieImagePrefetching {
    func prefetch(urls: [URL]) async {}
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

    func renameList(listID: UUID, name: String, userIdentifier: String) throws {}
    func deleteList(listID: UUID, userIdentifier: String) throws {}
    func add(movie: Movie, to listID: UUID, userIdentifier: String) throws {}
    func remove(movieID: Int, from listID: UUID, userIdentifier: String) throws {}
    func remove(movieID: Int, userIdentifier: String) throws {}
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) throws {}
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
}

private enum ServiceTestError: Error {
    case invalidResponseType
    case unexpectedEndpoint
    case missingStub
}
