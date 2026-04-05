//
//  NetworkManager.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

final class NetworkManager: NetworkServiceProtocol {
    static let shared = NetworkManager(session: NetworkManager.makeDefaultSession())

    private struct APIErrorPayload: Decodable {
        let statusMessage: String?

        private enum CodingKeys: String, CodingKey {
            case statusMessage = "status_message"
        }
    }

    private let session: URLSession
    private let decoder: JSONDecoder
    private let requestBuilder: NetworkRequestBuilding

    init(
        session: URLSession = NetworkManager.makeDefaultSession(),
        decoder: JSONDecoder = JSONDecoder(),
        requestBuilder: NetworkRequestBuilding = NetworkRequestBuilder()
    ) {
        self.session = session
        self.decoder = decoder
        self.requestBuilder = requestBuilder
    }

    func request<T: Decodable>(endpoint: Endpoint) async throws -> T {
        let endpointDescription = "\(endpoint.method.rawValue) \(endpoint.path)"
        let request: URLRequest
        do {
            request = try requestBuilder.makeRequest(endpoint: endpoint)
        } catch let error as NetworkError {
            if case .missingAPIKey = error {
                AppLogger.log("Missing API key", category: .network, level: .error)
            }
            throw error
        }

        AppLogger.log("Request started: \(endpointDescription)", category: .network)

        let result: (Data, URLResponse)

        do {
            result = try await performRequest(request, endpoint: endpoint, endpointDescription: endpointDescription)
        } catch let error as NetworkError {
            throw error
        } catch {
            AppLogger.log("Request failed: \(endpointDescription) [unknown]", category: .network, level: .error)
            throw NetworkError.requestFailed
        }

        let (data, response) = result

        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogger.log("Request failed: \(endpointDescription) [invalid-response]", category: .network, level: .error)
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            AppLogger.log(
                "Request failed: \(endpointDescription) [status=\(httpResponse.statusCode)]",
                category: .network,
                level: .error
            )
            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                message: decodeServerErrorMessage(from: data)
            )
        }

        do {
            let decoded = try decoder.decode(T.self, from: data)
            AppLogger.log(
                "Request succeeded: \(endpointDescription) [status=\(httpResponse.statusCode)]",
                category: .network,
                level: .success
            )
            return decoded
        } catch {
            AppLogger.log("Request failed: \(endpointDescription) [decoding]", category: .network, level: .error)
            throw NetworkError.decodingError
        }
    }

    private func performRequest(
        _ request: URLRequest,
        endpoint: Endpoint,
        endpointDescription: String
    ) async throws -> (Data, URLResponse) {
        var attempt = 0

        while true {
            do {
                return try await session.data(for: request)
            } catch is CancellationError {
                AppLogger.log("Request cancelled: \(endpointDescription)", category: .network, level: .warning)
                throw NetworkError.cancelled
            } catch let error as URLError {
                let mappedError = mapTransportError(error)
                // Retry only for short-lived connectivity failures; anything else
                // is surfaced immediately so the caller can decide what to do next.
                if shouldRetry(after: error, policy: endpoint.retryPolicy, attempt: attempt) {
                    attempt += 1
                    AppLogger.log(
                        "Request retrying: \(endpointDescription) [attempt=\(attempt)]",
                        category: .network,
                        level: .warning
                    )
                    continue
                }
                AppLogger.log(
                    "Request failed: \(endpointDescription) [transport=\(error.code.rawValue)]",
                    category: .network,
                    level: .error
                )
                throw mappedError
            }
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

    private func shouldRetry(
        after error: URLError,
        policy: NetworkRetryPolicy,
        attempt: Int
    ) -> Bool {
        guard case let .transient(maxRetryCount) = policy, attempt < maxRetryCount else {
            return false
        }

        switch error.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private func decodeServerErrorMessage(from data: Data) -> String? {
        try? decoder.decode(APIErrorPayload.self, from: data).statusMessage
    }

    private static func makeDefaultSession() -> URLSession {
        // Keep the session conservative for a content app: prefer fresh data,
        // but still allow the system to reuse cached responses when possible.
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadRevalidatingCacheData
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration)
    }
}
