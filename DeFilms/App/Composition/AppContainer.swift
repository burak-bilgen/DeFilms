
import Foundation

@MainActor
final class AppContainer {
    let persistenceController: PersistenceController
    let keychainService: KeychainServicing
    let networkService: NetworkServiceProtocol
    let recentSearchRepository: RecentSearchRepository
    let listsRepository: ListsRepository
    let sessionManager: AuthSessionManager
    let toastCenter: ToastCenter
    let movieStatusStore: UserMovieStatusStore
    let moviesFactory: MoviesFactory
    let listsFactory: ListsFactory
    let settingsFactory: SettingsFactory

    init(
        persistenceController: PersistenceController? = nil,
        keychainService: KeychainServicing? = nil,
        networkService: NetworkServiceProtocol? = nil,
        recentSearchRepository: RecentSearchRepository? = nil,
        listsRepository: ListsRepository? = nil,
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
        let resolvedListsRepository = listsRepository ?? ListsRepository(
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
        self.listsRepository = resolvedListsRepository
        self.sessionManager = resolvedSessionManager
        self.toastCenter = resolvedToastCenter
        self.movieStatusStore = resolvedMovieStatusStore
        self.moviesFactory = MoviesFactory(
            networkService: resolvedNetworkService,
            recentSearchRepository: resolvedRecentSearchRepository,
            sessionManager: resolvedSessionManager
        )
        self.listsFactory = ListsFactory(
            listsRepository: resolvedListsRepository,
            sessionManager: resolvedSessionManager
        )
        self.settingsFactory = SettingsFactory(
            sessionManager: resolvedSessionManager,
            listsRepository: resolvedListsRepository,
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
