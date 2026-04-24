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
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: apiKeyInfoKey) as? String else {
            return nil
        }

        let apiKey = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty, !apiKey.hasPrefix("$(") else {
            return nil
        }

        return apiKey
    }

    static let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p/w500"
}
