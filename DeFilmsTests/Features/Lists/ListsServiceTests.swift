import XCTest
@testable import DeFilms

@MainActor
final class ListsServiceTests: XCTestCase {
    func testCreateListRejectsDuplicateNamesCaseInsensitively() async throws {
        let service = ListsService(
            repository: ServiceTestListsRepository(),
            sessionManager: ServiceTestAuthSessionManager()
        )
        let existing = [MovieList(id: UUID(), name: "Weekend", movies: [])]

        do {
            _ = try await service.createList(named: " weekend ", lists: existing)
            XCTFail("Expected duplicate list name error")
        } catch {
            XCTAssertEqual(error as? ListsServiceError, .duplicateListName)
        }
    }

    func testCreateListRejectsDuplicateNamesDiacriticInsensitively() async throws {
        let service = ListsService(
            repository: ServiceTestListsRepository(),
            sessionManager: ServiceTestAuthSessionManager()
        )
        let existing = [MovieList(id: UUID(), name: "Café", movies: [])]

        do {
            _ = try await service.createList(named: " cafe ", lists: existing)
            XCTFail("Expected duplicate list name error")
        } catch {
            XCTAssertEqual(error as? ListsServiceError, .duplicateListName)
        }
    }

    func testLoadListsFetchesCurrentUserLists() async throws {
        let repository = ServiceTestListsRepository()
        repository.lists = [MovieList(id: UUID(), name: "Sci-Fi", movies: [])]
        let sessionManager = ServiceTestAuthSessionManager(
            session: AuthSession(email: "user@example.com", token: "token", userIdentifier: "user-id")
        )
        let service = ListsService(repository: repository, sessionManager: sessionManager)

        let lists = try await service.loadLists()

        XCTAssertEqual(lists.count, 1)
    }
}
