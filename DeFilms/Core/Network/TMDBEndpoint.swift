//
//  TMDBEndpoint.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

enum TMDBEndpoint: Endpoint {
    enum TrendingWindow: String {
        case day
        case week
    }

    case searchMovie(query: String, page: Int)
    case popularMovies(page: Int)
    case upcomingMovies(page: Int)
    case nowPlayingMovies(page: Int)
    case topRatedMovies(page: Int)
    case trendingMovies(window: TrendingWindow, page: Int)
    case movieDetails(movieID: Int)
    case movieVideos(movieID: Int, languageCode: String?)
    case movieImages(movieID: Int)
    case movieCredits(movieID: Int)
    case personExternalIDs(personID: Int)
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
        case let .trendingMovies(window, _):
            return "/trending/movie/\(window.rawValue)"
        case let .movieDetails(movieID):
            return "/movie/\(movieID)"
        case let .movieVideos(movieID, _):
            return "/movie/\(movieID)/videos"
        case let .movieImages(movieID):
            return "/movie/\(movieID)/images"
        case let .movieCredits(movieID):
            return "/movie/\(movieID)/credits"
        case let .personExternalIDs(personID):
            return "/person/\(personID)/external_ids"
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
        case let .trendingMovies(_, page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case .movieDetails:
            return []
        case let .movieVideos(_, languageCode):
            guard let languageCode else { return [] }
            return [
                URLQueryItem(name: "language", value: languageCode)
            ]
        case .movieImages:
            return [
                URLQueryItem(
                    name: "include_image_language",
                    value: "\(AppPreferences.persistedLanguage.rawValue),en,null"
                )
            ]
        case .movieCredits:
            return []
        case .personExternalIDs:
            return []
        case .genreList:
            return []
        }
    }
}
