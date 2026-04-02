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
        case .invalidURL: return "Geçersiz URL."
        case .invalidResponse: return "Sunucudan geçersiz yanıt alındı."
        case .decodingError: return "Veri işlenirken bir hata oluştu."
        case .serverError(let statusCode): return "Sunucu hatası. Kod: \(statusCode)"
        case .missingAPIKey: return "API anahtarı bulunamadı."
        }
    }
}
