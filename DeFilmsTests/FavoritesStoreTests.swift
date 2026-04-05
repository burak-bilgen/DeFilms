import Foundation
import Testing
@testable import DeFilms

@MainActor
struct FavoritesViewModelTests {
    @Test
    func createRenameAndDeleteListUpdatesPublishedLists() {
        let repository = MockFavoritesRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
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
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
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
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
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
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
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
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
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
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
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
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        store.move(movieID: 7, from: sourceListID, to: destinationListID)

        #expect(store.toastItem?.message == Localization.string("favorites.toast.genericError"))
        #expect(store.list(withID: sourceListID)?.movies.count == 1)
        #expect(store.list(withID: destinationListID)?.movies.isEmpty == true)
    }
}
