//
//  MovieSearchViewModel.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation

@MainActor
final class MovieSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var movies: [Movie] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchHistory: [String] = []

    private let networkService: NetworkServiceProtocol
    private let historyKey = "MovieSearchHistory"
    private let historyLimit = 10

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        loadHistory()
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            errorMessage = "Arama alanı boş olamaz."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: MovieResponse = try await networkService.request(
                endpoint: TMDBEndpoint.searchMovie(query: trimmedQuery, page: 1)
            )
            movies = response.results
            updateHistory(with: trimmedQuery)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Bir hata oluştu."
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func loadHistory() {
        let stored = UserDefaults.standard.stringArray(forKey: historyKey) ?? []
        searchHistory = stored
    }

    private func updateHistory(with item: String) {
        var updated = searchHistory.filter { $0.caseInsensitiveCompare(item) != .orderedSame }
        updated.insert(item, at: 0)
        if updated.count > historyLimit {
            updated = Array(updated.prefix(historyLimit))
        }
        searchHistory = updated
        UserDefaults.standard.set(updated, forKey: historyKey)
    }
}
