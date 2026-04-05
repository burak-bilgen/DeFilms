//
//  SettingsFactory.swift
//  DeFilms
//

import Foundation

final class SettingsFactory {
    private let sessionManager: AuthSessionManager
    private let authFormService: AuthFormServicing

    init(sessionManager: AuthSessionManager) {
        self.sessionManager = sessionManager
        self.authFormService = AuthFormService(sessionManager: sessionManager)
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            bundle: .main,
            sessionManager: sessionManager
        )
    }

    func makeSignInViewModel() -> SignInViewModel {
        SignInViewModel(authFormService: authFormService)
    }

    func makeSignUpViewModel() -> SignUpViewModel {
        SignUpViewModel(authFormService: authFormService)
    }

    func makeChangePasswordViewModel() -> ChangePasswordViewModel {
        ChangePasswordViewModel(authFormService: authFormService)
    }
}
