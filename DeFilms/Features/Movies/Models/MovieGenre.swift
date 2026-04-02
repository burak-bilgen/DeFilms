//
//  MovieGenre.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

struct MovieGenreResponse: Codable {
    let genres: [MovieGenre]
}

struct MovieGenre: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
}
