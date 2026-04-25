
import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

enum NetworkRetryPolicy: Equatable {
    case none
    case transient(maxRetryCount: Int)
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var retryPolicy: NetworkRetryPolicy { get }
    func queryItems(for language: AppLanguage) -> [URLQueryItem]
}

extension Endpoint {
    var cachePolicy: URLRequest.CachePolicy {
        .reloadRevalidatingCacheData
    }

    var retryPolicy: NetworkRetryPolicy {
        .transient(maxRetryCount: 1)
    }

    func queryItems(for language: AppLanguage) -> [URLQueryItem] {
        []
    }
}
