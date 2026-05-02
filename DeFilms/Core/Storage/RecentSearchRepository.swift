
import CoreData
import Foundation

protocol RecentSearchRepositoryProtocol {
    func fetchRecentSearches(for userIdentifier: String, limit: Int) async throws -> [String]
    func addSearch(_ query: String, for userIdentifier: String, limit: Int) async throws
    func clearRecentSearches(for userIdentifier: String) async throws
    func clearRecentSearches(for userIdentifiers: [String]) async throws
}

final class RecentSearchRepository: RecentSearchRepositoryProtocol {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        AppLogger.log("Recent search repository initialized", category: .persistence)
    }

    func fetchRecentSearches(for userIdentifier: String, limit: Int) async throws -> [String] {
        guard limit > 0 else { return [] }

        let results = try persistenceController.performRead { context in
            let request = RecentSearchEntity.fetchRequest()
            request.fetchLimit = limit
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
            return try context.fetch(request).map(\.query)
        }
        AppLogger.log("Fetched recent searches", category: .persistence)
        return results
    }

    func addSearch(_ query: String, for userIdentifier: String, limit: Int) async throws {
        let searchText = query.trimmed
        guard !searchText.isEmpty else { return }
        guard limit > 0 else { return }

        try persistenceController.performWrite { context in
            let matchingSearchRequest = RecentSearchEntity.fetchRequest()
            matchingSearchRequest.predicate = NSPredicate(format: "query =[c] %@ AND userIdentifier == %@", searchText, userIdentifier)
            let existingMatches = try context.fetch(matchingSearchRequest)
            for item in existingMatches {
                context.delete(item)
            }

            let entity = RecentSearchEntity(context: context)
            entity.id = UUID()
            entity.query = searchText
            entity.userIdentifier = userIdentifier
            entity.createdAt = Date()

            let searchesRequest = RecentSearchEntity.fetchRequest()
            searchesRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            searchesRequest.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
            let allSearches = try context.fetch(searchesRequest)

            for search in allSearches.dropFirst(limit) {
                context.delete(search)
            }
        }
        AppLogger.log("Saved recent search", category: .persistence, level: .success)
    }

    func clearRecentSearches(for userIdentifier: String) async throws {
        try await clearRecentSearches(for: [userIdentifier])
    }

    func clearRecentSearches(for userIdentifiers: [String]) async throws {
        let identifiers = normalizedUserIdentifiers(userIdentifiers)
        guard !identifiers.isEmpty else { return }

        try persistenceController.performWrite { context in
            let request = RecentSearchEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userIdentifier IN %@", identifiers)

            let searches = try context.fetch(request)
            for search in searches {
                context.delete(search)
            }
        }
        AppLogger.log("Cleared recent searches", category: .persistence, level: .success)
    }

    private func normalizedSearches(_ searches: [String]) -> [String] {
        var deduplicated: [String] = []

        for query in searches.reversed() {
            let searchText = query.trimmed
            guard !searchText.isEmpty else { continue }
            guard !deduplicated.contains(where: { $0.compare(searchText, options: .caseInsensitive) == .orderedSame }) else { continue }
            deduplicated.append(searchText)
        }

        return deduplicated
    }

    private func normalizedUserIdentifiers(_ identifiers: [String]) -> [String] {
        Array(Set(identifiers.map { $0.trimmed }.filter { !$0.isEmpty }))
    }

    func replaceSearchesForUITesting(_ searches: [String], userIdentifier: String) throws {
        let seededSearches = normalizedSearches(searches)

        try persistenceController.performWrite { context in
            let request = RecentSearchEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
            try context.fetch(request).forEach(context.delete)

            for (index, query) in seededSearches.enumerated() {
                let entity = RecentSearchEntity(context: context)
                entity.id = UUID()
                entity.query = query
                entity.userIdentifier = userIdentifier
                entity.createdAt = Date().addingTimeInterval(TimeInterval(-index))
            }
        }
    }
}
