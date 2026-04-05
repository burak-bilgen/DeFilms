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
final class FavoritesStore: ObservableObject, FavoritesStoreManaging {
    @Published private(set) var lists: [FavoriteList] = []
    @Published private(set) var toastItem: ToastItem?

    private let favoritesService: FavoritesServicing
    private let sessionManager: AuthSessionManager
    private var cancellables: Set<AnyCancellable> = []

    var listsPublisher: AnyPublisher<[FavoriteList], Never> {
        $lists.eraseToAnyPublisher()
    }

    init(
        favoritesService: FavoritesServicing,
        sessionManager: AuthSessionManager
    ) {
        self.favoritesService = favoritesService
        self.sessionManager = sessionManager

        sessionManager.$session
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.refreshLists()
                }
            }
            .store(in: &cancellables)

        Task { @MainActor in
            await refreshLists()
        }
    }

    func createList(named name: String) async -> FavoriteList? {
        do {
            let list = try await favoritesService.createList(named: name, lists: lists)
            await refreshLists()
            AppLogger.log("Created favorite list", category: .favorites, level: .success)
            toastItem = .success(Localization.string("favorites.toast.listCreated"))
            return list
        } catch FavoritesServiceError.invalidListName {
            return nil
        } catch FavoritesServiceError.duplicateListName {
            if let matchingList = list(named: name) {
                return matchingList
            }
            toastItem = .error(Localization.string("favorites.toast.duplicateList"))
            return nil
        } catch {
            AppLogger.log("Failed to create favorite list", category: .favorites, level: .error)
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return nil
        }
    }

    func add(movie: Movie, to listID: UUID) async {
        do {
            try await favoritesService.add(movie: movie, to: listID)
            await refreshLists()
            AppLogger.log("Added movie to favorites", category: .favorites, level: .success)
        } catch {
            AppLogger.log("Failed to add movie to favorites", category: .favorites, level: .error)
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return
        }
    }

    func remove(movieID: Int, from listID: UUID) async {
        do {
            try await favoritesService.remove(movieID: movieID, from: listID)
            await refreshLists()
            AppLogger.log("Removed movie from list", category: .favorites, level: .success)
        } catch {
            AppLogger.log("Failed to remove movie from list", category: .favorites, level: .error)
            toastItem = .error(Localization.string("favorites.toast.genericError"))
            return
        }
    }

    func renameList(listID: UUID, name: String) async -> Bool {
        do {
            try await favoritesService.renameList(listID: listID, name: name, lists: lists)
            await refreshLists()
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

    func deleteList(listID: UUID) async {
        do {
            try await favoritesService.deleteList(listID: listID)
            await refreshLists()
            toastItem = .success(Localization.string("favorites.toast.listDeleted"))
        } catch {
            toastItem = .error(Localization.string("favorites.toast.genericError"))
        }
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) async {
        do {
            try await favoritesService.move(
                movieID: movieID,
                from: sourceListID,
                to: destinationListID
            )
            await refreshLists()
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

    func list(named name: String) -> FavoriteList? {
        lists.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    var totalMovieCount: Int {
        lists.reduce(0) { $0 + $1.movies.count }
    }

    func list(withID listID: UUID) -> FavoriteList? {
        lists.first(where: { $0.id == listID })
    }

    private func refreshLists() async {
        do {
            let latestLists = try await favoritesService.loadLists()
            withAnimation(.easeInOut(duration: 0.24)) {
                lists = latestLists
            }
            AppLogger.log("Favorites refreshed", category: .favorites)
        } catch {
            AppLogger.log("Failed to refresh favorites", category: .favorites, level: .error)
            toastItem = .error(Localization.string("favorites.toast.genericError"))
        }
    }
}
