import Foundation
import Testing
@testable import DeFilms

@MainActor
struct MovieDetailViewModelTests {
    @Test
    func loadPopulatesPayloadAndTrailerAvailability() async {
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
                imdbID: "tt1160419",
                genres: [MovieGenre(id: 878, name: "Science Fiction")]
            ),
            trailer: MovieVideo(key: "abc123", name: "Trailer", site: "YouTube", type: "Trailer", official: true),
            gallery: [MovieImageAsset(filePath: "/gallery.jpg")],
            directors: [MovieCrewMember(id: 1, name: "Denis Villeneuve", job: "Director", profilePath: nil, imdbID: nil)],
            cast: [MovieCastMember(id: 2, name: "Timothee Chalamet", character: "Paul", profilePath: nil, imdbID: nil)],
            streamingPlatforms: [MovieStreamingPlatform(id: 3, name: "Max", logoURL: nil, linkURL: nil)],
            similarMovies: [Movie(id: 99, title: "Arrival", overview: nil, posterPath: nil, backdropPath: nil, releaseDate: "2016-11-11", voteAverage: 8.2, genreIDs: nil)]
        )
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: MockMovieDetailService(payload: payload)
        )

        await viewModel.load()

        #expect(viewModel.detail == payload.detail)
        #expect(viewModel.gallery == payload.gallery)
        #expect(viewModel.directors == payload.directors)
        #expect(viewModel.cast == payload.cast)
        #expect(viewModel.streamingPlatforms == payload.streamingPlatforms)
        #expect(viewModel.similarMovies == payload.similarMovies)
        #expect(viewModel.hasTrailer)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func loadFailurePublishesErrorToast() async {
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

        #expect(viewModel.detail == nil)
        #expect(viewModel.errorMessage == "Detail failed")
        #expect(viewModel.toastItem?.message == "Detail failed")
        #expect(viewModel.isLoading == false)
    }

    @Test
    func presentTrailerWithoutTrailerPublishesMissingTrailerToast() {
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
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: MockMovieDetailService()
        )

        viewModel.presentTrailer()

        #expect(viewModel.isTrailerPresented == false)
        #expect(viewModel.toastItem?.message == Localization.string("movies.detail.trailer.missing"))
    }

    @Test
    func reloadForLanguageChangeRequestsPayloadAgain() async {
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
                imdbID: nil,
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
        let viewModel = MovieDetailViewModel(
            movie: movie,
            detailService: detailService
        )

        await viewModel.loadIfNeeded()
        await viewModel.reloadForLanguageChange()

        #expect(detailService.loadCount == 2)
    }
}
