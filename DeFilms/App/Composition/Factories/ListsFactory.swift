
import Foundation

final class ListsFactory {
    private let listsService: ListsServicing
    private let sessionManager: AuthSessionManager

    init(
        listsRepository: ListsRepositoryProtocol,
        sessionManager: AuthSessionManager
    ) {
        self.listsService = ListsService(
            repository: listsRepository,
            sessionManager: sessionManager
        )
        self.sessionManager = sessionManager
    }

    func makeStore() -> ListsStore {
        ListsStore(
            listsService: listsService,
            sessionManager: sessionManager
        )
    }

    func makeListsViewModel(listsStore: ListsStore) -> ListsViewModel {
        ListsViewModel(listsStore: listsStore)
    }

    func makeListDetailViewModel(
        listID: UUID,
        listsStore: ListsStore
    ) -> MovieListDetailViewModel {
        MovieListDetailViewModel(
            listID: listID,
            listsStore: listsStore
        )
    }
}
