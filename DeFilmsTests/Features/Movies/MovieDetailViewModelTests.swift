import XCTest
@testable import DeFilms

@MainActor
final class MovieDetailViewModelTests: XCTestCase {
    func test_MovieDetailViewModel_initialDerivedValues_fallBackToBaseMovie() {
        let movie = Movie(
            id: 7,
            title: "Fallback",
            overview: nil,
            posterPath: "/poster.jpg",
            backdropPath: nil,
            releaseDate: "2022-03-04",
            voteAverage: 7.3,
            genreIDs: nil
        )
        let viewModel = MovieDetailViewModel(movie: movie, detailService: MockMovieDetailService())

        XCTAssertEqual(viewModel.title, "Fallback")
        XCTAssertEqual(viewModel.overview, Localization.string("movies.detail.overview.empty"))
        XCTAssertEqual(viewModel.releaseYear, "2022")
        XCTAssertEqual(viewModel.ratingText, "7.3")
        XCTAssertEqual(viewModel.heroFacts, ["2022"])
        XCTAssertEqual(viewModel.galleryURLs, [movie.posterURL].compactMap { $0 })
        XCTAssertFalse(viewModel.hasTrailer)
    }

    func test_MovieDetailViewModel_load_populatesPayloadAndTrailerAvailability() async {
        let movie = Movie(
            id: 42,
            title: "Dune",
            overview: "Sci-fi epic",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "2021-10-22",
            voteAverage: 8.1,
            genreIDs: [878]
        )
        let payload = MovieDetailPayload(
            detail: MovieDetail(
                id: 42,
                title: "Dune",
                overview: "Sci-fi epic",
                posterPath: "/poster.jpg",
                backdropPath: "/backdrop.jpg",
                releaseDate: "2021-10-22",
                voteAverage: 8.1,
                runtime: 155,
                genres: [MovieGenre(id: 878, name: "Science Fiction")]
            ),
            trailer: MovieVideo(key: "abc123", name: "Trailer", site: "YouTube", type: "Trailer", official: true),
            gallery: [MovieImageAsset(filePath: "/gallery.jpg")],
            directors: [MovieCrewMember(id: 1, name: "Denis Villeneuve", job: "Director", profilePath: nil)],
            cast: [MovieCastMember(id: 2, name: "Timothee Chalamet", character: "Paul", profilePath: nil)],
            streamingPlatforms: [MovieStreamingPlatform(id: 3, name: "Max", logoURL: nil, linkURL: nil)],
            similarMovies: [Movie(id: 99, title: "Arrival", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2016-11-11", voteAverage: 8.2, genreIDs: nil)]
        )
        let viewModel = MovieDetailViewModel(movie: movie, detailService: MockMovieDetailService(payload: payload))

        await viewModel.load()

        XCTAssertEqual(viewModel.detail, payload.detail)
        XCTAssertEqual(viewModel.gallery, payload.gallery)
        XCTAssertEqual(viewModel.directors, payload.directors)
        XCTAssertEqual(viewModel.cast, payload.cast)
        XCTAssertEqual(viewModel.streamingPlatforms, payload.streamingPlatforms)
        XCTAssertEqual(viewModel.similarMovies, payload.similarMovies)
        XCTAssertTrue(viewModel.hasTrailer)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_MovieDetailViewModel_loadFailure_publishesErrorToastAndClearsCollections() async {
        let movie = Movie(
            id: 17,
            title: "Blade Runner 2049",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2017-10-06",
            voteAverage: 8.0,
            genreIDs: nil
        )
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: MockMovieDetailService(error: TestLocalizedError(message: "Detail failed"))
        )

        await viewModel.load()

        XCTAssertNil(viewModel.detail)
        XCTAssertEqual(viewModel.errorMessage, "Detail failed")
        XCTAssertEqual(viewModel.toastItem?.message, "Detail failed")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.gallery.isEmpty)
        XCTAssertTrue(viewModel.cast.isEmpty)
    }

    func test_MovieDetailViewModel_presentTrailerWithoutTrailer_publishesMissingTrailerToast() {
        let movie = Movie(
            id: 5,
            title: "No Trailer",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: nil,
            genreIDs: nil
        )
        let viewModel = MovieDetailViewModel(movie: movie, detailService: MockMovieDetailService())

        viewModel.presentTrailer()

        XCTAssertFalse(viewModel.isTrailerPresented)
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("movies.detail.trailer.missing"))
    }

