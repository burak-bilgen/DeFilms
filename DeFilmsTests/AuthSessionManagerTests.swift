import XCTest
@testable import DeFilms

@MainActor
final class AuthSessionManagerTests: XCTestCase {
    func testSignsUpSignsOutAndRestoresSession() throws {
        let keychain = InMemoryKeychainService()
        let sessionManager = AuthSessionManager(keychainService: keychain)

        try sessionManager.signUp(email: "user@example.com", password: "secret1", confirmPassword: "secret1")

        XCTAssertTrue(sessionManager.isSignedIn)
        XCTAssertEqual(sessionManager.session?.email, "user@example.com")
        XCTAssertNotEqual(sessionManager.currentUserIdentifier, "user@example.com")

        let restoredSessionManager = AuthSessionManager(keychainService: keychain)
        XCTAssertEqual(restoredSessionManager.session?.email, "user@example.com")
        XCTAssertEqual(restoredSessionManager.currentUserIdentifier, sessionManager.currentUserIdentifier)

        restoredSessionManager.signOut()
        XCTAssertFalse(restoredSessionManager.isSignedIn)
    }

    func testChangePasswordRejectsIncorrectCurrentPasswordBeforeOtherValidation() throws {
        let keychain = InMemoryKeychainService()
        let sessionManager = AuthSessionManager(keychainService: keychain)
        try sessionManager.signUp(email: "user@example.com", password: "secret1", confirmPassword: "secret1")

        XCTAssertThrowsError(
            try sessionManager.changePassword(
                currentPassword: "wrongpass",
                newPassword: "short",
                confirmPassword: "mismatch"
            )
        ) { error in
            XCTAssertEqual(error as? AuthError, .currentPasswordIncorrect)
        }
    }

    func testChangePasswordRejectsReusingCurrentPassword() throws {
        let keychain = InMemoryKeychainService()
        let sessionManager = AuthSessionManager(keychainService: keychain)
        try sessionManager.signUp(email: "user@example.com", password: "secret1", confirmPassword: "secret1")

        XCTAssertThrowsError(
            try sessionManager.changePassword(
                currentPassword: "secret1",
                newPassword: "secret1",
                confirmPassword: "secret1"
            )
        ) { error in
            XCTAssertEqual(error as? AuthError, .newPasswordMustDiffer)
        }
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
