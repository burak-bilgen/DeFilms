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
    private let decoder: JSONDecoder
    private let requestBuilder: NetworkRequestBuilding

    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        requestBuilder: NetworkRequestBuilding = NetworkRequestBuilder()
    ) {
        self.session = session
        self.decoder = decoder
        self.requestBuilder = requestBuilder
    }

    func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let request: URLRequest
        do {
            request = try requestBuilder.makeRequest(endpoint: endpoint)
        } catch let error as NetworkError {
            if case .missingAPIKey = error {
                AppLogger.log("Missing API key", category: .network, level: .error)
            }
            throw error
        }

        AppLogger.log("Request started", category: .network)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            AppLogger.log("Request cancelled", category: .network, level: .warning)
            throw NetworkError.cancelled
        } catch let error as URLError {
            AppLogger.log("Transport error: \(error.code.rawValue)", category: .network, level: .error)
            throw mapTransportError(error)
        } catch {
            AppLogger.log("Unknown request failure", category: .network, level: .error)
            throw NetworkError.requestFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.log("Invalid HTTP response", category: .network, level: .error)
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            AppLogger.log("Server responded with status \(httpResponse.statusCode)", category: .network, level: .error)
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            let decoded = try decoder.decode(T.self, from: data)
            AppLogger.log("Request completed successfully", category: .network, level: .success)
            return decoded
        } catch {
            AppLogger.log("Response decoding failed", category: .network, level: .error)
            throw NetworkError.decodingError
        }
    }

    private func mapTransportError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .timedOut:
            return .requestTimedOut
        case .cancelled:
            return .cancelled
        default:
            return .requestFailed
        }
    }
}
