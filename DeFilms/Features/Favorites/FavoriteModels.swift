//
//  FavoriteModels.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

struct FavoriteMovie: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double?

    init(movie: Movie) {
        self.id = movie.id
        self.title = movie.title
        self.posterPath = movie.posterPath
        self.releaseDate = movie.releaseDate
        self.voteAverage = movie.voteAverage
    }

    init(id: Int, title: String, posterPath: String?, releaseDate: String?, voteAverage: Double?) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
    }
}

struct FavoriteList: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var movies: [FavoriteMovie]
}
