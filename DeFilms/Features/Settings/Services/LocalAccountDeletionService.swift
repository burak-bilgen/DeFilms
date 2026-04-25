
import Foundation

protocol LocalAccountDeleting {
    func deleteCurrentAccountAndData() async throws
}

enum LocalAccountDeletionError: Error, LocalizedError, Equatable {
    case notSignedIn
    case persistenceFailure

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return Localization.string("auth.error.notSignedIn")
        case .persistenceFailure:
            return Localization.string("settings.account.delete.error")
        }
    }
}

final class LocalAccountDeletionService: LocalAccountDeleting {
    private let sessionManager: AuthSessionManaging
    private let favoritesRepository: FavoritesRepositoryProtocol
    private let recentSearchRepository: RecentSearchRepositoryProtocol

    init(
        sessionManager: AuthSessionManaging,
        favoritesRepository: FavoritesRepositoryProtocol,
        recentSearchRepository: RecentSearchRepositoryProtocol
    ) {
        self.sessionManager = sessionManager
        self.favoritesRepository = favoritesRepository
        self.recentSearchRepository = recentSearchRepository
    }

    func deleteCurrentAccountAndData() async throws {
        guard let session = sessionManager.session else {
            throw LocalAccountDeletionError.notSignedIn
        }

        let userIdentifiers = accountScopedIdentifiers(for: session)

        do {
            try await favoritesRepository.deleteLists(for: userIdentifiers)
            try await recentSearchRepository.clearRecentSearches(for: userIdentifiers)
            try sessionManager.deleteSignedInAccount()
        } catch let error as LocalizedError {
            throw error
        } catch {
            throw LocalAccountDeletionError.persistenceFailure
        }
    }

    private func accountScopedIdentifiers(for session: AuthSession) -> [String] {
        let identifiers = [
            session.userIdentifier,
            session.email.lowercased()
        ]

        return Array(Set(identifiers.map { $0.trimmed }.filter { !$0.isEmpty }))
    }
}
