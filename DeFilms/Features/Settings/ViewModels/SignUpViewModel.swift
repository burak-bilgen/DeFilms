//
//  SignUpViewModel.swift
//  DeFilms
//

import Combine
import Foundation

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published private(set) var toastItem: ToastItem?

    private let authFormService: AuthFormServicing

    init(authFormService: AuthFormServicing) {
        self.authFormService = authFormService
    }

    func submit() -> Bool {
        do {
            toastItem = .success(
                try authFormService.signUp(
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
            )
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
