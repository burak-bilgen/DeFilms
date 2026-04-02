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
            throw NetworkError.missingAPIKey
        }

        guard var urlComponents = URLComponents(string: APIConfig.baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        var queryItems = endpoint.queryItems
        
        queryItems.append(URLQueryItem(name: "api_key", value: apiKey))
        
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
}


