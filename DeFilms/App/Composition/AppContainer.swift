
import Foundation

@MainActor
final class AppContainer {
    let persistenceController: PersistenceController
    let keychainService: KeychainServicing
    let networkService: NetworkServiceProtocol
    let recentSearchRepository: RecentSearchRepository
    let favoritesRepository: FavoritesRepository
    let sessionManager: AuthSessionManager
    let toastCenter: ToastCenter
    let movieStatusStore: UserMovieStatusStore
    let moviesFactory: MoviesFactory
    let favoritesFactory: FavoritesFactory
    let settingsFactory: SettingsFactory

    init(
        persistenceController: PersistenceController? = nil,
        keychainService: KeychainServicing? = nil,
        networkService: NetworkServiceProtocol? = nil,
        recentSearchRepository: RecentSearchRepository? = nil,
        favoritesRepository: FavoritesRepository? = nil,
        sessionManager: AuthSessionManager? = nil,
        movieStatusStore: UserMovieStatusStore? = nil,
        toastCenter: ToastCenter? = nil
    ) {
        let resolvedPersistenceController = persistenceController ?? PersistenceController()
        let resolvedKeychainService = keychainService ?? Self.makeDefaultKeychainService()
        let resolvedNetworkService = networkService ?? NetworkManager()
        let resolvedRecentSearchRepository = recentSearchRepository ?? RecentSearchRepository(
            persistenceController: resolvedPersistenceController
        )
        let resolvedFavoritesRepository = favoritesRepository ?? FavoritesRepository(
            persistenceController: resolvedPersistenceController
        )
        let resolvedSessionManager = sessionManager ?? AuthSessionManager(
            keychainService: resolvedKeychainService
        )
        let resolvedMovieStatusStore = movieStatusStore ?? UserMovieStatusStore()
        let resolvedToastCenter = toastCenter ?? ToastCenter()

        self.persistenceController = resolvedPersistenceController
        self.keychainService = resolvedKeychainService
        self.networkService = resolvedNetworkService
        self.recentSearchRepository = resolvedRecentSearchRepository
        self.favoritesRepository = resolvedFavoritesRepository
        self.sessionManager = resolvedSessionManager
        self.toastCenter = resolvedToastCenter
        self.movieStatusStore = resolvedMovieStatusStore
        self.moviesFactory = MoviesFactory(
            networkService: resolvedNetworkService,
            recentSearchRepository: resolvedRecentSearchRepository,
            sessionManager: resolvedSessionManager
        )
        self.favoritesFactory = FavoritesFactory(
            favoritesRepository: resolvedFavoritesRepository,
            sessionManager: resolvedSessionManager
        )
        self.settingsFactory = SettingsFactory(
            sessionManager: resolvedSessionManager,
            favoritesRepository: resolvedFavoritesRepository,
            recentSearchRepository: resolvedRecentSearchRepository
        )
    }

    private static func makeDefaultKeychainService() -> KeychainServicing {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("UITest.UseInMemoryKeychain") {
            return InMemoryKeychainService()
        }
        #endif

        return KeychainService()
    }
}
