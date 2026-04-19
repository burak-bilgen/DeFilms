import XCTest
@testable import DeFilms

@MainActor
final class FavoritesStoreTests: XCTestCase {
    func test_FavoritesViewModel_initialState_usesStoreListsAndDerivedCount() {
        let store = SpyFavoritesStore(
            lists: [
                FavoriteList(id: UUID(), name: "Weekend", movies: [FavoriteMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: nil, voteAverage: nil)]),
                FavoriteList(id: UUID(), name: "Sci-Fi", movies: [])
            ]
        )
        let viewModel = FavoritesViewModel(favoritesStore: store)

        XCTAssertEqual(viewModel.lists.count, 2)
        XCTAssertEqual(viewModel.totalMovieCount, 1)
    }

    func test_FavoritesViewModel_publishesUpdatedLists_whenStoreChanges() async {
        let firstList = FavoriteList(id: UUID(), name: "Weekend", movies: [])
        let secondList = FavoriteList(id: UUID(), name: "Sci-Fi", movies: [])
        let store = SpyFavoritesStore(lists: [firstList])
        let viewModel = FavoritesViewModel(favoritesStore: store)

        store.publish(lists: [firstList, secondList])

        let didUpdate = await waitUntil {
            viewModel.lists.count == 2
        }

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(viewModel.lists.map(\.name), ["Weekend", "Sci-Fi"])
    }

    func test_FavoritesViewModel_createRenameAndDeleteList_updatesPublishedLists() async throws {
        let repository = MockFavoritesRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )
        let viewModel = FavoritesViewModel(favoritesStore: store)

        let created = await viewModel.createList(named: "Weekend")

        XCTAssertEqual(created?.name, "Weekend")
        XCTAssertEqual(viewModel.lists.count, 1)

        let createdID = try XCTUnwrap(created?.id)
        let renamed = await viewModel.renameList(listID: createdID, name: "Weekend Picks")

        XCTAssertTrue(renamed)
        XCTAssertEqual(viewModel.lists.first?.name, "Weekend Picks")

        await viewModel.deleteList(listID: createdID)

        XCTAssertTrue(viewModel.lists.isEmpty)
    }

    func test_FavoritesStore_adoptsLegacyGuestListsIntoSignedInAccountScope() async throws {
        let repository = MockFavoritesRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        try sessionManager.signUp(email: "user@example.com", password: "secret1", confirmPassword: "secret1")

        let didAdopt = await waitUntil {
            repository.lastAdoptedUserIdentifier == sessionManager.currentUserIdentifier
        }

        XCTAssertTrue(didAdopt)
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("guest"))
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains(sessionManager.guestUserIdentifier))
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("user@example.com"))
        _ = store
    }

    func test_FavoritesStore_duplicateCreate_returnsExistingListWithoutCreatingNewOne() async {
        let repository = MockFavoritesRepository()
        repository.lists = [FavoriteList(id: UUID(), name: "Weekend", movies: [])]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        let result = await store.createList(named: " weekend ")

        XCTAssertEqual(result?.id, repository.lists.first?.id)
        XCTAssertEqual(repository.lists.count, 1)
        XCTAssertEqual(repository.createListCallCount, 0)
    }

    func test_FavoritesStore_sameNormalizedRename_isNoOp() async {
        let list = FavoriteList(id: UUID(), name: "Café", movies: [])
        let repository = MockFavoritesRepository()
        repository.lists = [list]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        let didRename = await store.renameList(listID: list.id, name: " cafe ")

        XCTAssertTrue(didRename)
        XCTAssertEqual(repository.renameListCallCount, 0)
        XCTAssertNil(store.toastItem)
    }

    func test_FavoritesStore_renameDuplicate_publishesDuplicateToast() async {
        let first = FavoriteList(id: UUID(), name: "Weekend", movies: [])
        let second = FavoriteList(id: UUID(), name: "Sci-Fi", movies: [])
        let repository = MockFavoritesRepository()
        repository.lists = [first, second]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        let didRename = await store.renameList(listID: second.id, name: "Weekend")

        XCTAssertFalse(didRename)
        XCTAssertEqual(store.toastItem?.message, Localization.string("favorites.toast.duplicateList"))
    }

    func test_FavoritesStore_removeFailure_publishesGenericToastAndKeepsMovie() async {
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

        await store.remove(movieID: 7, from: listID)

        XCTAssertEqual(store.toastItem?.message, Localization.string("favorites.toast.genericError"))
        XCTAssertEqual(store.list(withID: listID)?.movies.count, 1)
    }

    func test_FavoritesStore_deleteFailure_publishesGenericToastAndKeepsList() async {
        let list = FavoriteList(id: UUID(), name: "Weekend", movies: [])
        let repository = MockFavoritesRepository(deleteListError: FavoritesServiceError.persistenceFailure)
        repository.lists = [list]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.deleteList(listID: list.id)

        XCTAssertEqual(store.toastItem?.message, Localization.string("favorites.toast.genericError"))
        XCTAssertNotNil(store.list(withID: list.id))
    }

    func test_FavoritesStore_moveFailure_publishesGenericToast() async {
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

        await store.move(movieID: 7, from: sourceListID, to: destinationListID)

        XCTAssertEqual(store.toastItem?.message, Localization.string("favorites.toast.genericError"))
        XCTAssertEqual(store.list(withID: sourceListID)?.movies.count, 1)
        XCTAssertTrue(store.list(withID: destinationListID)?.movies.isEmpty == true)
    }

    func test_FavoritesStore_addExistingMovie_isNoOp() async {
        let listID = UUID()
        let existingMovie = FavoriteMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)
        let repository = MockFavoritesRepository()
        repository.lists = [FavoriteList(id: listID, name: "Weekend", movies: [existingMovie])]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.add(movie: existingMovie.asMovie, to: listID)

        XCTAssertEqual(repository.addMovieCallCount, 0)
    }

    func test_FavoritesStore_moveWithinSameList_isNoOp() async {
        let listID = UUID()
        let repository = MockFavoritesRepository()
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

        await store.move(movieID: 7, from: listID, to: listID)

        XCTAssertEqual(repository.moveMovieCallCount, 0)
        XCTAssertNil(store.toastItem)
    }

    func test_FavoritesStore_moveToListThatAlreadyContainsMovie_removesSourceCopyAndShowsMergeToast() async {
        let sourceListID = UUID()
        let destinationListID = UUID()
        let movie = FavoriteMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)
        let repository = MockFavoritesRepository()
        repository.lists = [
            FavoriteList(id: sourceListID, name: "X", movies: [movie]),
            FavoriteList(id: destinationListID, name: "Y", movies: [movie])
        ]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.move(movieID: movie.id, from: destinationListID, to: sourceListID)

        XCTAssertEqual(store.toastItem?.message, Localization.string("favorites.toast.movieMerged"))
        XCTAssertEqual(store.list(withID: sourceListID)?.movies.map(\.id), [movie.id])
        XCTAssertTrue(store.list(withID: destinationListID)?.movies.isEmpty == true)
    }

    func test_FavoritesStore_deleteMissingList_isNoOp() async {
        let repository = MockFavoritesRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = FavoritesStore(
            favoritesService: FavoritesService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.deleteList(listID: UUID())

        XCTAssertEqual(repository.deleteListCallCount, 0)
        XCTAssertNil(store.toastItem)
    }

    func test_FavoriteListDetailViewModel_initialState_exposesListDestinationsAndShareText() {
        let primaryListID = UUID()
        let primaryList = FavoriteList(
            id: primaryListID,
            name: "Weekend",
            movies: [FavoriteMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: "2021-10-22", voteAverage: nil)]
        )
        let destinationList = FavoriteList(id: UUID(), name: "Sci-Fi", movies: [])
        let store = SpyFavoritesStore(lists: [primaryList, destinationList])
        let viewModel = FavoriteListDetailViewModel(listID: primaryListID, favoritesStore: store)
        let destinationOptions = viewModel.destinationOptions(for: 1)

        XCTAssertEqual(viewModel.list?.name, "Weekend")
        XCTAssertEqual(destinationOptions.map(\.list.name), ["Sci-Fi"])
        XCTAssertEqual(destinationOptions.map(\.alreadyContainsMovie), [false])
        XCTAssertTrue(viewModel.shareText?.contains("Dune (2021)") == true)
    }

    func test_FavoriteListDetailViewModel_destinationOptions_markListsThatAlreadyContainMovie() {
        let primaryListID = UUID()
        let duplicateMovie = FavoriteMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: "2021-10-22", voteAverage: nil)
        let store = SpyFavoritesStore(
            lists: [
                FavoriteList(id: primaryListID, name: "X", movies: [duplicateMovie]),
                FavoriteList(id: UUID(), name: "Y", movies: [duplicateMovie]),
                FavoriteList(id: UUID(), name: "Z", movies: [])
            ]
        )
        let viewModel = FavoriteListDetailViewModel(listID: primaryListID, favoritesStore: store)

        let destinationOptions = viewModel.destinationOptions(for: duplicateMovie.id)

        XCTAssertEqual(destinationOptions.map(\.list.name), ["Y", "Z"])
        XCTAssertEqual(destinationOptions.map(\.alreadyContainsMovie), [true, false])
    }

    func test_FavoriteListDetailViewModel_updatesPublishedList_whenStorePublishesChange() async {
        let listID = UUID()
        let store = SpyFavoritesStore(lists: [FavoriteList(id: listID, name: "Weekend", movies: [])])
        let viewModel = FavoriteListDetailViewModel(listID: listID, favoritesStore: store)

        store.publish(lists: [FavoriteList(id: listID, name: "Weekend Picks", movies: [])])

        let didUpdate = await waitUntil {
            viewModel.list?.name == "Weekend Picks"
        }

        XCTAssertTrue(didUpdate)
    }

    func test_FavoriteListDetailViewModel_removeAndMove_delegateToStore() async {
        let listID = UUID()
        let destinationListID = UUID()
        let store = SpyFavoritesStore(
            lists: [
                FavoriteList(id: listID, name: "Weekend", movies: [FavoriteMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: nil, voteAverage: nil)]),
                FavoriteList(id: destinationListID, name: "Sci-Fi", movies: [])
            ]
        )
        let viewModel = FavoriteListDetailViewModel(listID: listID, favoritesStore: store)

        await viewModel.remove(movieID: 1)
        await viewModel.move(movieID: 1, to: destinationListID)

        XCTAssertEqual(store.removedMovies.count, 1)
        XCTAssertEqual(store.movedMovies.count, 1)
        XCTAssertEqual(store.removedMovies.first?.0, 1)
        XCTAssertEqual(store.movedMovies.first?.2, destinationListID)
    }
}
