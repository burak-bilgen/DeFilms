//
//  FavoritesRoute.swift
//  DeFilms
//

import Foundation

enum FavoritesRoute: Hashable {
    case list(UUID)
    case movie(Movie)
}
