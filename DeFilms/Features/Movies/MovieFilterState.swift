//
//  MovieFilterState.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

struct MovieFilterState: Equatable {
    var year: String
    var minRating: Double
    var genreID: Int?

    static let empty = MovieFilterState(year: "", minRating: 0, genreID: nil)
}
