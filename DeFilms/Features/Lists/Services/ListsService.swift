
import Foundation

enum ListsServiceError: LocalizedError, Equatable {
    case invalidListName
    case duplicateListName
    case persistenceFailure

    var errorDescription: String? {
        switch self {
        case .invalidListName:
            return Localization.string("lists.form.requiredHint")
        case .duplicateListName:
            return Localization.string("lists.toast.duplicateList")
        case .persistenceFailure:
            return Localization.string("lists.toast.genericError")
        }
    }
}

protocol ListsServicing {
    func loadLists() async throws -> [MovieList]
    func createList(named name: String, lists: [MovieList]) async throws -> MovieList
    func renameList(listID: UUID, name: String, lists: [MovieList]) async throws
    func deleteList(listID: UUID) async throws
    func add(movie: Movie, to listID: UUID) async throws
    func remove(movieID: Int, from listID: UUID) async throws
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) async throws
}

final class ListsService: ListsServicing {
    private let repository: ListsRepositoryProtocol
    private let sessionManager: AuthSessionManaging

    init(
        repository: ListsRepositoryProtocol,
        sessionManager: AuthSessionManaging
    ) {
        self.repository = repository
        self.sessionManager = sessionManager
    }

    func loadLists() async throws -> [MovieList] {
        do {
            return try await repository.fetchLists(for: currentUserIdentifier)
        } catch {
            throw ListsServiceError.persistenceFailure
        }
    }

    func createList(named name: String, lists: [MovieList]) async throws -> MovieList {
        let listName = try validateListName(name, in: lists)

        do {
            return try await repository.createList(
                named: listName,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw ListsServiceError.persistenceFailure
        }
    }

    func renameList(listID: UUID, name: String, lists: [MovieList]) async throws {
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
            throw ListsServiceError.persistenceFailure
        }
    }

    func deleteList(listID: UUID) async throws {
        do {
            try await repository.deleteList(
                listID: listID,
                userIdentifier: currentUserIdentifier
            )
        } catch {
            throw ListsServiceError.persistenceFailure
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
            throw ListsServiceError.persistenceFailure
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
            throw ListsServiceError.persistenceFailure
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
            throw ListsServiceError.persistenceFailure
        }
    }

    private var currentUserIdentifier: String {
        sessionManager.currentUserIdentifier
    }

    private func validateListName(
        _ name: String,
        in lists: [MovieList],
        excluding listID: UUID? = nil
    ) throws -> String {
        let listName = name.trimmed
        guard !listName.isEmpty else {
            throw ListsServiceError.invalidListName
        }

        let matchingList = lists.first {
            $0.id != listID &&
            normalizedListName($0.name) == normalizedListName(listName)
        }

        guard matchingList == nil else {
            throw ListsServiceError.duplicateListName
        }

        return listName
    }

    private func normalizedListName(_ name: String) -> String {
        name.normalizedForLookup
    }
}
