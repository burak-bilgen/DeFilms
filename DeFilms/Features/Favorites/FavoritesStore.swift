//
//  FavoritesStore.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var lists: [FavoriteList] = []

    private let storageKey = "FavoriteListsStorage"

    init() {
        load()
    }

    func createList(named name: String) -> FavoriteList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        let list = FavoriteList(id: UUID(), name: trimmed, movies: [])
        lists.insert(list, at: 0)
        save()
        return list
    }

    func add(movie: Movie, to listID: UUID) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        if lists[index].movies.contains(where: { $0.id == movie.id }) {
            return
        }
        lists[index].movies.append(FavoriteMovie(movie: movie))
        save()
    }

    func remove(movieID: Int, from listID: UUID) {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].movies.removeAll { $0.id == movieID }
        save()
    }

    func isMovieInAnyList(movieID: Int) -> Bool {
        lists.contains { list in
            list.movies.contains { $0.id == movieID }
        }
    }

    func isMovieInList(movieID: Int, listID: UUID) -> Bool {
        guard let list = lists.first(where: { $0.id == listID }) else { return false }
        return list.movies.contains { $0.id == movieID }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            let decoded = try JSONDecoder().decode([FavoriteList].self, from: data)
            lists = decoded
        } catch {
            lists = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(lists)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // no-op
        }
    }
}
