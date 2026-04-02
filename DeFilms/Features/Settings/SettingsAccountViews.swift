//
//  SettingsAccountViews.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

private enum AuthFlowMode {
    case signIn
    case signUp
    case changePassword
}

struct SignInView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        AuthFormContainer(title: Localization.string("auth.signIn")) {
            Section {
                TextField(Localization.string("auth.email"), text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField(Localization.string("auth.password"), text: $password)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button(Localization.string("auth.signIn")) {
                    do {
                        try sessionManager.signIn(email: email, password: password)
                        ToastCenter.shared.showSuccess(Localization.string("auth.toast.signedIn"))
                        dismiss()
                    } catch {
                        let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
                        errorMessage = message
                        ToastCenter.shared.showError(message)
                    }
                }
            }
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        AuthFormContainer(title: Localization.string("auth.signUp")) {
            Section {
                TextField(Localization.string("auth.email"), text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField(Localization.string("auth.password"), text: $password)
                SecureField(Localization.string("auth.confirmPassword"), text: $confirmPassword)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button(Localization.string("auth.createAccount")) {
                    do {
                        try sessionManager.signUp(email: email, password: password, confirmPassword: confirmPassword)
                        ToastCenter.shared.showSuccess(Localization.string("auth.toast.accountCreated"))
                        dismiss()
                    } catch {
                        let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
                        errorMessage = message
                        ToastCenter.shared.showError(message)
                    }
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        AuthFormContainer(title: Localization.string("auth.changePassword")) {
            Section {
                SecureField(Localization.string("auth.currentPassword"), text: $currentPassword)
                SecureField(Localization.string("auth.newPassword"), text: $newPassword)
                SecureField(Localization.string("auth.confirmPassword"), text: $confirmPassword)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if let successMessage {
                Section {
                    Text(successMessage)
                        .foregroundStyle(.green)
                }
            }

            Section {
                Button(Localization.string("auth.changePassword")) {
                    do {
                        try sessionManager.changePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword,
                            confirmPassword: confirmPassword
                        )
                        let success = Localization.string("auth.changePassword.success")
                        successMessage = success
                        ToastCenter.shared.showSuccess(success)
                        errorMessage = nil
                        currentPassword = ""
                        newPassword = ""
                        confirmPassword = ""
                    } catch {
                        let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("auth.error.generic")
                        errorMessage = message
                        ToastCenter.shared.showError(message)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Localization.string("common.done")) {
                    dismiss()
                }
            }
        }
    }
}

private struct AuthFormContainer<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            content
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
