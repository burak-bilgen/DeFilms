import Combine
import Foundation

struct UserMovieStatus: Codable, Equatable, Identifiable {
    let id: Int
    var movie: Movie
    var isWatchlisted: Bool
    var isWatched: Bool
    var rating: Int?
    var watchedAt: Date?
    var updatedAt: Date

    init(movie: Movie) {
        self.id = movie.id
        self.movie = movie
        self.isWatchlisted = false
        self.isWatched = false
        self.rating = nil
        self.watchedAt = nil
        self.updatedAt = Date()
    }
}

struct UserMovieStats: Equatable {
    let watchedCount: Int
    let watchlistCount: Int
    let ratedCount: Int
    let averageRating: Double?
}

@MainActor
final class UserMovieStatusStore: ObservableObject {
    @Published private(set) var statuses: [Int: UserMovieStatus] = [:]

    private let defaults: UserDefaults
    private let storageKey = "movies.userStatus.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        statuses = Self.loadStatuses(from: defaults, key: storageKey)
    }

    func status(for movie: Movie) -> UserMovieStatus {
        statuses[movie.id] ?? UserMovieStatus(movie: movie)
    }

    func isWatchlisted(_ movie: Movie) -> Bool {
        status(for: movie).isWatchlisted
    }

    func isWatched(_ movie: Movie) -> Bool {
        status(for: movie).isWatched
    }

    func toggleWatchlist(for movie: Movie) {
        var status = status(for: movie)
        status.movie = mergedMovie(existing: status.movie, incoming: movie)
        status.isWatchlisted.toggle()
        status.updatedAt = Date()
        save(status)
    }

    func toggleWatched(for movie: Movie) {
        var status = status(for: movie)
        status.movie = mergedMovie(existing: status.movie, incoming: movie)
        status.isWatched.toggle()
        status.watchedAt = status.isWatched ? Date() : nil
        if status.isWatched {
            status.isWatchlisted = false
        }
        status.updatedAt = Date()
        save(status)
    }

    func setRating(_ rating: Int?, for movie: Movie) {
        var status = status(for: movie)
        status.movie = mergedMovie(existing: status.movie, incoming: movie)
        status.rating = rating
        if rating != nil {
            status.isWatched = true
            status.isWatchlisted = false
            status.watchedAt = status.watchedAt ?? Date()
        }
        status.updatedAt = Date()
        save(status)
    }

    var watchlistMovies: [Movie] {
        statuses.values
            .filter(\.isWatchlisted)
            .sorted { $0.updatedAt > $1.updatedAt }
            .map(\.movie)
    }

    var watchedMovies: [Movie] {
        statuses.values
            .filter(\.isWatched)
            .sorted { ($0.watchedAt ?? $0.updatedAt) > ($1.watchedAt ?? $1.updatedAt) }
            .map(\.movie)
    }

    var stats: UserMovieStats {
        let ratedValues = statuses.values.compactMap(\.rating)
        let averageRating = ratedValues.isEmpty
            ? nil
            : Double(ratedValues.reduce(0, +)) / Double(ratedValues.count)

        return UserMovieStats(
            watchedCount: statuses.values.filter(\.isWatched).count,
            watchlistCount: statuses.values.filter(\.isWatchlisted).count,
            ratedCount: ratedValues.count,
            averageRating: averageRating
        )
    }

    func recommendations(from movies: [Movie], limit: Int = 12) -> [Movie] {
        let uniqueMovies = movies.uniquedByID()
        guard !uniqueMovies.isEmpty else { return [] }

        let likedGenreIDs = Set(
            statuses.values
                .filter { ($0.rating ?? 0) >= 4 || $0.isWatchlisted }
                .flatMap { $0.movie.genreIDs ?? [] }
        )
        let watchedIDs = Set(statuses.values.filter(\.isWatched).map(\.id))

        return uniqueMovies
            .filter { !watchedIDs.contains($0.id) }
            .sorted { lhs, rhs in
                recommendationScore(for: lhs, likedGenreIDs: likedGenreIDs) >
                    recommendationScore(for: rhs, likedGenreIDs: likedGenreIDs)
            }
            .prefix(limit)
            .map { $0 }
    }

    private func recommendationScore(for movie: Movie, likedGenreIDs: Set<Int>) -> Double {
        let ratingScore = movie.voteAverage ?? 0
        let genreScore = Double((movie.genreIDs ?? []).filter { likedGenreIDs.contains($0) }.count) * 2.0
        let watchlistPenalty = statuses[movie.id]?.isWatchlisted == true ? -1.0 : 0
        return ratingScore + genreScore + watchlistPenalty
    }

    private func save(_ status: UserMovieStatus) {
        let shouldKeep = status.isWatchlisted || status.isWatched || status.rating != nil
        if shouldKeep {
            statuses[status.id] = status
        } else {
            statuses[status.id] = nil
        }
        persist()
    }

    private func persist() {
        let values = Array(statuses.values)
        guard let data = try? JSONEncoder().encode(values) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func mergedMovie(existing: Movie, incoming: Movie) -> Movie {
        Movie(
            id: incoming.id,
            title: incoming.title,
            overview: incoming.overview ?? existing.overview,
            posterPath: incoming.posterPath ?? existing.posterPath,
            backdropPath: incoming.backdropPath ?? existing.backdropPath,
            releaseDate: incoming.releaseDate ?? existing.releaseDate,
            voteAverage: incoming.voteAverage ?? existing.voteAverage,
            genreIDs: incoming.genreIDs ?? existing.genreIDs
        )
    }

    private static func loadStatuses(from defaults: UserDefaults, key: String) -> [Int: UserMovieStatus] {
        guard
            let data = defaults.data(forKey: key),
            let values = try? JSONDecoder().decode([UserMovieStatus].self, from: data)
        else {
            return [:]
        }

        return Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
    }
}

extension Array where Element == Movie {
    func uniquedByID() -> [Movie] {
        var seen = Set<Int>()
        return filter { seen.insert($0.id).inserted }
    }
}
