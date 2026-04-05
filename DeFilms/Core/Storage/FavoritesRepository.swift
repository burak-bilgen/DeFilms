//
//  FavoritesRepository.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import CoreData
import Foundation

protocol FavoritesRepositoryProtocol {
    func fetchLists(for userIdentifier: String) throws -> [FavoriteList]
    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) throws
    func createList(named name: String, userIdentifier: String) throws -> FavoriteList
    func renameList(listID: UUID, name: String, userIdentifier: String) throws
    func deleteList(listID: UUID, userIdentifier: String) throws
    func add(movie: Movie, to listID: UUID, userIdentifier: String) throws
    func remove(movieID: Int, from listID: UUID, userIdentifier: String) throws
    func remove(movieID: Int, userIdentifier: String) throws
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) throws
}

final class FavoritesRepository: FavoritesRepositoryProtocol {
    static let shared = FavoritesRepository()

    private let persistenceController: PersistenceController
    private let legacyStorageKey = "FavoriteListsStorage"

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        migrateLegacyFavoritesIfNeeded()
        AppLogger.log("Favorites repository initialized", category: .persistence)
    }

    func fetchLists(for userIdentifier: String) throws -> [FavoriteList] {
        let request = FavoriteListEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)

        AppLogger.log("Fetching favorite lists", category: .persistence)
        return try persistenceController.viewContext.fetch(request).map(mapList)
    }

    func adoptListsIfNeeded(for userIdentifier: String, from legacyUserIdentifiers: [String]) throws {
        let sourceIdentifiers = Array(Set(legacyUserIdentifiers)).filter { $0 != userIdentifier }
        guard sourceIdentifiers.isEmpty == false else { return }

        let context = persistenceController.viewContext
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

        if didChange {
            try context.save()
            AppLogger.log("Adopted favorite lists", category: .persistence, level: .success)
        }
    }

    func createList(named name: String, userIdentifier: String) throws -> FavoriteList {
        let context = persistenceController.viewContext
        let entity = FavoriteListEntity(context: context)
        entity.id = UUID()
        entity.name = name
        entity.userIdentifier = userIdentifier
        entity.createdAt = Date()
        entity.movies = []
        try context.save()
        AppLogger.log("Persisted favorite list", category: .persistence, level: .success)
        return mapList(entity)
    }

    func renameList(listID: UUID, name: String, userIdentifier: String) throws {
        let context = persistenceController.viewContext
        guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }
        list.name = name
        try context.save()
        AppLogger.log("Renamed favorite list", category: .persistence, level: .success)
    }

    func deleteList(listID: UUID, userIdentifier: String) throws {
        let context = persistenceController.viewContext
        guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }
        context.delete(list)
        try context.save()
        AppLogger.log("Deleted favorite list", category: .persistence, level: .success)
    }

    func add(movie: Movie, to listID: UUID, userIdentifier: String) throws {
        let context = persistenceController.viewContext
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

        try context.save()
        AppLogger.log("Persisted favorite movie", category: .persistence, level: .success)
    }

    func remove(movieID: Int, from listID: UUID, userIdentifier: String) throws {
        let context = persistenceController.viewContext
        guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }

        for movie in list.movies where movie.movieID == Int64(movieID) {
            context.delete(movie)
        }

        try context.save()
        AppLogger.log("Deleted favorite movie from list", category: .persistence, level: .success)
    }

    func remove(movieID: Int, userIdentifier: String) throws {
        let context = persistenceController.viewContext
        let request = FavoriteMovieEntity.fetchRequest()
        request.predicate = NSPredicate(format: "movieID == %lld AND list.userIdentifier == %@", Int64(movieID), userIdentifier)

        let movies = try context.fetch(request)
        for movie in movies {
            context.delete(movie)
        }
        try context.save()
        AppLogger.log("Deleted favorite movie from all lists", category: .persistence, level: .success)
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) throws {
        let context = persistenceController.viewContext
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

        try context.save()
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

    private func migrateLegacyFavoritesIfNeeded() {
        let userDefaults = UserDefaults.standard
        guard
            let data = userDefaults.data(forKey: legacyStorageKey),
            let lists = try? JSONDecoder().decode([FavoriteList].self, from: data)
        else {
            return
        }

        let guestIdentifier = "guest"
        AppLogger.log("Starting legacy favorites migration", category: .persistence, level: .warning)

        if let existing = try? fetchLists(for: guestIdentifier), existing.isEmpty == false {
            userDefaults.removeObject(forKey: legacyStorageKey)
            return
        }

        for list in lists {
            do {
                let createdList = try createList(named: list.name, userIdentifier: guestIdentifier)
                for movie in list.movies {
                    let mappedMovie = Movie(
                        id: movie.id,
                        title: movie.title,
                        overview: nil,
                        posterPath: movie.posterPath,
                        backdropPath: nil,
                        releaseDate: movie.releaseDate,
                        voteAverage: movie.voteAverage,
                        genreIDs: nil
                    )
                    try add(movie: mappedMovie, to: createdList.id, userIdentifier: guestIdentifier)
                }
            } catch {
                continue
            }
        }

        userDefaults.removeObject(forKey: legacyStorageKey)
        AppLogger.log("Legacy favorites migration finished", category: .persistence, level: .success)
    }

    private func mapList(_ entity: FavoriteListEntity) -> FavoriteList {
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
}
