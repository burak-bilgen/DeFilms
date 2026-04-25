
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
    func loadLists() async throws -> [FavoriteList]
    func createList(named name: String, lists: [FavoriteList]) async throws -> FavoriteList
    func renameList(listID: UUID, name: String, lists: [FavoriteList]) async throws
    func deleteList(listID: UUID) async throws
    func add(movie: Movie, to listID: UUID) async throws
    func remove(movieID: Int, from listID: UUID) async throws
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) async throws
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

    func loadLists() async throws -> [FavoriteList] {
        do {
            try await repository.adoptListsIfNeeded(
                for: currentUserIdentifier,
                from: sessionManager.legacyUserIdentifiers
            )
            return try await repository.fetchLists(for: currentUserIdentifier)
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func createList(named name: String, lists: [FavoriteList]) async throws -> FavoriteList {
        let listName = try validateListName(name, in: lists)

        do {
            return try await repository.createList(
                named: listName,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func renameList(listID: UUID, name: String, lists: [FavoriteList]) async throws {
        let listName = try validateListName(
            name,
            in: lists,
            excluding: listID
        )

        do {
            try await repository.renameList(
                listID: listID,
                name: listName,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func deleteList(listID: UUID) async throws {
        do {
            try await repository.deleteList(
                listID: listID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func add(movie: Movie, to listID: UUID) async throws {
        do {
            try await repository.add(
                movie: movie,
                to: listID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func remove(movieID: Int, from listID: UUID) async throws {
        do {
            try await repository.remove(
                movieID: movieID,
                from: listID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw FavoritesServiceError.persistenceFailure
        }
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) async throws {
        do {
            try await repository.move(
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
        let listName = name.trimmed
        guard !listName.isEmpty else {
            throw FavoritesServiceError.invalidListName
        }

        let matchingList = lists.first {
            $0.id != listID &&
            normalizedListName($0.name) == normalizedListName(listName)
        }

        guard matchingList == nil else {
            throw FavoritesServiceError.duplicateListName
        }

        return listName
    }

    private func normalizedListName(_ name: String) -> String {
        name.normalizedForLookup
    }
}
