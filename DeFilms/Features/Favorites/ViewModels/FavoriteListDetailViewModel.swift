
import Combine
import Foundation

struct FavoriteMovieDestination: Identifiable, Equatable {
    let list: FavoriteList
    let alreadyContainsMovie: Bool

    var id: UUID { list.id }
}

@MainActor
final class FavoriteListDetailViewModel: ObservableObject {
    @Published private(set) var list: FavoriteList?

    let listID: UUID

    private let favoritesStore: FavoritesStoreManaging
    private var cancellables: Set<AnyCancellable> = []

    init(listID: UUID, favoritesStore: FavoritesStoreManaging) {
        self.listID = listID
        self.favoritesStore = favoritesStore
        self.list = favoritesStore.list(withID: listID)

        favoritesStore.listsPublisher
            .sink { [weak self] lists in
                guard let self else { return }
                self.list = lists.first { $0.id == self.listID }
            }
            .store(in: &cancellables)
    }

    func destinationOptions(for movieID: Int) -> [FavoriteMovieDestination] {
        favoritesStore.lists.compactMap { list in
            guard list.id != listID else { return nil }

            return FavoriteMovieDestination(
                list: list,
                alreadyContainsMovie: list.movies.contains(where: { $0.id == movieID })
            )
        }
    }

    var shareText: String? {
        guard let list, !list.movies.isEmpty else { return nil }

        let movieLines = list.movies.map { movie in
            "• \(movie.title) (\(movie.releaseYear))"
        }
        .joined(separator: "\n")

        return """
        \(Localization.string("favorites.share.header", list.name))

        \(movieLines)
        """
    }

    func renameList(name: String) async -> Bool {
        await favoritesStore.renameList(listID: listID, name: name)
    }

    func deleteList() async {
        await favoritesStore.deleteList(listID: listID)
    }

    func remove(movieID: Int) async {
        await favoritesStore.remove(movieID: movieID, from: listID)
    }

    func move(movieID: Int, to destinationListID: UUID) async {
        await favoritesStore.move(movieID: movieID, from: listID, to: destinationListID)
    }

    func createDestinationListAndMove(movieID: Int, listName: String) async -> Bool {
        guard let list = await favoritesStore.createList(named: listName) else {
            return false
        }

        await favoritesStore.move(movieID: movieID, from: listID, to: list.id)
        return true
    }
}
