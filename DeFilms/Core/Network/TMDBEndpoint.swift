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
    case upcomingMovies(page: Int)
    case nowPlayingMovies(page: Int)
    case topRatedMovies(page: Int)
    case movieDetails(movieID: Int)
    case genreList

    var path: String {
        switch self {
        case .searchMovie:
            return "/search/movie"
        case .popularMovies:
            return "/movie/popular"
        case .upcomingMovies:
            return "/movie/upcoming"
        case .nowPlayingMovies:
            return "/movie/now_playing"
        case .topRatedMovies:
            return "/movie/top_rated"
        case let .movieDetails(movieID):
            return "/movie/\(movieID)"
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
        case let .upcomingMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .nowPlayingMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .topRatedMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case .movieDetails:
            return []
        case .genreList:
            return []
        }
    }
}
