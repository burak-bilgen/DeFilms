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

    private let favoritesService: FavoritesServicing
    private let sessionManager: AuthSessionManager
    private var cancellables: Set<AnyCancellable> = []

    init(
        favoritesService: FavoritesServicing,
        sessionManager: AuthSessionManager
    ) {
        self.favoritesService = favoritesService
        self.sessionManager = sessionManager

        sessionManager.$session
            .sink { [weak self] _ in
                self?.reloadLists()
            }
            .store(in: &cancellables)

        reloadLists()
    }

    func createList(named name: String) -> FavoriteList? {
        do {
            let list = try favoritesService.createList(named: name, existingLists: lists)
            reloadLists()
            AppLogger.log("Created favorite list: \(list.name)", category: .favorites, level: .success)
            toastItem = .success(Localization.string("favorites.toast.listCreated"))
            return list
        } catch FavoritesServiceError.invalidListName {
            return nil
        } catch FavoritesServiceError.duplicateListName {
            if let existingList = existingList(named: name) {
                return existingList
            }
            toastItem = .error(Localization.string("favorites.toast.duplicateList"))
            return nil
        } catch {
            AppLogger.log("Failed to create favorite list", category: .favorites, level: .error)
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return nil
        }
    }

    func add(movie: Movie, to listID: UUID) {
        do {
            try favoritesService.add(movie: movie, to: listID)
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
            try favoritesService.remove(movieID: movieID, from: listID)
            reloadLists()
            AppLogger.log("Removed movie \(movieID) from list \(listID.uuidString)", category: .favorites, level: .success)
        } catch {
            AppLogger.log("Failed to remove movie \(movieID) from list", category: .favorites, level: .error)
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return
        }
    }

    func renameList(listID: UUID, name: String) -> Bool {
        do {
            try favoritesService.renameList(listID: listID, name: name, existingLists: lists)
            reloadLists()
            toastItem = .success(Localization.string("favorites.toast.listRenamed"))
            return true
        } catch FavoritesServiceError.invalidListName {
            return false
        } catch FavoritesServiceError.duplicateListName {
            toastItem = .error(Localization.string("favorites.toast.duplicateList"))
            return false
        } catch {
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return false
        }
    }

    func deleteList(listID: UUID) {
        do {
            try favoritesService.deleteList(listID: listID)
            reloadLists()
            toastItem = .success(Localization.string("favorites.toast.listDeleted"))
        } catch {
            toastItem = .error(Localization.string("favorites.toast.genericError"))
        }
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) {
        do {
            try favoritesService.move(
                movieID: movieID,
                from: sourceListID,
                to: destinationListID
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

    private func reloadLists() {
        let updatedLists = (try? favoritesService.loadLists()) ?? []
        withAnimation(.easeInOut(duration: 0.24)) {
            lists = updatedLists
        }
        AppLogger.log("Favorites reloaded for \(sessionManager.currentUserIdentifier)", category: .favorites)
    }
}
