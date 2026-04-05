import XCTest
@testable import DeFilms

@MainActor
final class AuthFormServiceTests: XCTestCase {
    func testSignInReturnsLocalizedSuccessMessage() throws {
        let sessionManager = ServiceTestAuthSessionManager()
        let service = AuthFormService(sessionManager: sessionManager)

        let message = try service.signIn(email: "user@example.com", password: "password")

        XCTAssertEqual(message, Localization.string("auth.toast.signedIn"))
        XCTAssertEqual(sessionManager.session?.email, "user@example.com")
    }

    func testChangePasswordPropagatesUnderlyingError() {
        let sessionManager = ServiceTestAuthSessionManager(changePasswordError: AuthError.invalidPasswordFormat)
        let service = AuthFormService(sessionManager: sessionManager)

        XCTAssertThrowsError(
            try service.changePassword(
                currentPassword: "old",
                newPassword: "new",
                confirmPassword: "new"
            )
        ) { error in
            XCTAssertEqual(error as? AuthError, .invalidPasswordFormat)
        }
    }
}
