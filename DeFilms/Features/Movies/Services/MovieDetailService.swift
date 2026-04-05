//
//  MovieDetailServices.swift
//  DeFilms
//

import Foundation

struct MovieDetailPayload: Equatable {
    let detail: MovieDetail
    let trailer: MovieVideo?
    let gallery: [MovieImageAsset]
    let directors: [MovieCrewMember]
    let cast: [MovieCastMember]
    let streamingPlatforms: [MovieStreamingPlatform]
    let similarMovies: [Movie]
}

@MainActor
protocol MovieDetailServicing {
    func loadPayload(for movie: Movie) async throws -> MovieDetailPayload
}

@MainActor
final class TMDBMovieDetailService: MovieDetailServicing {
    private let networkService: NetworkServiceProtocol
    private let imagePrefetcher: MovieImagePrefetching

    init(
        networkService: NetworkServiceProtocol,
        imagePrefetcher: MovieImagePrefetching
    ) {
        self.networkService = networkService
        self.imagePrefetcher = imagePrefetcher
    }

    func loadPayload(for movie: Movie) async throws -> MovieDetailPayload {
        let detail: MovieDetail = try await networkService.request(
            endpoint: TMDBEndpoint.movieDetails(movieID: movie.id)
        )
        async let galleryTask = loadGallery(movieID: movie.id)
        async let peopleTask = loadPeople(movieID: movie.id)
        async let trailerTask = loadTrailer(movieID: movie.id)
        async let platformsTask = loadStreamingPlatforms(for: movie)
        async let similarMoviesTask = loadSimilarMovies(for: movie)

        let payload = await MovieDetailPayload(
            detail: detail,
            trailer: trailerTask,
            gallery: galleryTask,
            directors: peopleTask.directors,
            cast: peopleTask.cast,
            streamingPlatforms: platformsTask,
            similarMovies: similarMoviesTask
        )

        Task {
            await imagePrefetcher.prefetch(urls: payload.streamingPlatforms.compactMap(\.logoURL))
        }
        Task {
            await imagePrefetcher.prefetch(
                urls: payload.similarMovies.flatMap { movie in
                    [movie.posterURL, movie.backdropURL].compactMap { $0 }
                }
            )
        }

        return payload
    }

    private func loadGallery(movieID: Int) async -> [MovieImageAsset] {
        do {
            let response: MovieImageResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieImages(movieID: movieID)
            )
            return Array(response.backdrops.prefix(6))
        } catch {
            AppLogger.log("Image load failed", category: .movie, level: .error)
            return []
        }
    }

    private func loadPeople(movieID: Int) async -> (directors: [MovieCrewMember], cast: [MovieCastMember]) {
        do {
            let response: MovieCreditsResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieCredits(movieID: movieID)
            )
            return (
                directors: Array(response.crew.filter { $0.job == "Director" }.prefix(3)),
                cast: Array(response.cast.prefix(6))
            )
        } catch {
            AppLogger.log("Credits load failed", category: .movie, level: .error)
            return ([], [])
        }
    }

    private func loadTrailer(movieID: Int) async -> MovieVideo? {
        do {
            let localizedVideos: MovieVideoResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieVideos(movieID: movieID, languageCode: nil)
            )
            let localizedTrailer = selectPreferredTrailer(from: localizedVideos.results)

            if localizedTrailer != nil || AppPreferences.persistedLanguage == .english {
                return localizedTrailer
            }

            let fallbackVideos: MovieVideoResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieVideos(
                    movieID: movieID,
                    languageCode: AppLanguage.english.tmdbLanguageCode
                )
            )
            return selectPreferredTrailer(from: fallbackVideos.results)
        } catch {
            AppLogger.log("Trailer load failed", category: .movie, level: .error)
            return nil
        }
    }

    private func loadStreamingPlatforms(for movie: Movie) async -> [MovieStreamingPlatform] {
        do {
            let response: MovieWatchProvidersResponse = try await networkService.request(
                endpoint: TMDBEndpoint.movieWatchProviders(movieID: movie.id)
            )
            return preferredPlatforms(from: response.results, movieTitle: movie.title)
        } catch {
            AppLogger.log("Watch providers load failed", category: .movie, level: .error)
            return []
        }
    }

    private func loadSimilarMovies(for movie: Movie) async -> [Movie] {
        do {
            let response: MovieResponse = try await networkService.request(
                endpoint: TMDBEndpoint.similarMovies(movieID: movie.id, page: 1)
            )
            return Array(response.results.filter { $0.id != movie.id }.prefix(12))
        } catch {
            AppLogger.log("Similar movies load failed", category: .movie, level: .error)
            return []
        }
    }

    private func selectPreferredTrailer(from videos: [MovieVideo]) -> MovieVideo? {
        let youtubeVideos = videos.filter { $0.watchURL != nil }

        return youtubeVideos.first(where: { $0.type == "Trailer" && $0.official }) ??
            youtubeVideos.first(where: { $0.type == "Trailer" }) ??
            youtubeVideos.first(where: { $0.official }) ??
            youtubeVideos.first
    }

    private func preferredPlatforms(from results: [String: MovieWatchProviderRegion], movieTitle: String) -> [MovieStreamingPlatform] {
        let preferredRegions = [preferredRegionCode, "TR", "US"]
        let region = preferredRegions
            .compactMap { code in results[code] }
            .first ?? results.values.first

        guard let region else { return [] }

        var seen = Set<Int>()
        let providers = (region.flatrate ?? []) + (region.rent ?? []) + (region.buy ?? [])

        return providers.compactMap { provider in
            guard seen.insert(provider.providerID).inserted else { return nil }

            return MovieStreamingPlatform(
                id: provider.providerID,
                name: provider.providerName,
                logoURL: provider.logoURL,
                linkURL: googleSearchURL(movieTitle: movieTitle, platformName: provider.providerName)
            )
        }
    }

    private func googleSearchURL(movieTitle: String, platformName: String) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: "\(movieTitle) \(platformName)")
        ]
        return components?.url
    }

    private var preferredRegionCode: String {
        switch AppPreferences.persistedLanguage {
        case .turkish:
            return "TR"
        case .arabic:
            return "AE"
        case .english:
            return "US"
        }
    }
}
