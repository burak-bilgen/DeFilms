
import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(statusCode: Int, message: String?)
    case rateLimited(retryAfter: TimeInterval?)
    case missingAPIKey
    case requestFailed
    case requestTimedOut
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL: return Localization.string("network.error.invalidURL")
        case .invalidResponse: return Localization.string("network.error.invalidResponse")
        case .decodingError: return Localization.string("network.error.decoding")
        case let .serverError(statusCode, message):
            return message ?? Localization.string("network.error.server", statusCode)
        case .rateLimited:
            return Localization.string("network.error.rateLimited")
        case .missingAPIKey: return Localization.string("network.error.missingAPIKey")
        case .requestFailed: return Localization.string("network.error.invalidResponse")
        case .requestTimedOut: return Localization.string("network.error.invalidResponse")
        case .cancelled: return nil
        }
    }
}
