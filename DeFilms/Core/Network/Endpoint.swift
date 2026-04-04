//
//  Endpoint.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    func queryItems(for language: AppLanguage) -> [URLQueryItem]
}

extension Endpoint {
    func queryItems(for language: AppLanguage) -> [URLQueryItem] {
        []
    }
}
