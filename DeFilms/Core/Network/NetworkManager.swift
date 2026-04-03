//
//  NetworkManager.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

final class NetworkManager: NetworkServiceProtocol {
    static let shared = NetworkManager()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        guard let apiKey = APIConfig.apiKey, !apiKey.isEmpty else {
            AppLogger.log("Missing API key", category: .network, level: .error)
            throw NetworkError.missingAPIKey
        }

        guard var urlComponents = URLComponents(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        var queryItems = endpoint.queryItems
        
        queryItems.append(URLQueryItem(name: "api_key", value: apiKey))

        if !queryItems.contains(where: { $0.name == "language" }) {
            queryItems.append(URLQueryItem(name: "language", value: AppPreferences.persistedLanguage.tmdbLanguageCode))
        }
        
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        AppLogger.log("Request started: \(request.httpMethod ?? "") \(url.absoluteString)", category: .network)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.log("Invalid HTTP response", category: .network, level: .error)
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            AppLogger.log("Server responded with status \(httpResponse.statusCode)", category: .network, level: .error)
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(T.self, from: data)
            AppLogger.log("Request completed successfully", category: .network, level: .success)
            return decoded
        } catch {
            AppLogger.log("Decoding failed for \(url.absoluteString)", category: .network, level: .error)
            throw NetworkError.decodingError
        }
    }
}
