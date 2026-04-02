//
//  TMDBEndpoint.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

enum TMDBEndpoint: Endpoint {
    case searchMovie(query: String, page: Int)
    case popularMovies(page: Int)
    case genreList

    var path: String {
        switch self {
        case .searchMovie:
            return "/search/movie"
        case .popularMovies:
            return "/movie/popular"
        case .genreList:
            return "/genre/movie/list"
        }
    }

    var method: HTTPMethod {
        .get
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .searchMovie(query, page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .popularMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case .genreList:
            return []
        }
    }
}
