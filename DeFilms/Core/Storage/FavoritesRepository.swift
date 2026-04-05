//
//  FavoritesRepository.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import CoreData
import Foundation

protocol FavoritesRepositoryProtocol {
    func fetchLists(for userIdentifier: String) async throws -> [FavoriteList]
    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) async throws
    func createList(named name: String, userIdentifier: String) async throws -> FavoriteList
    func renameList(listID: UUID, name: String, userIdentifier: String) async throws
    func deleteList(listID: UUID, userIdentifier: String) async throws
    func add(movie: Movie, to listID: UUID, userIdentifier: String) async throws
    func remove(movieID: Int, from listID: UUID, userIdentifier: String) async throws
    func remove(movieID: Int, userIdentifier: String) async throws
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) async throws
}

final class FavoritesRepository: FavoritesRepositoryProtocol {
    static let shared = FavoritesRepository()

    private let persistenceController: PersistenceController
    private let legacyStorageKey = "FavoriteListsStorage"
    private let legacyGuestIdentifier = "guest"

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        Task {
            await migrateLegacyFavoritesIfNeeded()
        }
        AppLogger.log("Favorites repository initialized", category: .persistence)
    }

    func fetchLists(for userIdentifier: String) async throws -> [FavoriteList] {
        AppLogger.log("Fetching favorite lists", category: .persistence)
        return try persistenceController.performRead { context in
            let request = FavoriteListEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
            return try context.fetch(request).map(mapFavoriteList)
        }
    }

    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) async throws {
        let sourceIdentifiers = Array(Set(legacyUserIdentifiers)).filter { $0 != userIdentifier }
        guard sourceIdentifiers.isEmpty == false else { return }

        let didChange = try persistenceController.performWrite { context in
            var destinationLists = try fetchListEntities(for: userIdentifier, context: context)
            var destinationListsByName = Dictionary(
                uniqueKeysWithValues: destinationLists.map { ($0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current), $0) }
            )
            var didChange = false

            for sourceIdentifier in sourceIdentifiers {
                let sourceLists = try fetchListEntities(for: sourceIdentifier, context: context)

                for sourceList in sourceLists {
                    let normalizedName = sourceList.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)

                    if let destinationList = destinationListsByName[normalizedName] {
                        mergeMovies(from: sourceList, into: destinationList, context: context)
                        context.delete(sourceList)
                    } else {
                        sourceList.userIdentifier = userIdentifier
                        destinationLists.append(sourceList)
                        destinationListsByName[normalizedName] = sourceList
                    }

                    didChange = true
                }
            }

            return didChange
        }

        if didChange {
            AppLogger.log("Adopted favorite lists", category: .persistence, level: .success)
        }
    }

    func createList(named name: String, userIdentifier: String) async throws -> FavoriteList {
        let list = try persistenceController.performWrite { context in
            let entity = FavoriteListEntity(context: context)
            entity.id = UUID()
            entity.name = name
            entity.userIdentifier = userIdentifier
            entity.createdAt = Date()
            entity.movies = []
            return mapFavoriteList(entity)
        }
        AppLogger.log("Persisted favorite list", category: .persistence, level: .success)
        return list
    }

    func renameList(listID: UUID, name: String, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }
            list.name = name
        }
        AppLogger.log("Renamed favorite list", category: .persistence, level: .success)
    }

    func deleteList(listID: UUID, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }
            context.delete(list)
        }
        AppLogger.log("Deleted favorite list", category: .persistence, level: .success)
    }

    func add(movie: Movie, to listID: UUID, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }

            if list.movies.contains(where: { $0.movieID == Int64(movie.id) }) {
                return
            }

            let entity = FavoriteMovieEntity(context: context)
            entity.movieID = Int64(movie.id)
            entity.title = movie.title
            entity.posterPath = movie.posterPath
            entity.releaseDate = movie.releaseDate
            if let voteAverage = movie.voteAverage {
                entity.voteAverage = NSNumber(value: voteAverage)
            }
            entity.list = list
        }
        AppLogger.log("Persisted favorite movie", category: .persistence, level: .success)
    }

    func remove(movieID: Int, from listID: UUID, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }

            for movie in list.movies where movie.movieID == Int64(movieID) {
                context.delete(movie)
            }
        }
        AppLogger.log("Deleted favorite movie from list", category: .persistence, level: .success)
    }

    func remove(movieID: Int, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            let request = FavoriteMovieEntity.fetchRequest()
            request.predicate = NSPredicate(format: "movieID == %lld AND list.userIdentifier == %@", Int64(movieID), userIdentifier)

            let movies = try context.fetch(request)
            for movie in movies {
                context.delete(movie)
            }
        }
        AppLogger.log("Deleted favorite movie from all lists", category: .persistence, level: .success)
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard
                let sourceList = try fetchListEntity(listID: sourceListID, userIdentifier: userIdentifier, context: context),
                let destinationList = try fetchListEntity(listID: destinationListID, userIdentifier: userIdentifier, context: context),
                let movieEntity = sourceList.movies.first(where: { $0.movieID == Int64(movieID) })
            else {
                return
            }

            if destinationList.movies.contains(where: { $0.movieID == Int64(movieID) }) {
                context.delete(movieEntity)
            } else {
                movieEntity.list = destinationList
            }
        }
        AppLogger.log("Moved favorite movie", category: .persistence, level: .success)
    }

    private func fetchListEntity(listID: UUID, userIdentifier: String, context: NSManagedObjectContext) throws -> FavoriteListEntity? {
        let request = FavoriteListEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@ AND userIdentifier == %@", listID as CVarArg, userIdentifier)
        return try context.fetch(request).first
    }

    private func fetchListEntities(for userIdentifier: String, context: NSManagedObjectContext) throws -> [FavoriteListEntity] {
        let request = FavoriteListEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
        return try context.fetch(request)
    }

    private func mergeMovies(from sourceList: FavoriteListEntity, into destinationList: FavoriteListEntity, context: NSManagedObjectContext) {
        let existingMovieIDs = Set(destinationList.movies.map(\.movieID))
        let sourceMovies = Array(sourceList.movies)

        for movie in sourceMovies {
            guard existingMovieIDs.contains(movie.movieID) == false else { continue }
            movie.list = destinationList
        }

        for duplicateMovie in sourceMovies where existingMovieIDs.contains(duplicateMovie.movieID) {
            context.delete(duplicateMovie)
        }
    }

    private func migrateLegacyFavoritesIfNeeded() async {
        let userDefaults = UserDefaults.standard
        guard
            let data = userDefaults.data(forKey: legacyStorageKey),
            let lists = try? JSONDecoder().decode([FavoriteList].self, from: data)
        else {
            return
        }

        AppLogger.log("Starting legacy favorites migration", category: .persistence, level: .warning)

        if let existing = try? await fetchLists(for: legacyGuestIdentifier), existing.isEmpty == false {
            if legacyFavoritesMigrationMatchesSource(lists, importedLists: existing) {
                userDefaults.removeObject(forKey: legacyStorageKey)
            }
            return
        }

        do {
            try importLegacyFavorites(lists)
            let importedLists = try await fetchLists(for: legacyGuestIdentifier)

            guard legacyFavoritesMigrationMatchesSource(lists, importedLists: importedLists) else {
                AppLogger.log("Legacy favorites migration verification failed", category: .persistence, level: .error)
                return
            }

            userDefaults.removeObject(forKey: legacyStorageKey)
            AppLogger.log("Legacy favorites migration finished", category: .persistence, level: .success)
        } catch {
            AppLogger.log("Legacy favorites migration failed", category: .persistence, level: .error)
        }
    }

    private func importLegacyFavorites(_ lists: [FavoriteList]) throws {
        try persistenceController.performWrite { context in
            for list in lists {
                let entity = FavoriteListEntity(context: context)
                entity.id = list.id
                entity.name = list.name
                entity.userIdentifier = legacyGuestIdentifier
                entity.createdAt = Date()

                for movie in list.movies {
                    let movieEntity = FavoriteMovieEntity(context: context)
                    movieEntity.movieID = Int64(movie.id)
                    movieEntity.title = movie.title
                    movieEntity.posterPath = movie.posterPath
                    movieEntity.releaseDate = movie.releaseDate
                    if let voteAverage = movie.voteAverage {
                        movieEntity.voteAverage = NSNumber(value: voteAverage)
                    }
                    movieEntity.list = entity
                }
            }
        }
    }

    private func legacyFavoritesMigrationMatchesSource(_ sourceLists: [FavoriteList], importedLists: [FavoriteList]) -> Bool {
        guard sourceLists.count == importedLists.count else { return false }

        let importedByName = Dictionary(
            uniqueKeysWithValues: importedLists.map {
                ($0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current), $0)
            }
        )

        for sourceList in sourceLists {
            let normalizedName = sourceList.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard let importedList = importedByName[normalizedName] else { return false }

            let sourceMovieIDs = Set(sourceList.movies.map(\.id))
            let importedMovieIDs = Set(importedList.movies.map(\.id))
            guard sourceMovieIDs == importedMovieIDs else { return false }
        }

        return true
    }
}

private func mapFavoriteList(_ entity: FavoriteListEntity) -> FavoriteList {
    let movies = entity.movies
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        .map { movieEntity in
            FavoriteMovie(
                id: Int(movieEntity.movieID),
                title: movieEntity.title,
                posterPath: movieEntity.posterPath,
                releaseDate: movieEntity.releaseDate,
                voteAverage: movieEntity.voteAverage?.doubleValue
            )
        }

    return FavoriteList(id: entity.id, name: entity.name, movies: movies)
}
