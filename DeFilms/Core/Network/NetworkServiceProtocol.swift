//
//  NetworkServiceProtocol.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Foundation

protocol NetworkServiceProtocol {
    func request<T: Decodable>(endpoint: Endpoint) async throws -> T
}

