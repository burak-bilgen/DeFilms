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

    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        AuthFormContainer(title: Localization.string("auth.signIn")) {
            Section {
                TextField(Localization.string("auth.email"), text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField(Localization.string("auth.password"), text: $viewModel.password)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button(Localization.string("auth.signIn")) {
                    if viewModel.submit(using: sessionManager) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = SignUpViewModel()

    var body: some View {
        AuthFormContainer(title: Localization.string("auth.signUp")) {
            Section {
                TextField(Localization.string("auth.email"), text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                SecureField(Localization.string("auth.password"), text: $viewModel.password)
                SecureField(Localization.string("auth.confirmPassword"), text: $viewModel.confirmPassword)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button(Localization.string("auth.createAccount")) {
                    if viewModel.submit(using: sessionManager) {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ChangePasswordViewModel()

    var body: some View {
        AuthFormContainer(title: Localization.string("auth.changePassword")) {
            Section {
                SecureField(Localization.string("auth.currentPassword"), text: $viewModel.currentPassword)
                SecureField(Localization.string("auth.newPassword"), text: $viewModel.newPassword)
                SecureField(Localization.string("auth.confirmPassword"), text: $viewModel.confirmPassword)
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if let successMessage = viewModel.successMessage {
                Section {
                    Text(successMessage)
                        .foregroundStyle(.green)
                }
            }

            Section {
                Button(Localization.string("auth.changePassword")) {
                    _ = viewModel.submit(using: sessionManager)
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
