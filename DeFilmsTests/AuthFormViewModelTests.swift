import Foundation
import Testing
@testable import DeFilms

@MainActor
struct AuthFormViewModelTests {
    @Test
    func signInViewModelPublishesLocalizedErrorOnFailure() {
        let authFormService = MockAuthFormService(signInError: AuthError.invalidCredentials)
        let viewModel = SignInViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.invalidCredentials"))
    }

    @Test
    func signUpViewModelPublishesLocalizedErrorOnFailure() {
        let authFormService = MockAuthFormService(signUpError: AuthError.accountExists)
        let viewModel = SignUpViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "secret1"
        viewModel.confirmPassword = "secret1"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.accountExists"))
    }

    @Test
    func signInViewModelFallsBackToGenericErrorForNonLocalizedFailure() {
        let authFormService = MockAuthFormService(signInError: TestError.unexpectedEndpoint)
        let viewModel = SignInViewModel(authFormService: authFormService)
        viewModel.email = "user@example.com"
        viewModel.password = "wrong"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.generic"))
    }

    @Test
    func changePasswordViewModelClearsFieldsOnSuccess() {
        let viewModel = ChangePasswordViewModel(authFormService: MockAuthFormService())
        viewModel.currentPassword = "oldpass"
        viewModel.newPassword = "newpass"
        viewModel.confirmPassword = "newpass"

        let result = viewModel.submit()

        #expect(result)
        #expect(viewModel.currentPassword.isEmpty)
        #expect(viewModel.newPassword.isEmpty)
        #expect(viewModel.confirmPassword.isEmpty)
    }

    @Test
    func changePasswordViewModelPreservesFieldsOnFailure() {
        let viewModel = ChangePasswordViewModel(
            authFormService: MockAuthFormService(changePasswordError: AuthError.currentPasswordIncorrect)
        )
        viewModel.currentPassword = "oldpass"
        viewModel.newPassword = "newpass"
        viewModel.confirmPassword = "newpass"

        let result = viewModel.submit()

        #expect(result == false)
        #expect(viewModel.currentPassword == "oldpass")
        #expect(viewModel.newPassword == "newpass")
        #expect(viewModel.confirmPassword == "newpass")
        #expect(viewModel.toastItem?.message == Localization.string("auth.error.currentPasswordIncorrect"))
    }
}
