//
//  NetworkError.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(statusCode: Int)
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .invalidURL: return Localization.string("network.error.invalidURL")
        case .invalidResponse: return Localization.string("network.error.invalidResponse")
        case .decodingError: return Localization.string("network.error.decoding")
        case .serverError(let statusCode): return Localization.string("network.error.server", statusCode)
        case .missingAPIKey: return Localization.string("network.error.missingAPIKey")
        }
    }
}
