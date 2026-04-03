//
//  MovieResponse.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

struct MovieResponse: Codable {
    let page: Int
    let results: [Movie]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}

struct MovieVideoResponse: Codable {
    let results: [MovieVideo]
}

struct MovieVideo: Codable, Equatable {
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool

    var watchURL: URL? {
        switch site.lowercased() {
        case "youtube":
            return URL(string: "https://www.youtube.com/watch?v=\(key)")
        case "vimeo":
            return URL(string: "https://vimeo.com/\(key)")
        default:
            return nil
        }
    }
}

struct MovieImageResponse: Codable {
    let backdrops: [MovieImageAsset]
    let posters: [MovieImageAsset]
}

struct MovieCreditsResponse: Codable {
    let cast: [MovieCastMember]
    let crew: [MovieCrewMember]
}

struct MovieCastMember: Codable, Equatable, Identifiable {
    let id: Int
    let name: String
    let character: String?
    let profilePath: String?
    var imdbID: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }

    var imageURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: APIConfig.imageBaseURL + profilePath)
    }

    var imdbURL: URL? {
        guard let imdbID, imdbID.isEmpty == false else { return nil }
        return URL(string: "https://www.imdb.com/name/\(imdbID)")
    }
}

struct PersonExternalIDsResponse: Codable {
    let imdbID: String?

    enum CodingKeys: String, CodingKey {
        case imdbID = "imdb_id"
    }
}

struct MovieCrewMember: Codable, Equatable, Identifiable {
    let id: Int
    let name: String
    let job: String
    let profilePath: String?
    var imdbID: String? = nil

    enum CodingKeys: String, CodingKey {
        case id, name, job
        case profilePath = "profile_path"
    }

    var imageURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: APIConfig.imageBaseURL + profilePath)
    }

    var imdbURL: URL? {
        guard let imdbID, imdbID.isEmpty == false else { return nil }
        return URL(string: "https://www.imdb.com/name/\(imdbID)")
    }
}

struct MovieImageAsset: Codable, Equatable {
    let filePath: String

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
    }

    var imageURL: URL? {
        URL(string: APIConfig.imageBaseURL + filePath)
    }
}

struct MovieDetail: Codable, Equatable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let runtime: Int?
    let imdbID: String?
    let genres: [MovieGenre]

    enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres
        case imdbID = "imdb_id"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: APIConfig.imageBaseURL + path)
    }

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: APIConfig.imageBaseURL + path)
    }

    var releaseYear: String {
        guard let date = releaseDate, date.count >= 4 else { return "--" }
        return String(date.prefix(4))
    }

    var runtimeText: String? {
        guard let runtime, runtime > 0 else { return nil }
        let hours = runtime / 60
        let minutes = runtime % 60

        if hours > 0 {
            return Localization.string("movies.runtime.hoursMinutes", hours, minutes)
        }

        return Localization.string("movies.runtime.minutes", minutes)
    }

    var imdbURL: URL? {
        guard let imdbID, imdbID.isEmpty == false else { return nil }
        return URL(string: "https://www.imdb.com/title/\(imdbID)")
    }
}

struct Movie: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let title: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let genreIDs: [Int]?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case genreIDs = "genre_ids"
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: APIConfig.imageBaseURL + path)
    }

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: APIConfig.imageBaseURL + path)
    }

    var releaseYear: String {
        guard let date = releaseDate, date.count >= 4 else { return "--" }
        return String(date.prefix(4))
    }

    var releaseDateValue: Date? {
        guard let date = releaseDate else { return nil }
        return Movie.dateFormatter.date(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
