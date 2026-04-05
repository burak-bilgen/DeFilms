import XCTest
@testable import DeFilms

@MainActor
final class MovieDetailServiceTests: XCTestCase {
    func testLoadPayloadCombinesPrimaryDetailSections() async throws {
        let movie = Movie(
            id: 42,
            title: "Arrival",
            overview: "Test",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2016-11-11",
            voteAverage: 8.2,
            genreIDs: [18]
        )
        let network = MockMovieDetailNetworkService()
        network.detail = MovieDetail(
            id: 42,
            title: "Arrival",
            overview: "Expanded",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2016-11-11",
            voteAverage: 8.4,
            runtime: 116,
            genres: [MovieGenre(id: 18, name: "Drama")]
        )
        network.images = MovieImageResponse(
            backdrops: [MovieImageAsset(filePath: "/gallery.jpg")],
            posters: []
        )
        network.credits = MovieCreditsResponse(
            cast: [
                MovieCastMember(id: 1, name: "Amy Adams", character: "Louise", profilePath: nil),
                MovieCastMember(id: 2, name: "Jeremy Renner", character: "Ian", profilePath: nil)
            ],
            crew: [
                MovieCrewMember(id: 3, name: "Denis Villeneuve", job: "Director", profilePath: nil)
            ]
        )
        network.videos = MovieVideoResponse(
            results: [MovieVideo(key: "abc", name: "Trailer", site: "YouTube", type: "Trailer", official: true)]
        )
        network.watchProviders = MovieWatchProvidersResponse(
            id: 42,
            results: [
                "US": MovieWatchProviderRegion(
                    link: URL(string: "https://example.com"),
                    flatrate: [MovieWatchProvider(providerID: 10, providerName: "Netflix", logoPath: "/logo.png")],
                    rent: nil,
                    buy: nil
                )
            ]
        )
        network.similar = MovieResponse(
            page: 1,
            results: [
                movie,
                Movie(id: 99, title: "Sicario", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2015-01-01", voteAverage: 7.6, genreIDs: nil)
            ],
            totalPages: 1
        )
        let service = TMDBMovieDetailService(
            networkService: network,
            imagePrefetcher: MockMovieImagePrefetcher()
        )

        let payload = try await service.loadPayload(for: movie)

        XCTAssertEqual(payload.detail.title, "Arrival")
        XCTAssertEqual(payload.gallery.count, 1)
        XCTAssertEqual(payload.cast.count, 2)
        XCTAssertEqual(payload.directors.count, 1)
        XCTAssertEqual(payload.trailer?.key, "abc")
        XCTAssertEqual(payload.streamingPlatforms.first?.name, "Netflix")
        XCTAssertEqual(payload.similarMovies.map(\.id), [99])
    }
}
