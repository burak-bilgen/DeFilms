//
//  MovieResponse.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

struct MovieResponse: Codable {
    let results: [Movie]
}

struct Movie: Codable, Identifiable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: APIConfig.imageBaseURL + path)
    }

    var releaseYear: String {
        guard let date = releaseDate, date.count >= 4 else { return "N/A" }
        return String(date.prefix(4))
    }
}
