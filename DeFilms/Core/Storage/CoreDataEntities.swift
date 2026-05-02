
import CoreData
import Foundation

@objc(MovieListEntity)
final class MovieListEntity: NSManagedObject {}

extension MovieListEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<MovieListEntity> {
        NSFetchRequest<MovieListEntity>(entityName: "MovieListEntity")
    }

    @NSManaged var createdAt: Date
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var userIdentifier: String
    @NSManaged var movies: Set<ListedMovieEntity>
}

@objc(ListedMovieEntity)
final class ListedMovieEntity: NSManagedObject {}

extension ListedMovieEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<ListedMovieEntity> {
        NSFetchRequest<ListedMovieEntity>(entityName: "ListedMovieEntity")
    }

    @NSManaged var movieID: Int64
    @NSManaged var posterPath: String?
    @NSManaged var releaseDate: String?
    @NSManaged var title: String
    @NSManaged var voteAverage: NSNumber?
    @NSManaged var list: MovieListEntity
}

@objc(RecentSearchEntity)
final class RecentSearchEntity: NSManagedObject {}

extension RecentSearchEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<RecentSearchEntity> {
        NSFetchRequest<RecentSearchEntity>(entityName: "RecentSearchEntity")
    }

    @NSManaged var createdAt: Date
    @NSManaged var id: UUID
    @NSManaged var query: String
    @NSManaged var userIdentifier: String
}
