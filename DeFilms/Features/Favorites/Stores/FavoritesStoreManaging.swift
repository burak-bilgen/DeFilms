//
//  FavoritesStoreManaging.swift
//  DeFilms
//

import Combine
import Foundation

@MainActor
protocol FavoritesStoreManaging: AnyObject {
    var lists: [FavoriteList] { get }
    var listsPublisher: AnyPublisher<[FavoriteList], Never> { get }

    func createList(named name: String) async -> FavoriteList?
    func renameList(listID: UUID, name: String) async -> Bool
    func deleteList(listID: UUID) async
    func add(movie: Movie, to listID: UUID) async
    func remove(movieID: Int, from listID: UUID) async
    func move(movieID: Int, from sourceListID: UUID, to destinationListID: UUID) async
    func list(withID listID: UUID) -> FavoriteList?
}
