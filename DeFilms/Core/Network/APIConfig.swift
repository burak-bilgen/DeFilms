//
//  APIConfig.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

struct APIConfig {
    private static let apiKeyInfoKey = "TMDBApiKey"

    static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String
    }

    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p/w500"
}
