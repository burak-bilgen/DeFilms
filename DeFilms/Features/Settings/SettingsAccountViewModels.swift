//
//  SettingsAccountViewModels.swift
//  DeFilms
//

import Combine
import Foundation

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published private(set) var errorMessage: String?

    func submit(using sessionManager: AuthSessionManaging) -> Bool {
        do {
            try sessionManager.signIn(email: email, password: password)
            errorMessage = nil
            ToastCenter.shared.showSuccess(Localization.string("auth.toast.signedIn"))
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
            errorMessage = message
            ToastCenter.shared.showError(message)
            return false
        }
    }
}

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published private(set) var errorMessage: String?

    func submit(using sessionManager: AuthSessionManaging) -> Bool {
        do {
            try sessionManager.signUp(email: email, password: password, confirmPassword: confirmPassword)
            errorMessage = nil
            ToastCenter.shared.showSuccess(Localization.string("auth.toast.accountCreated"))
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
            errorMessage = message
            ToastCenter.shared.showError(message)
            return false
        }
    }
}

@MainActor
final class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    func submit(using sessionManager: AuthSessionManaging) -> Bool {
        do {
            try sessionManager.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
            let success = Localization.string("auth.changePassword.success")
            successMessage = success
            errorMessage = nil
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            ToastCenter.shared.showSuccess(success)
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
            errorMessage = message
            successMessage = nil
            ToastCenter.shared.showError(message)
            return false
        }
    }
}
