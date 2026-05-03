import Foundation

struct MovieKeywordResponse: Codable {
    let page: Int
    let results: [MovieKeyword]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}

struct MovieKeyword: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
}
