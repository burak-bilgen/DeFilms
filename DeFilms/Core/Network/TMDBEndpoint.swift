
import Foundation

enum TMDBEndpoint: Endpoint {
    enum TrendingWindow: String {
        case day
        case week
    }

    enum MovieDiscoverCategory {
        case criticallyAcclaimed
        case hiddenGems
        case actionAdventure
        case familyNight
    }

    enum KeywordMatchMode {
        case any
        case all

        var separator: String {
            switch self {
            case .any:
                return "|"
            case .all:
                return ","
            }
        }
    }

    case searchMovie(query: String, page: Int)
    case searchKeyword(query: String, page: Int)
    case popularMovies(page: Int)
    case upcomingMovies(page: Int)
    case nowPlayingMovies(page: Int)
    case topRatedMovies(page: Int)
    case trendingMovies(window: TrendingWindow, page: Int)
    case discoverMovies(category: MovieDiscoverCategory, page: Int)
    case discoverMoviesByKeywords(keywordIDs: [Int], matchMode: KeywordMatchMode, page: Int)
    case movieDetails(movieID: Int)
    case movieVideos(movieID: Int, languageCode: String?)
    case movieImages(movieID: Int)
    case movieCredits(movieID: Int)
    case movieWatchProviders(movieID: Int)
    case similarMovies(movieID: Int, page: Int)
    case genreList

    var path: String {
        switch self {
        case .searchMovie:
            return "/search/movie"
        case .searchKeyword:
            return "/search/keyword"
        case .popularMovies:
            return "/movie/popular"
        case .upcomingMovies:
            return "/movie/upcoming"
        case .nowPlayingMovies:
            return "/movie/now_playing"
        case .topRatedMovies:
            return "/movie/top_rated"
        case let .trendingMovies(window, _):
            return "/trending/movie/\(window.rawValue)"
        case .discoverMovies, .discoverMoviesByKeywords:
            return "/discover/movie"
        case let .movieDetails(movieID):
            return "/movie/\(movieID)"
        case let .movieVideos(movieID, _):
            return "/movie/\(movieID)/videos"
        case let .movieImages(movieID):
            return "/movie/\(movieID)/images"
        case let .movieCredits(movieID):
            return "/movie/\(movieID)/credits"
        case let .movieWatchProviders(movieID):
            return "/movie/\(movieID)/watch/providers"
        case let .similarMovies(movieID, _):
            return "/movie/\(movieID)/similar"
        case .genreList:
            return "/genre/movie/list"
        }
    }

    var method: HTTPMethod {
        .get
    }

    var cachePolicy: URLRequest.CachePolicy {
        switch self {
        case .genreList, .movieWatchProviders:
            return .returnCacheDataElseLoad
        default:
            return .reloadRevalidatingCacheData
        }
    }

    var retryPolicy: NetworkRetryPolicy {
        .transient(maxRetryCount: 1)
    }

    func queryItems(for language: AppLanguage) -> [URLQueryItem] {
        switch self {
        case let .searchMovie(query, page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .searchKeyword(query, page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .popularMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .upcomingMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .nowPlayingMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .topRatedMovies(page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .trendingMovies(_, page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case let .discoverMovies(category, page):
            return discoverQueryItems(for: category, page: page)
        case let .discoverMoviesByKeywords(keywordIDs, matchMode, page):
            return discoverQueryItems(forKeywordIDs: keywordIDs, matchMode: matchMode, page: page)
        case .movieDetails:
            return []
        case let .movieVideos(_, languageCode):
            guard let languageCode else { return [] }
            return [
                URLQueryItem(name: "language", value: languageCode)
            ]
        case .movieImages:
            return [
                URLQueryItem(
                    name: "include_image_language",
                    value: "\(language.rawValue),en,null"
                )
            ]
        case .movieCredits:
            return []
        case .movieWatchProviders:
            return []
        case let .similarMovies(_, page):
            return [
                URLQueryItem(name: "page", value: String(page))
            ]
        case .genreList:
            return []
        }
    }

    private func discoverQueryItems(for category: MovieDiscoverCategory, page: Int) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "false")
        ]

        switch category {
        case .criticallyAcclaimed:
            items.append(URLQueryItem(name: "sort_by", value: "vote_average.desc"))
            items.append(URLQueryItem(name: "vote_count.gte", value: "1200"))
        case .hiddenGems:
            items.append(URLQueryItem(name: "sort_by", value: "vote_average.desc"))
            items.append(URLQueryItem(name: "vote_count.gte", value: "250"))
            items.append(URLQueryItem(name: "vote_count.lte", value: "2500"))
        case .actionAdventure:
            items.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            items.append(URLQueryItem(name: "with_genres", value: "28|12"))
            items.append(URLQueryItem(name: "vote_count.gte", value: "300"))
        case .familyNight:
            items.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            items.append(URLQueryItem(name: "with_genres", value: "10751|16"))
            items.append(URLQueryItem(name: "vote_count.gte", value: "150"))
        }

        return items
    }

    private func discoverQueryItems(
        forKeywordIDs keywordIDs: [Int],
        matchMode: KeywordMatchMode,
        page: Int
    ) -> [URLQueryItem] {
        [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "false"),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "vote_count.gte", value: "20"),
            URLQueryItem(
                name: "with_keywords",
                value: keywordIDs.map(String.init).joined(separator: matchMode.separator)
            )
        ]
    }
}
