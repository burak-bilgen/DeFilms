//
//  ChangePasswordViewModel.swift
//  DeFilms
//

import Combine
import Foundation

@MainActor
final class ChangePasswordViewModel: ObservableObject {
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published private(set) var toastItem: ToastItem?

    private let authFormService: AuthFormServicing

    init(authFormService: AuthFormServicing) {
        self.authFormService = authFormService
    }

    func submit() -> Bool {
        do {
            let success = try authFormService.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
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
