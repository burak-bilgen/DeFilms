import XCTest
@testable import DeFilms

@MainActor
final class DeFilmsTests: XCTestCase {
    func testAuthSessionManagerSignsUpSignsOutAndRestoresSession() throws {
        let keychain = InMemoryKeychainService()
        let sessionManager = AuthSessionManager(keychainService: keychain)

        try sessionManager.signUp(email: "user@example.com", password: "secret1", confirmPassword: "secret1")

        XCTAssertTrue(sessionManager.isSignedIn)
        XCTAssertEqual(sessionManager.session?.email, "user@example.com")

        let restoredSessionManager = AuthSessionManager(keychainService: keychain)
        XCTAssertEqual(restoredSessionManager.session?.email, "user@example.com")

        restoredSessionManager.signOut()
        XCTAssertFalse(restoredSessionManager.isSignedIn)
    }

    func testSettingsViewModelSignsOutThroughBoundSession() {
        let sessionManager = MockBoundAuthSessionManager()
        let viewModel = SettingsViewModel()

        viewModel.bind(sessionManager: sessionManager)
        viewModel.signOut()

        XCTAssertTrue(sessionManager.didSignOut)
    }
}

private final class InMemoryKeychainService: KeychainServicing {
    private var storage: [String: Data] = [:]

    func data(for account: String) throws -> Data? {
        storage[account]
    }

    func save(_ data: Data, for account: String) throws {
        storage[account] = data
    }

    func delete(account: String) throws {
        storage.removeValue(forKey: account)
    }
}

private final class MockBoundAuthSessionManager: AuthSessionManaging {
    var session: AuthSession? = AuthSession(email: "bound@example.com", token: "token")
    var isSignedIn: Bool { session != nil }
    var currentUserIdentifier: String { session?.email ?? "guest" }
    private(set) var didSignOut = false

    func signUp(email: String, password: String, confirmPassword: String) throws {}
    func signIn(email: String, password: String) throws {}
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws {}

    func signOut() {
        didSignOut = true
        session = nil
    }
}
