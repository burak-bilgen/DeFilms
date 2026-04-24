import XCTest
@testable import DeFilms

@MainActor
final class AuthFormViewModelTests: XCTestCase {
    func test_SignInViewModel_submitFailure_publishesLocalizedError() {
        let authFormService = MockAuthFormService(signInError: AuthError.invalidCredentials)
        let viewModel = SignInViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"

        let result = viewModel.submit()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("auth.error.invalidCredentials"))
    }

    func test_SignUpViewModel_submitFailure_publishesLocalizedError() {
        let authFormService = MockAuthFormService(signUpError: AuthError.accountExists)
        let viewModel = SignUpViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "Secret123"
        viewModel.confirmPassword = "Secret123"

        let result = viewModel.submit()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("auth.error.accountExists"))
    }

    func test_SignInViewModel_nonLocalizedFailure_fallsBackToGenericError() {
        let authFormService = MockAuthFormService(signInError: TestError.unexpectedEndpoint)
        let viewModel = SignInViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"

        let result = viewModel.submit()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("auth.error.generic"))
    }

    func test_SignInViewModel_submitSuccess_publishesSuccessToast() {
        let viewModel = SignInViewModel(authFormService: MockAuthFormService())
        viewModel.email = "user@example.com"
        viewModel.password = "Secret123"

        let result = viewModel.submit()

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.toastItem?.style, .success)
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("auth.toast.signedIn"))
    }

    func test_SignUpViewModel_submitSuccess_publishesSuccessToast() {
        let viewModel = SignUpViewModel(authFormService: MockAuthFormService())
        viewModel.email = "user@example.com"
        viewModel.password = "Secret123"
        viewModel.confirmPassword = "Secret123"

        let result = viewModel.submit()

        XCTAssertTrue(result)
        XCTAssertEqual(viewModel.toastItem?.style, .success)
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("auth.toast.accountCreated"))
    }

    func test_ChangePasswordViewModel_submitSuccess_clearsFieldsOnSuccess() {
        let viewModel = ChangePasswordViewModel(authFormService: MockAuthFormService())
        viewModel.currentPassword = "oldpass"
        viewModel.newPassword = "newpass"
        viewModel.confirmPassword = "newpass"

        let result = viewModel.submit()

        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.currentPassword.isEmpty)
        XCTAssertTrue(viewModel.newPassword.isEmpty)
        XCTAssertTrue(viewModel.confirmPassword.isEmpty)
    }

    func test_ChangePasswordViewModel_submitFailure_preservesFieldsAndPublishesError() {
        let viewModel = ChangePasswordViewModel(
            authFormService: MockAuthFormService(changePasswordError: AuthError.currentPasswordIncorrect)
        )
        viewModel.currentPassword = "oldpass"
        viewModel.newPassword = "newpass"
        viewModel.confirmPassword = "newpass"

        let result = viewModel.submit()

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.currentPassword, "oldpass")
        XCTAssertEqual(viewModel.newPassword, "newpass")
        XCTAssertEqual(viewModel.confirmPassword, "newpass")
        XCTAssertEqual(viewModel.toastItem?.message, Localization.string("auth.error.currentPasswordIncorrect"))
    }

    func test_AuthFormViewModels_clearToast_removesToastItem() {
        let signInViewModel = SignInViewModel(authFormService: MockAuthFormService())
        signInViewModel.email = "user@example.com"
        signInViewModel.password = "Secret123"
        _ = signInViewModel.submit()
        signInViewModel.clearToast()

        let signUpViewModel = SignUpViewModel(authFormService: MockAuthFormService())
        signUpViewModel.email = "user@example.com"
        signUpViewModel.password = "Secret123"
        signUpViewModel.confirmPassword = "Secret123"
        _ = signUpViewModel.submit()
        signUpViewModel.clearToast()

        let changePasswordViewModel = ChangePasswordViewModel(authFormService: MockAuthFormService())
        changePasswordViewModel.currentPassword = "OldSecret1"
        changePasswordViewModel.newPassword = "NewSecret1"
        changePasswordViewModel.confirmPassword = "NewSecret1"
        _ = changePasswordViewModel.submit()
        changePasswordViewModel.clearToast()

        XCTAssertNil(signInViewModel.toastItem)
        XCTAssertNil(signUpViewModel.toastItem)
        XCTAssertNil(changePasswordViewModel.toastItem)
    }
}
