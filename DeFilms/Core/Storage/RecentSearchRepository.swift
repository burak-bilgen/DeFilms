//
//  RecentSearchRepository.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import CoreData
import Foundation

protocol RecentSearchRepositoryProtocol {
    func fetchRecentSearches(for userIdentifier: String, limit: Int) throws -> [String]
    func addSearch(_ query: String, for userIdentifier: String, limit: Int) throws
    func clearRecentSearches(for userIdentifier: String) throws
}

final class RecentSearchRepository: RecentSearchRepositoryProtocol {
    static let shared = RecentSearchRepository()

    private let persistenceController: PersistenceController
    private let legacyStorageKey = "MovieSearchHistory"

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        migrateLegacySearchesIfNeeded()
        AppLogger.log("Recent search repository initialized", category: .persistence)
    }

    func fetchRecentSearches(for userIdentifier: String, limit: Int) throws -> [String] {
        let request = RecentSearchEntity.fetchRequest()
        request.fetchLimit = limit
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)

        let results = try persistenceController.viewContext.fetch(request).map(\.query)
        AppLogger.log("Fetched recent searches", category: .persistence)
        return results
    }

    func addSearch(_ query: String, for userIdentifier: String, limit: Int) throws {
        let searchText = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else { return }

        let context = persistenceController.viewContext

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

        try context.save()
        AppLogger.log("Saved recent search", category: .persistence, level: .success)
    }

    func clearRecentSearches(for userIdentifier: String) throws {
        let context = persistenceController.viewContext
        let request = RecentSearchEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)

        let searches = try context.fetch(request)
        for search in searches {
            context.delete(search)
        }

        try context.save()
        AppLogger.log("Cleared recent searches", category: .persistence, level: .success)
    }

    private func migrateLegacySearchesIfNeeded() {
        let userDefaults = UserDefaults.standard
        let guestIdentifier = "guest"
        AppLogger.log("Starting legacy recent-search migration", category: .persistence, level: .warning)
        guard
            let searches = userDefaults.stringArray(forKey: legacyStorageKey),
            let existing = try? fetchRecentSearches(for: guestIdentifier, limit: searches.count),
            existing.isEmpty
        else {
            userDefaults.removeObject(forKey: legacyStorageKey)
            return
        }

        for query in searches.reversed() {
            try? addSearch(query, for: guestIdentifier, limit: max(searches.count, 10))
        }

        userDefaults.removeObject(forKey: legacyStorageKey)
        AppLogger.log("Legacy recent-search migration finished", category: .persistence, level: .success)
    }
}
