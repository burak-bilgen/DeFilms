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
    @Published private(set) var toastItem: ToastItem?

    func submit(using sessionManager: AuthSessionManaging) -> Bool {
        do {
            try sessionManager.signIn(email: email, password: password)
            toastItem = .success(Localization.string("auth.toast.signedIn"))
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
            toastItem = .error(message)
            return false
        }
    }

    func clearToast() {
        toastItem = nil
    }
}

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published private(set) var toastItem: ToastItem?

    func submit(using sessionManager: AuthSessionManaging) -> Bool {
        do {
            try sessionManager.signUp(email: email, password: password, confirmPassword: confirmPassword)
            toastItem = .success(Localization.string("auth.toast.accountCreated"))
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
            toastItem = .error(message)
            return false
        }
    }

    func clearToast() {
        toastItem = nil
    }
}

@MainActor
final class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published private(set) var toastItem: ToastItem?

    func submit(using sessionManager: AuthSessionManaging) -> Bool {
        do {
            try sessionManager.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
            let success = Localization.string("auth.changePassword.success")
            currentPassword = ""
            newPassword = ""
            confirmPassword = ""
            toastItem = .success(success)
            return true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
            toastItem = .error(message)
            return false
        }
    }

    func clearToast() {
        toastItem = nil
    }
}
