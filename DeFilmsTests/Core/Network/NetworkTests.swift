import XCTest
@testable import DeFilms

@MainActor
final class NetworkRequestBuilderTests: XCTestCase {
    func testRequestBuilderAppendsApiKeyAndLanguage() throws {
        let builder = NetworkRequestBuilder(
            apiKeyProvider: { "test-key" },
            languageProvider: { .turkish },
            timeoutInterval: 12
        )

        let request = try builder.makeRequest(endpoint: TMDBEndpoint.popularMovies(page: 3))

        XCTAssertEqual(request.httpMethod, HTTPMethod.get.rawValue)
        XCTAssertEqual(request.timeoutInterval, 12)

        let queryItems = try queryItems(from: request)

        XCTAssertEqual(queryItems["page"], "3")
        XCTAssertEqual(queryItems["api_key"], "test-key")
        XCTAssertEqual(queryItems["language"], AppLanguage.turkish.tmdbLanguageCode)
    }

    func testRequestBuilderUsesEndpointCachePolicy() throws {
        let builder = NetworkRequestBuilder(
            apiKeyProvider: { "test-key" },
            languageProvider: { .english }
        )

        let request = try builder.makeRequest(endpoint: TMDBEndpoint.genreList)

        XCTAssertEqual(request.cachePolicy, .returnCacheDataElseLoad)
    }

    func testRequestBuilderUsesEndpointProvidedLanguageWhenPresent() throws {
        let builder = NetworkRequestBuilder(
            apiKeyProvider: { "test-key" },
            languageProvider: { .turkish }
        )

        let request = try builder.makeRequest(
            endpoint: TMDBEndpoint.movieVideos(movieID: 10, languageCode: AppLanguage.english.tmdbLanguageCode)
        )

        let queryItems = try queryItems(from: request)

        XCTAssertEqual(queryItems["language"], AppLanguage.english.tmdbLanguageCode)
    }

    func testRequestBuilderThrowsForMissingAPIKey() {
        let builder = NetworkRequestBuilder(
            apiKeyProvider: { nil },
            languageProvider: { .english }
        )

        XCTAssertThrowsError(try builder.makeRequest(endpoint: TMDBEndpoint.genreList)) { error in
            XCTAssertEqual(error as? NetworkError, .missingAPIKey)
        }
    }

    private func queryItems(from request: URLRequest) throws -> [String: String] {
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") }
        )
    }
}

@MainActor
final class NetworkManagerTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    override class func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        super.tearDown()
    }

    func testRequestDecodesSuccessfulResponse() async throws {
        let session = makeSession()
        let manager = NetworkManager(
            session: session,
            requestBuilder: NetworkRequestBuilder(
                apiKeyProvider: { "test-key" },
                languageProvider: { .english }
            )
        )

        MockURLProtocol.handler = { request in
            let data = #"{"page":1,"results":[],"total_pages":1}"#.data(using: .utf8) ?? Data()
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, data)
        }

        let response: MovieResponse = try await manager.request(endpoint: TMDBEndpoint.popularMovies(page: 1))

        XCTAssertEqual(response.page, 1)
        XCTAssertEqual(response.results.count, 0)
        XCTAssertEqual(response.totalPages, 1)
    }

    func testRequestMapsTimedOutURLError() async {
        let session = makeSession()
        let manager = NetworkManager(
            session: session,
            requestBuilder: NetworkRequestBuilder(
                apiKeyProvider: { "test-key" },
                languageProvider: { .english }
            )
        )

        MockURLProtocol.handler = { _ in
            throw URLError(.timedOut)
        }

        do {
            let _: MovieResponse = try await manager.request(endpoint: TMDBEndpoint.popularMovies(page: 1))
            XCTFail("Expected timed out error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .requestTimedOut)
        }
    }

    func testRequestMapsDecodingFailure() async {
        let session = makeSession()
        let manager = NetworkManager(
            session: session,
            requestBuilder: NetworkRequestBuilder(
                apiKeyProvider: { "test-key" },
                languageProvider: { .english }
            )
        )

        MockURLProtocol.handler = { request in
            let data = #"{"invalid":true}"#.data(using: .utf8) ?? Data()
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, data)
        }

        do {
            let _: MovieResponse = try await manager.request(endpoint: TMDBEndpoint.popularMovies(page: 1))
            XCTFail("Expected decoding error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .decodingError)
        }
    }

    func testRequestMapsServerMessageFromPayload() async {
        let session = makeSession()
        let manager = NetworkManager(
            session: session,
            requestBuilder: NetworkRequestBuilder(
                apiKeyProvider: { "test-key" },
                languageProvider: { .english }
            )
        )

        MockURLProtocol.handler = { request in
            let data = #"{"status_message":"The resource you requested could not be found."}"#.data(using: .utf8) ?? Data()
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 404, httpVersion: nil, headerFields: nil)
            )
            return (response, data)
        }

        do {
            let _: MovieResponse = try await manager.request(endpoint: TMDBEndpoint.popularMovies(page: 1))
            XCTFail("Expected server error")
        } catch {
            XCTAssertEqual(
                error as? NetworkError,
                .serverError(statusCode: 404, message: "The resource you requested could not be found.")
            )
        }
    }

    func testRequestMapsRateLimitWithRetryAfterHeader() async {
        let session = makeSession()
        let manager = NetworkManager(
            session: session,
            requestBuilder: NetworkRequestBuilder(
                apiKeyProvider: { "test-key" },
                languageProvider: { .english }
            )
        )

        MockURLProtocol.handler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 429,
                    httpVersion: nil,
                    headerFields: ["Retry-After": "12"]
                )
            )
            return (response, Data())
        }

        do {
            let _: MovieResponse = try await manager.request(endpoint: TMDBEndpoint.popularMovies(page: 1))
            XCTFail("Expected rate-limit error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .rateLimited(retryAfter: 12))
        }
    }

    func testRequestRetriesTransientTransportFailureOnce() async throws {
        let session = makeSession()
        let manager = NetworkManager(
            session: session,
            requestBuilder: NetworkRequestBuilder(
                apiKeyProvider: { "test-key" },
                languageProvider: { .english }
            )
        )
        var attempts = 0

        MockURLProtocol.handler = { request in
            attempts += 1
            if attempts == 1 {
                throw URLError(.timedOut)
            }
            let data = #"{"page":1,"results":[],"total_pages":1}"#.data(using: .utf8) ?? Data()
            let response = try XCTUnwrap(
                HTTPURLResponse(url: try XCTUnwrap(request.url), statusCode: 200, httpVersion: nil, headerFields: nil)
            )
            return (response, data)
        }

        let response: MovieResponse = try await manager.request(endpoint: TMDBEndpoint.popularMovies(page: 1))

        XCTAssertEqual(attempts, 2)
        XCTAssertEqual(response.page, 1)
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
