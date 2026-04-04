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

    private let favoritesStore: FavoritesStore
    private var cancellables: Set<AnyCancellable> = []

    init(listID: UUID, favoritesStore: FavoritesStore) {
        self.listID = listID
        self.favoritesStore = favoritesStore
        self.list = favoritesStore.list(withID: listID)

        favoritesStore.$lists
            .sink { [weak self] _ in
                guard let self else { return }
                self.list = self.favoritesStore.list(withID: self.listID)
            }
            .store(in: &cancellables)
    }

    var destinationLists: [FavoriteList] {
        favoritesStore.lists.filter { $0.id != listID }
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

    func renameList(name: String) -> Bool {
        favoritesStore.renameList(listID: listID, name: name)
    }

    func deleteList() {
        favoritesStore.deleteList(listID: listID)
    }

    func remove(movieID: Int) {
        favoritesStore.remove(movieID: movieID, from: listID)
    }

    func move(movieID: Int, to destinationListID: UUID) {
        favoritesStore.move(movieID: movieID, from: listID, to: destinationListID)
    }
}
