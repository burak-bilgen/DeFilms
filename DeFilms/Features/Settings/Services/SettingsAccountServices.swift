//
//  SettingsAccountServices.swift
//  DeFilms
//

import Foundation

protocol AuthFormServicing {
    func signIn(email: String, password: String) throws -> String
    func signUp(email: String, password: String, confirmPassword: String) throws -> String
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws -> String
}

final class AuthFormService: AuthFormServicing {
    private let sessionManager: AuthSessionManaging

    init(sessionManager: AuthSessionManaging) {
        self.sessionManager = sessionManager
    }

    func signIn(email: String, password: String) throws -> String {
        try sessionManager.signIn(email: email, password: password)
        return Localization.string("auth.toast.signedIn")
    }

    func signUp(email: String, password: String, confirmPassword: String) throws -> String {
        try sessionManager.signUp(email: email, password: password, confirmPassword: confirmPassword)
        return Localization.string("auth.toast.accountCreated")
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws -> String {
        try sessionManager.changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            confirmPassword: confirmPassword
        )
        return Localization.string("auth.changePassword.success")
    }
}
