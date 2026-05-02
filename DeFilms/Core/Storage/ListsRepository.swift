
import CoreData
import Foundation

protocol ListsRepositoryProtocol {
    func fetchLists(for userIdentifier: String) async throws -> [MovieList]
    func createList(named name: String, userIdentifier: String) async throws -> MovieList
    func renameList(listID: UUID, name: String, userIdentifier: String) async throws
    func deleteList(listID: UUID, userIdentifier: String) async throws
    func deleteLists(for userIdentifiers: [String]) async throws
    func add(movie: Movie, to listID: UUID, userIdentifier: String) async throws
    func remove(movieID: Int, from listID: UUID, userIdentifier: String) async throws
    func remove(movieID: Int, userIdentifier: String) async throws
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) async throws
}

final class ListsRepository: ListsRepositoryProtocol {
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        AppLogger.log("Lists repository initialized", category: .persistence)
    }

    func fetchLists(for userIdentifier: String) async throws -> [MovieList] {
        AppLogger.log("Fetching movie lists", category: .persistence)
        return try persistenceController.performRead { context in
            let request = MovieListEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
            return try context.fetch(request).map(mapMovieList)
        }
    }

    func createList(named name: String, userIdentifier: String) async throws -> MovieList {
        let list = try persistenceController.performWrite { context in
            let entity = MovieListEntity(context: context)
            entity.id = UUID()
            entity.name = name
            entity.userIdentifier = userIdentifier
            entity.createdAt = Date()
            entity.movies = []
            return mapMovieList(entity)
        }
        AppLogger.log("Persisted movie list", category: .persistence, level: .success)
        return list
    }

    func renameList(listID: UUID, name: String, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }
            guard normalizedListName(list.name) != normalizedListName(name) else { return }
            list.name = name
        }
        AppLogger.log("Renamed movie list", category: .persistence, level: .success)
    }

    func deleteList(listID: UUID, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }
            context.delete(list)
        }
        AppLogger.log("Deleted movie list", category: .persistence, level: .success)
    }

    func deleteLists(for userIdentifiers: [String]) async throws {
        let identifiers = normalizedUserIdentifiers(userIdentifiers)
        guard !identifiers.isEmpty else { return }

        try persistenceController.performWrite { context in
            let request = MovieListEntity.fetchRequest()
            request.predicate = NSPredicate(format: "userIdentifier IN %@", identifiers)
            try context.fetch(request).forEach(context.delete)
        }
        AppLogger.log("Deleted account-scoped movie lists", category: .persistence, level: .success)
    }

    func add(movie: Movie, to listID: UUID, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }

            if list.movies.contains(where: { $0.movieID == Int64(movie.id) }) {
                return
            }

            let entity = ListedMovieEntity(context: context)
            entity.movieID = Int64(movie.id)
            entity.title = movie.title
            entity.posterPath = movie.posterPath
            entity.releaseDate = movie.releaseDate
            if let voteAverage = movie.voteAverage {
                entity.voteAverage = NSNumber(value: voteAverage)
            }
            entity.list = list
        }
        AppLogger.log("Persisted list movie", category: .persistence, level: .success)
    }

    func remove(movieID: Int, from listID: UUID, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            guard let list = try fetchListEntity(listID: listID, userIdentifier: userIdentifier, context: context) else { return }

            for movie in list.movies where movie.movieID == Int64(movieID) {
                context.delete(movie)
            }
        }
        AppLogger.log("Deleted list movie from list", category: .persistence, level: .success)
    }

    func remove(movieID: Int, userIdentifier: String) async throws {
        try persistenceController.performWrite { context in
            let request = ListedMovieEntity.fetchRequest()
            request.predicate = NSPredicate(format: "movieID == %lld AND list.userIdentifier == %@", Int64(movieID), userIdentifier)

            let movies = try context.fetch(request)
            for movie in movies {
                context.delete(movie)
            }
        }
        AppLogger.log("Deleted list movie from all lists", category: .persistence, level: .success)
    }

    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID, userIdentifier: String) async throws {
        guard sourceListID != destinationListID else { return }

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
        AppLogger.log("Moved list movie", category: .persistence, level: .success)
    }

    private func fetchListEntity(listID: UUID, userIdentifier: String, context: NSManagedObjectContext) throws -> MovieListEntity? {
        let request = MovieListEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@ AND userIdentifier == %@", listID as CVarArg, userIdentifier)
        return try context.fetch(request).first
    }

    private func fetchListEntities(for userIdentifier: String, context: NSManagedObjectContext) throws -> [MovieListEntity] {
        let request = MovieListEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        request.predicate = NSPredicate(format: "userIdentifier == %@", userIdentifier)
        return try context.fetch(request)
    }

    private func normalizedListName(_ name: String) -> String {
        name.normalizedForLookup
    }

    private func normalizedUserIdentifiers(_ identifiers: [String]) -> [String] {
        Array(Set(identifiers.map { $0.trimmed }.filter { !$0.isEmpty }))
    }

    func replaceListsForUITesting(_ lists: [MovieList], userIdentifier: String) throws {
        try persistenceController.performWrite { context in
            let existingLists = try fetchListEntities(for: userIdentifier, context: context)
            existingLists.forEach(context.delete)

            for list in lists {
                let entity = MovieListEntity(context: context)
                entity.id = list.id
                entity.name = list.name
                entity.userIdentifier = userIdentifier
                entity.createdAt = Date()

                for movie in list.movies {
                    let movieEntity = ListedMovieEntity(context: context)
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
}

private func mapMovieList(_ entity: MovieListEntity) -> MovieList {
    let movies = entity.movies
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        .map { movieEntity in
            ListedMovie(
                id: Int(movieEntity.movieID),
                title: movieEntity.title,
                posterPath: movieEntity.posterPath,
                releaseDate: movieEntity.releaseDate,
                voteAverage: movieEntity.voteAverage?.doubleValue
            )
        }

    return MovieList(id: entity.id, name: entity.name, movies: movies)
}
