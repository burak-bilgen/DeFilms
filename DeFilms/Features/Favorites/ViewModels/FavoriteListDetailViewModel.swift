//
//  FavoriteListDetailViewModel.swift
//  DeFilms
//

import Combine
import Foundation

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
            .sink { [weak self] _ in
                self?.refreshCurrentList()
            }
            .store(in: &cancellables)
    }

    var destinationLists: [FavoriteList] {
        favoritesStore.lists.filter { $0.id != listID }
    }

    var shareText: String? {
        guard let list, !list.movies.isEmpty else { return nil }

        // Keep the exported text intentionally plain so the system share sheet
        // works equally well with Notes, Messages, and third-party apps.
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

    private func refreshCurrentList() {
        list = favoritesStore.list(withID: listID)
    }
}
