
import Combine
import Foundation

struct ListedMovieDestination: Identifiable, Equatable {
    let list: MovieList
    let alreadyContainsMovie: Bool

    var id: UUID { list.id }
}

@MainActor
final class MovieListDetailViewModel: ObservableObject {
    @Published private(set) var list: MovieList?

    let listID: UUID

    private let listsStore: ListsStoreManaging
    private var cancellables: Set<AnyCancellable> = []

    init(listID: UUID, listsStore: ListsStoreManaging) {
        self.listID = listID
        self.listsStore = listsStore
        self.list = listsStore.list(withID: listID)

        listsStore.listsPublisher
            .sink { [weak self] lists in
                guard let self else { return }
                self.list = lists.first { $0.id == self.listID }
            }
            .store(in: &cancellables)
    }

    func destinationOptions(for movieID: Int) -> [ListedMovieDestination] {
        listsStore.lists.compactMap { list in
            guard list.id != listID else { return nil }

            return ListedMovieDestination(
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
        \(Localization.string("lists.share.header", list.name))

        \(movieLines)
        """
    }

    func renameList(name: String) async -> Bool {
        await listsStore.renameList(listID: listID, name: name)
    }

    func deleteList() async {
        await listsStore.deleteList(listID: listID)
    }

    func remove(movieID: Int) async {
        await listsStore.remove(movieID: movieID, from: listID)
    }

    func move(movieID: Int, to destinationListID: UUID) async {
        await listsStore.move(movieID: movieID, from: listID, to: destinationListID)
    }

    func createDestinationListAndMove(movieID: Int, listName: String) async -> Bool {
        guard let list = await listsStore.createList(named: listName) else {
            return false
        }

        await listsStore.move(movieID: movieID, from: listID, to: list.id)
        return true
    }
}
