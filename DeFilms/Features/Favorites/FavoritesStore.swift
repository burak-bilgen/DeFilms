//
//  FavoritesStore.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation

final class FavoritesStore: ObservableObject {
    @Published private(set) var lists: [FavoriteList] = []

    private let repository: FavoritesRepositoryProtocol
    private let sessionManager: AuthSessionManager
    private let defaultListNameKey = "favorites.defaultListName"
    private var cancellables: Set<AnyCancellable> = []

    init(
        repository: FavoritesRepositoryProtocol,
        sessionManager: AuthSessionManager
    ) {
        self.repository = repository
        self.sessionManager = sessionManager

        sessionManager.$session
            .sink { [weak self] _ in
                self?.reloadLists()
            }
            .store(in: &cancellables)

        reloadLists()
    }

    func createList(named name: String) -> FavoriteList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        do {
            let list = try repository.createList(named: trimmed, userIdentifier: currentUserIdentifier)
            reloadLists()
            AppLogger.log("Created favorite list: \(trimmed)", category: .favorites, level: .success)
            ToastCenter.shared.showSuccess(Localization.string("favorites.toast.listCreated"))
            return list
        } catch {
            AppLogger.log("Failed to create favorite list", category: .favorites, level: .error)
            ToastCenter.shared.showError(Localization.string("favorites.toast.genericError"))
            return nil
        }
    }

    func add(movie: Movie, to listID: UUID) {
        do {
            try repository.add(movie: movie, to: listID, userIdentifier: currentUserIdentifier)
            reloadLists()
            AppLogger.log("Added movie \(movie.id) to favorites", category: .favorites, level: .success)
        } catch {
            AppLogger.log("Failed to add movie \(movie.id) to favorites", category: .favorites, level: .error)
            ToastCenter.shared.showError(Localization.string("favorites.toast.genericError"))
            return
        }
    }

    func remove(movieID: Int, from listID: UUID) {
        do {
            try repository.remove(movieID: movieID, from: listID, userIdentifier: currentUserIdentifier)
            reloadLists()
            AppLogger.log("Removed movie \(movieID) from list \(listID.uuidString)", category: .favorites, level: .success)
        } catch {
            AppLogger.log("Failed to remove movie \(movieID) from list", category: .favorites, level: .error)
            ToastCenter.shared.showError(Localization.string("favorites.toast.genericError"))
            return
        }
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

    func toggleFavorite(movie: Movie) {
        if isMovieInAnyList(movieID: movie.id) {
            remove(movieID: movie.id)
        } else {
            let listID = defaultList().id
            add(movie: movie, to: listID)
        }
    }

    func remove(movieID: Int) {
        do {
            try repository.remove(movieID: movieID, userIdentifier: currentUserIdentifier)
            reloadLists()
            AppLogger.log("Removed movie \(movieID) from all lists", category: .favorites, level: .success)
        } catch {
            AppLogger.log("Failed to remove movie \(movieID) from favorites", category: .favorites, level: .error)
            ToastCenter.shared.showError(Localization.string("favorites.toast.genericError"))
            return
        }
    }

    func defaultList() -> FavoriteList {
        if let list = lists.first(where: { $0.name.localizedCaseInsensitiveCompare(Localization.string(defaultListNameKey)) == .orderedSame }) {
            return list
        }

        return createList(named: Localization.string(defaultListNameKey)) ?? FavoriteList(id: UUID(), name: Localization.string(defaultListNameKey), movies: [])
    }

    private var currentUserIdentifier: String {
        sessionManager.currentUserIdentifier
    }

    private func reloadLists() {
        lists = (try? repository.fetchLists(for: currentUserIdentifier)) ?? []
        AppLogger.log("Favorites reloaded for \(currentUserIdentifier)", category: .favorites)
    }
}
