import XCTest
@testable import DeFilms

@MainActor
final class FavoritesServiceTests: XCTestCase {
    func testCreateListRejectsDuplicateNamesCaseInsensitively() async throws {
        let service = FavoritesService(
            repository: ServiceTestFavoritesRepository(),
            sessionManager: ServiceTestAuthSessionManager()
        )
        let existing = [FavoriteList(id: UUID(), name: "Weekend", movies: [])]

        do {
            _ = try await service.createList(named: " weekend ", lists: existing)
            XCTFail("Expected duplicate list name error")
        } catch {
            XCTAssertEqual(error as? FavoritesServiceError, .duplicateListName)
        }
    }

    func testCreateListRejectsDuplicateNamesDiacriticInsensitively() async throws {
        let service = FavoritesService(
            repository: ServiceTestFavoritesRepository(),
            sessionManager: ServiceTestAuthSessionManager()
        )
        let existing = [FavoriteList(id: UUID(), name: "Café", movies: [])]

        do {
            _ = try await service.createList(named: " cafe ", lists: existing)
            XCTFail("Expected duplicate list name error")
        } catch {
            XCTAssertEqual(error as? FavoritesServiceError, .duplicateListName)
        }
    }

    func testLoadListsAdoptsLegacyIdentifiersBeforeFetching() async throws {
        let repository = ServiceTestFavoritesRepository()
        repository.lists = [FavoriteList(id: UUID(), name: "Sci-Fi", movies: [])]
        let sessionManager = ServiceTestAuthSessionManager(
            session: AuthSession(email: "user@example.com", token: "token", userIdentifier: "user-id")
        )
        let service = FavoritesService(repository: repository, sessionManager: sessionManager)

        let lists = try await service.loadLists()

        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(repository.lastAdoptedUserIdentifier, "user-id")
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("guest"))
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("guest-device-id"))
        XCTAssertTrue(repository.lastLegacyUserIdentifiers.contains("user@example.com"))
    }
}
