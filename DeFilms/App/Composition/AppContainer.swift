
import Foundation

final class AppContainer {
    let persistenceController: PersistenceController
    let keychainService: KeychainServicing
    let networkService: NetworkServiceProtocol
    let recentSearchRepository: RecentSearchRepository
    let favoritesRepository: FavoritesRepository
    let sessionManager: AuthSessionManager
    let toastCenter: ToastCenter
    let moviesFactory: MoviesFactory
    let favoritesFactory: FavoritesFactory
    let settingsFactory: SettingsFactory

    init(
        persistenceController: PersistenceController = PersistenceController(),
        keychainService: KeychainServicing? = nil,
        networkService: NetworkServiceProtocol? = nil,
        recentSearchRepository: RecentSearchRepository? = nil,
        favoritesRepository: FavoritesRepository? = nil,
        sessionManager: AuthSessionManager? = nil,
        toastCenter: ToastCenter = ToastCenter()
    ) {
        let resolvedKeychainService = keychainService ?? Self.makeDefaultKeychainService()
        let resolvedNetworkService = networkService ?? NetworkManager()
        let resolvedRecentSearchRepository = recentSearchRepository ?? RecentSearchRepository(
            persistenceController: persistenceController
        )
        let resolvedFavoritesRepository = favoritesRepository ?? FavoritesRepository(
            persistenceController: persistenceController
        )
        let resolvedSessionManager = sessionManager ?? AuthSessionManager(
            keychainService: resolvedKeychainService
        )

        self.persistenceController = persistenceController
        self.keychainService = resolvedKeychainService
        self.networkService = resolvedNetworkService
        self.recentSearchRepository = resolvedRecentSearchRepository
        self.favoritesRepository = resolvedFavoritesRepository
        self.sessionManager = resolvedSessionManager
        self.toastCenter = toastCenter
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