    func test_MovieDetailViewModel_presentTrailerWithTrailer_setsPresentedState() async {
        let movie = Movie(
            id: 42,
            title: "Dune",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2021-10-22",
            voteAverage: 8.0,
            genreIDs: nil
        )
        let payload = MovieDetailPayload(
            detail: MovieDetail(
                id: 42,
                title: "Dune",
                overview: nil,
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2021-10-22",
                voteAverage: 8.0,
                runtime: 155,
                genres: []
            ),
            trailer: MovieVideo(key: "abc123", name: "Trailer", site: "YouTube", type: "Trailer", official: true),
            gallery: [],
            directors: [],
            cast: [],
            streamingPlatforms: [],
            similarMovies: []
        )
        let viewModel = MovieDetailViewModel(movie: movie, detailService: MockMovieDetailService(payload: payload))

        await viewModel.load()
        viewModel.presentTrailer()

        XCTAssertTrue(viewModel.isTrailerPresented)
    }

    func test_MovieDetailViewModel_loadIfNeeded_onlyLoadsOnce() async {
        let movie = Movie(
            id: 12,
            title: "Only Once",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 7.0,
            genreIDs: nil
        )
        let payload = MovieDetailPayload(
            detail: MovieDetail(
                id: 12,
                title: "Only Once",
                overview: nil,
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2024-01-01",
                voteAverage: 7.0,
                runtime: nil,
                genres: []
            ),
            trailer: nil,
            gallery: [],
            directors: [],
            cast: [],
            streamingPlatforms: [],
            similarMovies: []
        )
        let detailService = MockMovieDetailService(payload: payload)
        let viewModel = MovieDetailViewModel(movie: movie, detailService: detailService)

        await viewModel.loadIfNeeded()
        await viewModel.loadIfNeeded()

        XCTAssertEqual(detailService.loadCount, 1)
    }

    func test_MovieDetailViewModel_reloadForLanguageChange_requestsPayloadAgain() async {
        let movie = Movie(
            id: 33,
            title: "Reload Test",
            overview: nil,
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 7.4,
            genreIDs: nil
        )
        let payload = MovieDetailPayload(
            detail: MovieDetail(
                id: 33,
                title: "Reload Test",
                overview: nil,
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2024-01-01",
                voteAverage: 7.4,
                runtime: 120,
                genres: []
            ),
            trailer: nil,
            gallery: [],
            directors: [],
            cast: [],
            streamingPlatforms: [],
            similarMovies: []
        )
        let detailService = MockMovieDetailService(payload: payload)
        let viewModel = MovieDetailViewModel(movie: movie, detailService: detailService)

        await viewModel.loadIfNeeded()
        await viewModel.reloadForLanguageChange()

        XCTAssertEqual(detailService.loadCount, 2)
    }

    func test_MovieDetailViewModel_galleryURLs_deduplicatesFallbackAssets() {
        let sharedURLPath = "/shared.jpg"
        let movie = Movie(
            id: 51,
            title: "Gallery",
            overview: nil,
            posterPath: sharedURLPath,
            backdropPath: sharedURLPath,
            releaseDate: "2024-01-01",
            voteAverage: nil,
            genreIDs: nil
        )
        let viewModel = MovieDetailViewModel(movie: movie, detailService: MockMovieDetailService())

        XCTAssertEqual(viewModel.galleryURLs.count, 1)
    }
}
