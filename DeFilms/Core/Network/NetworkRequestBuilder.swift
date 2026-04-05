//
//  NetworkRequestBuilder.swift
//  DeFilms
//

import Foundation

protocol NetworkRequestBuilding {
    func makeRequest(endpoint: Endpoint) throws -> URLRequest
}

struct NetworkRequestBuilder: NetworkRequestBuilding {
    let apiKeyProvider: () -> String?
    let languageProvider: () -> AppLanguage
    let timeoutInterval: TimeInterval

    init(
        apiKeyProvider: @escaping () -> String? = { APIConfig.apiKey },
        languageProvider: @escaping () -> AppLanguage = { AppPreferences.persistedLanguage },
        timeoutInterval: TimeInterval = 15
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.languageProvider = languageProvider
        self.timeoutInterval = timeoutInterval
    }

    func makeRequest(endpoint: Endpoint) throws -> URLRequest {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw NetworkError.missingAPIKey
        }

        let language = languageProvider()

        guard var urlComponents = URLComponents(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        var queryItems = endpoint.queryItems(for: language)
        queryItems.append(URLQueryItem(name: "api_key", value: apiKey))

        if !queryItems.contains(where: { $0.name == "language" }) {
            queryItems.append(URLQueryItem(name: "language", value: language.tmdbLanguageCode))
        }

        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url, cachePolicy: endpoint.cachePolicy)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = timeoutInterval
        return request
    }
}
