//
//  FavoritesStore.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var lists: [FavoriteList] = []
    @Published private(set) var toastItem: ToastItem?

    private let repository: FavoritesRepositoryProtocol
    private let sessionManager: AuthSessionManager
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

        if let existingList = existingList(named: trimmed) {
            return existingList
        }

        do {
            let list = try repository.createList(named: trimmed, userIdentifier: currentUserIdentifier)
            reloadLists()
            AppLogger.log("Created favorite list: \(trimmed)", category: .favorites, level: .success)
            toastItem = .success(Localization.string("favorites.toast.listCreated"))
            return list
        } catch {
            AppLogger.log("Failed to create favorite list", category: .favorites, level: .error)
            toastItem = .error(Localization.string("favorites.toast.genericError"))
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
            toastItem = .error(Localization.string("favorites.toast.genericError"))
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
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return
        }
    }

    func renameList(listID: UUID, name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if let existingList = existingList(named: trimmed), existingList.id != listID {
            toastItem = .error(Localization.string("favorites.toast.duplicateList"))
            return false
        }

        do {
            try repository.renameList(listID: listID, name: trimmed, userIdentifier: currentUserIdentifier)
            reloadLists()
            toastItem = .success(Localization.string("favorites.toast.listRenamed"))
            return true
        } catch {
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return false
        }
    }

    func deleteList(listID: UUID) {
        do {
            try repository.deleteList(listID: listID, userIdentifier: currentUserIdentifier)
            reloadLists()
            toastItem = .success(Localization.string("favorites.toast.listDeleted"))
        } catch {
            toastItem = .error(Localization.string("favorites.toast.genericError"))
        }
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) {
        do {
            try repository.move(
                movieID: movieID,
                from: sourceListID,
                to: destinationListID,
                userIdentifier: currentUserIdentifier
            )
            reloadLists()
            toastItem = .success(Localization.string("favorites.toast.movieMoved"))
        } catch {
            toastItem = .error(Localization.string("favorites.toast.genericError"))
        }
    }

    func clearToast() {
        toastItem = nil
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

    func listIDs(containing movieID: Int) -> Set<UUID> {
        Set(
            lists.compactMap { list in
                list.movies.contains(where: { $0.id == movieID }) ? list.id : nil
            }
        )
    }

    func existingList(named name: String) -> FavoriteList? {
        lists.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    var totalMovieCount: Int {
        lists.reduce(0) { $0 + $1.movies.count }
    }

    func list(withID listID: UUID) -> FavoriteList? {
        lists.first(where: { $0.id == listID })
    }

    private var currentUserIdentifier: String {
        sessionManager.currentUserIdentifier
    }

    private func reloadLists() {
        try? repository.adoptListsIfNeeded(
            for: currentUserIdentifier,
            from: sessionManager.legacyUserIdentifiers
        )
        let updatedLists = (try? repository.fetchLists(for: currentUserIdentifier)) ?? []
        withAnimation(.easeInOut(duration: 0.24)) {
            lists = updatedLists
        }
        AppLogger.log("Favorites reloaded for \(currentUserIdentifier)", category: .favorites)
    }
}
