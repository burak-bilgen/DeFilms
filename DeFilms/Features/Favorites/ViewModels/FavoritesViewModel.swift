
import Combine
import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var lists: [FavoriteList] = []

    private let store: FavoritesStoreManaging
    private var cancellables: Set<AnyCancellable> = []

    init(favoritesStore: FavoritesStoreManaging) {
        self.store = favoritesStore
        self.lists = favoritesStore.lists

        favoritesStore.listsPublisher
            .sink { [weak self] lists in
                self?.lists = lists
            }
            .store(in: &cancellables)
    }

    var totalMovieCount: Int {
        lists.reduce(0) { $0 + $1.movies.count }
    }

    func createList(named name: String) async -> FavoriteList? {
        await store.createList(named: name)
    }

    func renameList(listID: UUID, name: String) async -> Bool {
        await store.renameList(listID: listID, name: name)
    }

    func deleteList(listID: UUID) async {
        await store.deleteList(listID: listID)
    }
}
