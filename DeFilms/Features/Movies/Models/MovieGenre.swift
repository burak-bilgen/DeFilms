
import Foundation

struct MovieGenreResponse: Codable {
    let genres: [MovieGenre]
}

struct MovieGenre: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
}
