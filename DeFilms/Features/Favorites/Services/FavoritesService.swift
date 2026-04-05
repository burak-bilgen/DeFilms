//
//  FavoritesServices.swift
//  DeFilms
//

import Foundation

enum FavoritesServiceError: LocalizedError, Equatable {
    case invalidListName
    case duplicateListName
    case persistenceFailure

    var errorDescription: String? {
        switch self {
        case .invalidListName:
            return Localization.string("favorites.form.requiredHint")
        case .duplicateListName:
            return Localization.string("favorites.toast.duplicateList")
        case .persistenceFailure:
            return Localization.string("favorites.toast.genericError")
        }
    }
}

protocol FavoritesServicing {
    func loadLists() throws -> [FavoriteList]
    func createList(named name: String, lists: [FavoriteList]) throws -> FavoriteList
    func renameList(listID: UUID, name: String, lists: [FavoriteList]) throws
    func deleteList(listID: UUID) throws
    func add(movie: Movie, to listID: UUID) throws
    func remove(movieID: Int, from listID: UUID) throws
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) throws
}

final class FavoritesService: FavoritesServicing {
    private let repository: FavoritesRepositoryProtocol
    private let sessionManager: AuthSessionManaging

    init(
        repository: FavoritesRepositoryProtocol,
        sessionManager: AuthSessionManaging
    ) {
        self.repository = repository
        self.sessionManager = sessionManager
    }

    func loadLists() throws -> [FavoriteList] {
        do {
            try repository.adoptListsIfNeeded(
                for: currentUserIdentifier,
                from: sessionManager.legacyUserIdentifiers
            )
            return try repository.fetchLists(for: currentUserIdentifier)
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func createList(named name: String, lists: [FavoriteList]) throws -> FavoriteList {
        let listName = try validateListName(name, in: lists)

        do {
            return try repository.createList(
                named: listName,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func renameList(listID: UUID, name: String, lists: [FavoriteList]) throws {
        let listName = try validateListName(
            name,
            in: lists,
            excluding: listID
        )

        do {
            try repository.renameList(
                listID: listID,
                name: listName,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func deleteList(listID: UUID) throws {
        do {
            try repository.deleteList(
                listID: listID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func add(movie: Movie, to listID: UUID) throws {
        do {
            try repository.add(
                movie: movie,
                to: listID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func remove(movieID: Int, from listID: UUID) throws {
        do {
            try repository.remove(
                movieID: movieID,
                from: listID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) throws {
        do {
            try repository.move(
                movieID: movieID,
                from: sourceListID,
                to: destinationListID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    private var currentUserIdentifier: String {
        sessionManager.currentUserIdentifier
    }

    private func validateListName(
        _ name: String,
        in lists: [FavoriteList],
        excluding listID: UUID? = nil
    ) throws -> String {
        let listName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !listName.isEmpty else {
            throw FavoritesServiceError.invalidListName
        }

        let matchingList = lists.first {
            $0.id != listID &&
            $0.name.localizedCaseInsensitiveCompare(listName) == .orderedSame
        }

        guard matchingList == nil else {
            throw FavoritesServiceError.duplicateListName
        }

        return listName
    }
}
