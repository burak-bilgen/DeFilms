//
//  CoreDataEntities.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import CoreData
import Foundation

@objc(FavoriteListEntity)
final class FavoriteListEntity: NSManagedObject {}

extension FavoriteListEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<FavoriteListEntity> {
        NSFetchRequest<FavoriteListEntity>(entityName: "FavoriteListEntity")
    }

    @NSManaged var createdAt: Date
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var userIdentifier: String
    @NSManaged var movies: Set<FavoriteMovieEntity>
}

@objc(FavoriteMovieEntity)
final class FavoriteMovieEntity: NSManagedObject {}

extension FavoriteMovieEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<FavoriteMovieEntity> {
        NSFetchRequest<FavoriteMovieEntity>(entityName: "FavoriteMovieEntity")
    }

    @NSManaged var movieID: Int64
    @NSManaged var posterPath: String?
    @NSManaged var releaseDate: String?
    @NSManaged var title: String
    @NSManaged var voteAverage: NSNumber?
    @NSManaged var list: FavoriteListEntity
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
