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
    @Published var popularMovies: [Movie] = []
    @Published var searchResults: [Movie] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchHistory: [String] = []
    @Published var filterYear: String = ""
    @Published var minRating: Double = 0
    @Published var selectedGenreID: Int?
    @Published var sortOption: MovieSortOption = .titleAsc
    @Published private(set) var genres: [MovieGenre] = []

    @Published var appliedFilters: MovieFilterState = .empty
    @Published var appliedSortOption: MovieSortOption = .titleAsc

    private let networkService: NetworkServiceProtocol
    private let historyKey = "MovieSearchHistory"
    private let historyLimit = 10
    private var searchTask: Task<Void, Never>?

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
        loadHistory()
    }

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        log("Search started", details: ["query": trimmedQuery])

        do {
            let response: MovieResponse = try await networkService.request(
                endpoint: TMDBEndpoint.searchMovie(query: trimmedQuery, page: 1)
            )
            searchResults = response.results
            updateHistory(with: trimmedQuery)
            log("Search success", details: ["count": "\(response.results.count)"])
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Bir hata oluştu."
            log("Search failed", details: ["error": error.localizedDescription])
        }
    }

    func loadPopularMoviesIfNeeded() async {
        if !popularMovies.isEmpty {
            return
        }

        isLoading = true
        defer { isLoading = false }

        log("Popular fetch started", details: nil)

        do {
            let response: MovieResponse = try await networkService.request(
                endpoint: TMDBEndpoint.popularMovies(page: 1)
            )
            popularMovies = response.results
            log("Popular fetch success", details: ["count": "\(response.results.count)"])
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Bir hata oluştu."
            log("Popular fetch failed", details: ["error": error.localizedDescription])
        }
    }

    func loadGenresIfNeeded() async {
        if !genres.isEmpty {
            return
        }

        log("Genre fetch started", details: nil)

        do {
            let response: MovieGenreResponse = try await networkService.request(
                endpoint: TMDBEndpoint.genreList
            )
            genres = response.genres.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            log("Genre fetch success", details: ["count": "\(response.genres.count)"])
        } catch {
            log("Genre fetch failed", details: ["error": error.localizedDescription])
        }
    }

    func applyFilters() {
        appliedFilters = MovieFilterState(
            year: filterYear,
            minRating: minRating,
            genreID: selectedGenreID
        )
    }

    func applySort() {
        appliedSortOption = sortOption
    }

    func resetFilters() {
        filterYear = ""
        minRating = 0
        selectedGenreID = nil
        appliedFilters = .empty
    }

    func resetSort() {
        sortOption = .titleAsc
        appliedSortOption = .titleAsc
    }

    func clearSearchResults() {
        searchResults = []
    }

    func searchDebounced() {
        searchTask?.cancel()
        let currentQuery = query

        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch(for: currentQuery)
        }
    }

    private func performSearch(for query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.query = trimmed
        await search()
    }

    var filteredMovies: [Movie] {
        var results = searchResults

        let trimmedYear = appliedFilters.year.trimmingCharacters(in: .whitespacesAndNewlines)
        if let year = Int(trimmedYear), trimmedYear.count == 4 {
            results = results.filter { $0.releaseYear == String(year) }
        }

        if appliedFilters.minRating > 0 {
            results = results.filter { ($0.voteAverage ?? 0) >= appliedFilters.minRating }
        }

        if let genre = appliedFilters.genreID {
            results = results.filter { ($0.genreIDs ?? []).contains(genre) }
        }

        switch appliedSortOption {
        case .titleAsc:
            results = results.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .dateDesc:
            results = results.sorted { ($0.releaseDateValue ?? .distantPast) > ($1.releaseDateValue ?? .distantPast) }
        case .ratingDesc:
            results = results.sorted { ($0.voteAverage ?? 0) > ($1.voteAverage ?? 0) }
        }

        return results
    }

    private func log(_ message: String, details: [String: String]?) {
        var output = "[MovieSearchViewModel] \(message)"
        if let details = details, !details.isEmpty {
            let formatted = details.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            output += " | \(formatted)"
        }
        print(output)
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
enum MovieSortOption: String, CaseIterable, Identifiable {
    case titleAsc = "Alfabetik"
    case dateDesc = "Yeniden Eskiye"
    case ratingDesc = "Puana Göre"

    var id: String { rawValue }
}

