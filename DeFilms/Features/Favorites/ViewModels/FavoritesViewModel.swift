//
//  FavoritesViewModel.swift
//  DeFilms
//

import Combine
import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published private(set) var lists: [FavoriteList] = []

    private let store: FavoritesStore
    private var cancellables: Set<AnyCancellable> = []

    init(favoritesStore: FavoritesStore) {
        self.store = favoritesStore
        self.lists = favoritesStore.lists

        favoritesStore.$lists
            .sink { [weak self] lists in
                self?.lists = lists
            }
            .store(in: &cancellables)
    }

    var totalMovieCount: Int {
        lists.reduce(0) { $0 + $1.movies.count }
    }

    func createList(named name: String) -> FavoriteList? {
        store.createList(named: name)
    }

    func renameList(listID: UUID, name: String) -> Bool {
        store.renameList(listID: listID, name: name)
    }

    func deleteList(listID: UUID) {
        store.deleteList(listID: listID)
    }
}
