
import Combine
import Foundation

@MainActor
final class ListsViewModel: ObservableObject {
    @Published private(set) var lists: [MovieList] = []

    private let store: ListsStoreManaging
    private var cancellables: Set<AnyCancellable> = []

    init(listsStore: ListsStoreManaging) {
        self.store = listsStore
        self.lists = listsStore.lists

        listsStore.listsPublisher
            .sink { [weak self] lists in
                self?.lists = lists
            }
            .store(in: &cancellables)
    }

    var totalMovieCount: Int {
        lists.reduce(0) { $0 + $1.movies.count }
    }

    func createList(named name: String) async -> MovieList? {
        await store.createList(named: name)
    }

    func renameList(listID: UUID, name: String) async -> Bool {
        await store.renameList(listID: listID, name: name)
    }

    func deleteList(listID: UUID) async {
        await store.deleteList(listID: listID)
    }
}
