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
    func createList(named name: String, existingLists: [FavoriteList]) throws -> FavoriteList
    func renameList(listID: UUID, name: String, existingLists: [FavoriteList]) throws
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

    func createList(named name: String, existingLists: [FavoriteList]) throws -> FavoriteList {
        let trimmedName = try validateListName(name, existingLists: existingLists)

        do {
            return try repository.createList(
                named: trimmedName,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func renameList(listID: UUID, name: String, existingLists: [FavoriteList]) throws {
        let trimmedName = try validateListName(
            name,
            existingLists: existingLists,
            excluding: listID
        )

        do {
            try repository.renameList(
                listID: listID,
                name: trimmedName,
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
        existingLists: [FavoriteList],
        excluding listID: UUID? = nil
    ) throws -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FavoritesServiceError.invalidListName
        }

        let duplicate = existingLists.first {
            $0.id != listID &&
            $0.name.localizedCaseInsensitiveCompare(trimmedName) == .orderedSame
        }

        guard duplicate == nil else {
            throw FavoritesServiceError.duplicateListName
        }

        return trimmedName
    }
}
