//
//  TMDBEndpoint.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

enum TMDBEndpoint: Endpoint {
    case searchMovie(query: String, page: Int)

    var path: String {
        switch self {
        case .searchMovie:
            return "/search/movie"
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
        }
    }
}
