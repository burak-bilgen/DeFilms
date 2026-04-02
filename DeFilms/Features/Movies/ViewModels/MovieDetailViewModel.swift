//
//  MovieDetailViewModel.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published private(set) var detail: MovieDetail?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let movie: Movie

    private let networkService: NetworkServiceProtocol
    private var hasLoaded = false

    init(movie: Movie, networkService: NetworkServiceProtocol) {
        self.movie = movie
        self.networkService = networkService
    }

    var title: String {
        detail?.title ?? movie.title
    }

    var overview: String {
        let value = detail?.overview ?? movie.overview
        return value?.isEmpty == false ? value ?? "" : Localization.string("movies.detail.overview.empty")
    }

    var heroPosterURL: URL? {
        detail?.backdropURL ?? movie.backdropURL ?? detail?.posterURL ?? movie.posterURL
    }

    var posterURL: URL? {
        detail?.posterURL ?? movie.posterURL
    }

    var releaseYear: String {
        detail?.releaseYear ?? movie.releaseYear
    }

    var ratingText: String? {
        let rating = detail?.voteAverage ?? movie.voteAverage
        guard let rating else { return nil }
        return String(format: "%.1f", rating)
    }

    var runtimeText: String? {
        detail?.runtimeText
    }

    var genreNames: [String] {
        detail?.genres.map(\.name) ?? []
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await load()
    }

    func reloadForLanguageChange() async {
        hasLoaded = true
        await load()
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            AppLogger.log("Loading detail for movie \(movie.id)", category: .movie)
            let response: MovieDetail = try await networkService.request(
                endpoint: TMDBEndpoint.movieDetails(movieID: movie.id)
            )
            detail = response
            AppLogger.log("Loaded detail for movie \(movie.id)", category: .movie, level: .success)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.detail.error")
            errorMessage = message
            ToastCenter.shared.showError(message)
            AppLogger.log("Detail load failed for movie \(movie.id)", category: .movie, level: .error)
        }

        isLoading = false
    }
}
