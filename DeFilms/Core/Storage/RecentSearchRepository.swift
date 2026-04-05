//
//  RecentSearchRepository.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import CoreData
import Foundation

protocol RecentSearchRepositoryProtocol {
    func fetchRecentSearches(for userIdentifier: String, limit: Int) async throws -> [String]
    func addSearch(_ query: String, for userIdentifier: String, limit: Int) async throws
    func clearRecentSearches(for userIdentifier: String) async throws
}

final class RecentSearchRepository: RecentSearchRepositoryProtocol {
    static let shared = RecentSearchRepository()

    private let persistenceController: PersistenceController
    private let legacyStorageKey = "MovieSearchHistory"
    private let legacyGuestIdentifier = "guest"

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        Task {
            await migrateLegacySearchesIfNeeded()
        }
        AppLogger.log("Recent search repository initialized", category: .persistence)
    }

    func fetchRecentSearches(for userIdentifier: String, limit: Int) async throws -> [String] {
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
        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return }

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
        try persistenceController.performWrite { context in
            let request = RecentSearchEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)

            let searches = try context.fetch(request)
            for search in searches {
                context.delete(search)
            }
        }
        AppLogger.log("Cleared recent searches", category: .persistence, level: .success)
    }

    private func migrateLegacySearchesIfNeeded() async {
        let userDefaults = UserDefaults.standard
        AppLogger.log("Starting legacy recent-search migration", category: .persistence, level: .warning)
        guard
            let searches = userDefaults.stringArray(forKey: legacyStorageKey),
            searches.isEmpty == false
        else {
            userDefaults.removeObject(forKey: legacyStorageKey)
            return
        }

        if let existing = try? await fetchRecentSearches(for: legacyGuestIdentifier, limit: searches.count),
           existing.isEmpty == false {
            if legacySearchMigrationMatchesSource(searches, importedSearches: existing) {
                userDefaults.removeObject(forKey: legacyStorageKey)
            }
            return
        }

        do {
            try importLegacySearches(searches)
            let importedSearches = try await fetchRecentSearches(
                for: legacyGuestIdentifier,
                limit: max(searches.count, 10)
            )

            guard legacySearchMigrationMatchesSource(searches, importedSearches: importedSearches) else {
                AppLogger.log("Legacy recent-search migration verification failed", category: .persistence, level: .error)
                return
            }

            userDefaults.removeObject(forKey: legacyStorageKey)
            AppLogger.log("Legacy recent-search migration finished", category: .persistence, level: .success)
        } catch {
            AppLogger.log("Legacy recent-search migration failed", category: .persistence, level: .error)
        }
    }

    private func importLegacySearches(_ searches: [String]) throws {
        let normalizedSearches = normalizedLegacySearches(searches)

        try persistenceController.performWrite { context in
            for (index, query) in normalizedSearches.enumerated() {
                let entity = RecentSearchEntity(context: context)
                entity.id = UUID()
                entity.query = query
                entity.userIdentifier = legacyGuestIdentifier
                entity.createdAt = Date().addingTimeInterval(TimeInterval(-index))
            }
        }
    }

    private func legacySearchMigrationMatchesSource(_ sourceSearches: [String], importedSearches: [String]) -> Bool {
        normalizedLegacySearches(sourceSearches) == importedSearches
    }

    private func normalizedLegacySearches(_ searches: [String]) -> [String] {
        var deduplicated: [String] = []

        for query in searches.reversed() {
            let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !searchText.isEmpty else { continue }
            guard !deduplicated.contains(where: { $0.compare(searchText, options: .caseInsensitive) == .orderedSame }) else { continue }
            deduplicated.append(searchText)
        }

        return deduplicated
    }

    func replaceSearchesForUITesting(_ searches: [String], userIdentifier: String) throws {
        let normalizedSearches = normalizedLegacySearches(searches)

        try persistenceController.performWrite { context in
            let request = RecentSearchEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
            try context.fetch(request).forEach(context.delete)

            for (index, query) in normalizedSearches.enumerated() {
                let entity = RecentSearchEntity(context: context)
                entity.id = UUID()
                entity.query = query
                entity.userIdentifier = userIdentifier
                entity.createdAt = Date().addingTimeInterval(TimeInterval(-index))
            }
        }
    }
}
