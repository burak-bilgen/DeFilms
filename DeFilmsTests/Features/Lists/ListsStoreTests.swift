import XCTest
@testable import DeFilms

@MainActor
final class ListsStoreTests: XCTestCase {
    func test_ListsViewModel_initialState_usesStoreListsAndDerivedCount() {
        let store = SpyListsStore(
            lists: [
                MovieList(id: UUID(), name: "Weekend", movies: [ListedMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: nil, voteAverage: nil)]),
                MovieList(id: UUID(), name: "Sci-Fi", movies: [])
            ]
        )
        let viewModel = ListsViewModel(listsStore: store)

        XCTAssertEqual(viewModel.lists.count, 2)
        XCTAssertEqual(viewModel.totalMovieCount, 1)
    }

    func test_ListsViewModel_publishesUpdatedLists_whenStoreChanges() async {
        let firstList = MovieList(id: UUID(), name: "Weekend", movies: [])
        let secondList = MovieList(id: UUID(), name: "Sci-Fi", movies: [])
        let store = SpyListsStore(lists: [firstList])
        let viewModel = ListsViewModel(listsStore: store)

        store.publish(lists: [firstList, secondList])

        let didUpdate = await waitUntil {
            viewModel.lists.count == 2
        }

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(viewModel.lists.map(\.name), ["Weekend", "Sci-Fi"])
    }

    func test_ListsViewModel_createRenameAndDeleteList_updatesPublishedLists() async throws {
        let repository = MockListsRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )
        let viewModel = ListsViewModel(listsStore: store)

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

    func test_ListsStore_duplicateCreate_returnsExistingListWithoutCreatingNewOne() async {
        let repository = MockListsRepository()
        repository.lists = [MovieList(id: UUID(), name: "Weekend", movies: [])]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        let result = await store.createList(named: " weekend ")

        XCTAssertEqual(result?.id, repository.lists.first?.id)
        XCTAssertEqual(repository.lists.count, 1)
        XCTAssertEqual(repository.createListCallCount, 0)
    }

    func test_ListsStore_sameNormalizedRename_isNoOp() async {
        let list = MovieList(id: UUID(), name: "Café", movies: [])
        let repository = MockListsRepository()
        repository.lists = [list]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        let didRename = await store.renameList(listID: list.id, name: " cafe ")

        XCTAssertTrue(didRename)
        XCTAssertEqual(repository.renameListCallCount, 0)
        XCTAssertNil(store.toastItem)
    }

    func test_ListsStore_renameDuplicate_publishesDuplicateToast() async {
        let first = MovieList(id: UUID(), name: "Weekend", movies: [])
        let second = MovieList(id: UUID(), name: "Sci-Fi", movies: [])
        let repository = MockListsRepository()
        repository.lists = [first, second]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        let didRename = await store.renameList(listID: second.id, name: "Weekend")

        XCTAssertFalse(didRename)
        XCTAssertEqual(store.toastItem?.message, Localization.string("lists.toast.duplicateList"))
    }

    func test_ListsStore_removeFailure_publishesGenericToastAndKeepsMovie() async {
        let listID = UUID()
        let repository = MockListsRepository(removeMovieError: ListsServiceError.persistenceFailure)
        repository.lists = [
            MovieList(
                id: listID,
                name: "Weekend",
                movies: [ListedMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)]
            )
        ]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.remove(movieID: 7, from: listID)

        XCTAssertEqual(store.toastItem?.message, Localization.string("lists.toast.genericError"))
        XCTAssertEqual(store.list(withID: listID)?.movies.count, 1)
    }

    func test_ListsStore_deleteFailure_publishesGenericToastAndKeepsList() async {
        let list = MovieList(id: UUID(), name: "Weekend", movies: [])
        let repository = MockListsRepository(deleteListError: ListsServiceError.persistenceFailure)
        repository.lists = [list]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.deleteList(listID: list.id)

        XCTAssertEqual(store.toastItem?.message, Localization.string("lists.toast.genericError"))
        XCTAssertNotNil(store.list(withID: list.id))
    }

    func test_ListsStore_moveFailure_publishesGenericToast() async {
        let sourceListID = UUID()
        let destinationListID = UUID()
        let repository = MockListsRepository(moveMovieError: ListsServiceError.persistenceFailure)
        repository.lists = [
            MovieList(
                id: sourceListID,
                name: "Weekend",
                movies: [ListedMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)]
            ),
            MovieList(id: destinationListID, name: "Sci-Fi", movies: [])
        ]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.move(movieID: 7, from: sourceListID, to: destinationListID)

        XCTAssertEqual(store.toastItem?.message, Localization.string("lists.toast.genericError"))
        XCTAssertEqual(store.list(withID: sourceListID)?.movies.count, 1)
        XCTAssertTrue(store.list(withID: destinationListID)?.movies.isEmpty == true)
    }

    func test_ListsStore_addExistingMovie_isNoOp() async {
        let listID = UUID()
        let existingMovie = ListedMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)
        let repository = MockListsRepository()
        repository.lists = [MovieList(id: listID, name: "Weekend", movies: [existingMovie])]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.add(movie: existingMovie.asMovie, to: listID)

        XCTAssertEqual(repository.addMovieCallCount, 0)
    }

    func test_ListsStore_moveWithinSameList_isNoOp() async {
        let listID = UUID()
        let repository = MockListsRepository()
        repository.lists = [
            MovieList(
                id: listID,
                name: "Weekend",
                movies: [ListedMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)]
            )
        ]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.move(movieID: 7, from: listID, to: listID)

        XCTAssertEqual(repository.moveMovieCallCount, 0)
        XCTAssertNil(store.toastItem)
    }

    func test_ListsStore_moveToListThatAlreadyContainsMovie_removesSourceCopyAndShowsMergeToast() async {
        let sourceListID = UUID()
        let destinationListID = UUID()
        let movie = ListedMovie(id: 7, title: "Arrival", posterPath: nil, releaseDate: nil, voteAverage: nil)
        let repository = MockListsRepository()
        repository.lists = [
            MovieList(id: sourceListID, name: "X", movies: [movie]),
            MovieList(id: destinationListID, name: "Y", movies: [movie])
        ]
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.move(movieID: movie.id, from: destinationListID, to: sourceListID)

        XCTAssertEqual(store.toastItem?.message, Localization.string("lists.toast.movieMerged"))
        XCTAssertEqual(store.list(withID: sourceListID)?.movies.map(\.id), [movie.id])
        XCTAssertTrue(store.list(withID: destinationListID)?.movies.isEmpty == true)
    }

    func test_ListsStore_deleteMissingList_isNoOp() async {
        let repository = MockListsRepository()
        let sessionManager = AuthSessionManager(keychainService: MockKeychainService())
        let store = ListsStore(
            listsService: ListsService(repository: repository, sessionManager: sessionManager),
            sessionManager: sessionManager
        )

        await store.deleteList(listID: UUID())

        XCTAssertEqual(repository.deleteListCallCount, 0)
        XCTAssertNil(store.toastItem)
    }

    func test_MovieListDetailViewModel_initialState_exposesListDestinationsAndShareText() {
        let primaryListID = UUID()
        let primaryList = MovieList(
            id: primaryListID,
            name: "Weekend",
            movies: [ListedMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: "2021-10-22", voteAverage: nil)]
        )
        let destinationList = MovieList(id: UUID(), name: "Sci-Fi", movies: [])
        let store = SpyListsStore(lists: [primaryList, destinationList])
        let viewModel = MovieListDetailViewModel(listID: primaryListID, listsStore: store)
        let destinationOptions = viewModel.destinationOptions(for: 1)

        XCTAssertEqual(viewModel.list?.name, "Weekend")
        XCTAssertEqual(destinationOptions.map(\.list.name), ["Sci-Fi"])
        XCTAssertEqual(destinationOptions.map(\.alreadyContainsMovie), [false])
        XCTAssertTrue(viewModel.shareText?.contains("Dune (2021)") == true)
    }

    func test_MovieListDetailViewModel_destinationOptions_markListsThatAlreadyContainMovie() {
        let primaryListID = UUID()
        let duplicateMovie = ListedMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: "2021-10-22", voteAverage: nil)
        let store = SpyListsStore(
            lists: [
                MovieList(id: primaryListID, name: "X", movies: [duplicateMovie]),
                MovieList(id: UUID(), name: "Y", movies: [duplicateMovie]),
                MovieList(id: UUID(), name: "Z", movies: [])
            ]
        )
        let viewModel = MovieListDetailViewModel(listID: primaryListID, listsStore: store)

        let destinationOptions = viewModel.destinationOptions(for: duplicateMovie.id)

        XCTAssertEqual(destinationOptions.map(\.list.name), ["Y", "Z"])
        XCTAssertEqual(destinationOptions.map(\.alreadyContainsMovie), [true, false])
    }

    func test_MovieListDetailViewModel_updatesPublishedList_whenStorePublishesChange() async {
        let listID = UUID()
        let store = SpyListsStore(lists: [MovieList(id: listID, name: "Weekend", movies: [])])
        let viewModel = MovieListDetailViewModel(listID: listID, listsStore: store)

        store.publish(lists: [MovieList(id: listID, name: "Weekend Picks", movies: [])])

        let didUpdate = await waitUntil {
            viewModel.list?.name == "Weekend Picks"
        }

        XCTAssertTrue(didUpdate)
    }

    func test_MovieListDetailViewModel_removeAndMove_delegateToStore() async {
        let listID = UUID()
        let destinationListID = UUID()
        let store = SpyListsStore(
            lists: [
                MovieList(id: listID, name: "Weekend", movies: [ListedMovie(id: 1, title: "Dune", posterPath: nil, releaseDate: nil, voteAverage: nil)]),
                MovieList(id: destinationListID, name: "Sci-Fi", movies: [])
            ]
        )
        let viewModel = MovieListDetailViewModel(listID: listID, listsStore: store)

        await viewModel.remove(movieID: 1)
        await viewModel.move(movieID: 1, to: destinationListID)

        XCTAssertEqual(store.removedMovies.count, 1)
        XCTAssertEqual(store.movedMovies.count, 1)
        XCTAssertEqual(store.removedMovies.first?.0, 1)
        XCTAssertEqual(store.movedMovies.first?.2, destinationListID)
    }
}
