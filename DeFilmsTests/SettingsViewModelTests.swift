import XCTest
@testable import DeFilms

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testSignsOutThroughBoundSession() {
        let sessionManager = MockBoundAuthSessionManager()
        let viewModel = SettingsViewModel(sessionManager: sessionManager)

        viewModel.signOut()

        XCTAssertTrue(sessionManager.didSignOut)
    }
}

private final class MockBoundAuthSessionManager: AuthSessionManaging {
    var session: AuthSession? = AuthSession(email: "bound@example.com", token: "token", userIdentifier: "bound-user-id")
    var isSignedIn: Bool { session != nil }
    var currentUserIdentifier: String { session?.userIdentifier ?? guestUserIdentifier }
    let guestUserIdentifier: String = "guest-device-id"
    var legacyUserIdentifiers: [String] { ["guest", guestUserIdentifier, "bound@example.com"] }
    private(set) var didSignOut = false

    func signUp(email: String, password: String, confirmPassword: String) throws {}
    func signIn(email: String, password: String) throws {}
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws {}

    func signOut() {
        didSignOut = true
        session = nil
    }
}
