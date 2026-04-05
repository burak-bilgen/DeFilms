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
    @Published private(set) var trailer: MovieVideo?
    @Published private(set) var gallery: [MovieImageAsset] = []
    @Published private(set) var directors: [MovieCrewMember] = []
    @Published private(set) var cast: [MovieCastMember] = []
    @Published private(set) var streamingPlatforms: [MovieStreamingPlatform] = []
    @Published private(set) var similarMovies: [Movie] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var toastItem: ToastItem?
    @Published var isTrailerPresented = false

    let movie: Movie

    private let service: MovieDetailServicing
    private var didLoadOnce = false
    private var activeLoadRequestID = UUID()

    init(movie: Movie, detailService: MovieDetailServicing) {
        self.movie = movie
        self.service = detailService
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

    var heroSubtitle: String? {
        runtimeText.map { Localization.string("movies.detail.runtimeHero", $0) }
    }

    var heroFacts: [String] {
        [releaseYear, runtimeText]
            .compactMap { value in
                guard let value, !value.isEmpty, value != "--" else { return nil }
                return value
            }
    }

    var galleryURLs: [URL] {
        let galleryURLs = gallery.compactMap(\.imageURL)

        if !galleryURLs.isEmpty {
            return galleryURLs
        }

        return [movie.backdropURL, detail?.backdropURL, movie.posterURL, detail?.posterURL]
            .compactMap { $0 }
            .uniqued()
    }

    var trailerURL: URL? {
        trailer?.watchURL
    }

    var tmdbURL: URL? {
        detail?.tmdbURL
    }

    var hasTrailer: Bool {
        trailerURL != nil
    }

    func loadIfNeeded() async {
        guard !didLoadOnce else { return }
        didLoadOnce = true
        await load()
    }

    func reloadForLanguageChange() async {
        didLoadOnce = true
        await load()
    }

    func load() async {
        let requestID = UUID()
        activeLoadRequestID = requestID
        isLoading = true
        errorMessage = nil
        detail = nil
        trailer = nil
        gallery = []
        directors = []
        cast = []
        streamingPlatforms = []
        similarMovies = []

        do {
            AppLogger.log("Opening movie details", category: .movie)
            let payload = try await service.loadPayload(for: movie)
            guard activeLoadRequestID == requestID else { return }
            detail = payload.detail
            trailer = payload.trailer
            gallery = payload.gallery
            directors = payload.directors
            cast = payload.cast
            streamingPlatforms = payload.streamingPlatforms
            similarMovies = payload.similarMovies
            AppLogger.log("Movie details ready", category: .movie, level: .success)
        } catch {
            guard activeLoadRequestID == requestID else { return }
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.detail.error")
            errorMessage = message
            toastItem = .error(message)
            AppLogger.log("Couldn't load movie details", category: .movie, level: .error)
        }

        guard activeLoadRequestID == requestID else { return }
        isLoading = false
    }

    func presentTrailer() {
        guard hasTrailer else {
            toastItem = .error(Localization.string("movies.detail.trailer.missing"))
            return
        }

        isTrailerPresented = true
    }

    func clearToast() {
        toastItem = nil
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()

        return filter { seen.insert($0).inserted }
    }
}
