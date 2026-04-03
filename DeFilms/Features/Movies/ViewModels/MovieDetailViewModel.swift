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
    @Published private(set) var cast: [MovieCastMember] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var isTrailerPresented = false

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

    var imdbURL: URL? {
        detail?.imdbURL
    }

    var hasTrailer: Bool {
        trailerURL != nil
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
        trailer = nil
        gallery = []
        cast = []

        do {
            AppLogger.log("Loading detail for movie \(movie.id)", category: .movie)
            async let imagesTask: Void = loadImages()
            async let castTask: Void = loadCast()
            async let trailerTask: Void = loadTrailer()

            detail = try await networkService.request(
                endpoint: TMDBEndpoint.movieDetails(movieID: movie.id)
            )
            _ = await (imagesTask, castTask, trailerTask)
            AppLogger.log("Loaded detail for movie \(movie.id)", category: .movie, level: .success)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("movies.detail.error")
            errorMessage = message
            ToastCenter.shared.showError(message)
            AppLogger.log("Detail load failed for movie \(movie.id)", category: .movie, level: .error)
        }

        isLoading = false
    }

    func presentTrailer() {
        guard hasTrailer else {
            ToastCenter.shared.showError(Localization.string("movies.detail.trailer.missing"))
            return
        }

        isTrailerPresented = true
    }

    private func loadImages() async {
        do {
            let imagesResponse: MovieImageResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieImages(movieID: movie.id)
            )
            gallery = Array(imagesResponse.backdrops.prefix(6))
        } catch {
            AppLogger.log("Image load failed for movie \(movie.id)", category: .movie, level: .error)
        }
    }

    private func loadCast() async {
        do {
            let creditsResponse: MovieCreditsResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieCredits(movieID: movie.id)
            )
            let primaryCast = Array(creditsResponse.cast.prefix(6))
            cast = primaryCast
            await enrichCastWithIMDb(primaryCast)
        } catch {
            AppLogger.log("Credits load failed for movie \(movie.id)", category: .movie, level: .error)
        }
    }

    private func loadTrailer() async {
        do {
            let localizedVideos: MovieVideoResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieVideos(movieID: movie.id, languageCode: nil)
            )
            trailer = selectPreferredTrailer(from: localizedVideos.results)

            if trailer == nil, AppPreferences.persistedLanguage != .english {
                let fallbackVideos: MovieVideoResponse = try await networkService.request(
                    endpoint: TMDBEndpoint.movieVideos(movieID: movie.id, languageCode: AppLanguage.english.tmdbLanguageCode)
                )
                trailer = selectPreferredTrailer(from: fallbackVideos.results)
            }
        } catch {
            AppLogger.log("Trailer load failed for movie \(movie.id)", category: .movie, level: .error)
        }
    }

    private func selectPreferredTrailer(from videos: [MovieVideo]) -> MovieVideo? {
        let youtubeVideos = videos.filter { $0.watchURL != nil }

        return youtubeVideos.first(where: { $0.type == "Trailer" && $0.official }) ??
            youtubeVideos.first(where: { $0.type == "Trailer" }) ??
            youtubeVideos.first(where: { $0.official }) ??
            youtubeVideos.first
    }

    private func enrichCastWithIMDb(_ castMembers: [MovieCastMember]) async {
        let enrichedCast = await withTaskGroup(of: MovieCastMember.self) { group in
            for member in castMembers {
                group.addTask { [networkService] in
                    do {
                        let response: PersonExternalIDsResponse = try await networkService.request(
                            endpoint: TMDBEndpoint.personExternalIDs(personID: member.id)
                        )
                        var updatedMember = member
                        updatedMember.imdbID = response.imdbID
                        return updatedMember
                    } catch {
                        return member
                    }
                }
            }

            var collectedMembers: [MovieCastMember] = []
            for await member in group {
                collectedMembers.append(member)
            }
            return collectedMembers
        }

        let castOrder = Dictionary(uniqueKeysWithValues: castMembers.enumerated().map { ($0.element.id, $0.offset) })
        cast = enrichedCast.sorted { lhs, rhs in
            (castOrder[lhs.id] ?? 0) < (castOrder[rhs.id] ?? 0)
        }
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()

        return filter { seen.insert($0).inserted }
    }
}
