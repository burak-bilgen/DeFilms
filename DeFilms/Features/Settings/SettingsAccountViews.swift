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
                AuthInputField(
                    title: Localization.string("auth.email"),
                    text: $viewModel.email,
                    systemImage: "envelope.fill",
                    kind: .email
                )

                AuthInputField(
                    title: Localization.string("auth.password"),
                    text: $viewModel.password,
                    systemImage: "lock.fill",
                    kind: .password
                )
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
                AuthInputField(
                    title: Localization.string("auth.email"),
                    text: $viewModel.email,
                    systemImage: "envelope.fill",
                    kind: .email
                )
                AuthInputField(
                    title: Localization.string("auth.password"),
                    text: $viewModel.password,
                    systemImage: "lock.fill",
                    kind: .password
                )
                AuthInputField(
                    title: Localization.string("auth.confirmPassword"),
                    text: $viewModel.confirmPassword,
                    systemImage: "checkmark.shield.fill",
                    kind: .password
                )
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
                AuthInputField(
                    title: Localization.string("auth.currentPassword"),
                    text: $viewModel.currentPassword,
                    systemImage: "lock.rotation",
                    kind: .password
                )
                AuthInputField(
                    title: Localization.string("auth.newPassword"),
                    text: $viewModel.newPassword,
                    systemImage: "lock.open.fill",
                    kind: .newPassword
                )
                AuthInputField(
                    title: Localization.string("auth.confirmPassword"),
                    text: $viewModel.confirmPassword,
                    systemImage: "checkmark.shield.fill",
                    kind: .newPassword
                )
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

private struct AuthInputField: View {
    enum Kind {
        case email
        case password
        case newPassword

        var textContentType: UITextContentType? {
            switch self {
            case .email:
                return .username
            case .password:
                return .password
            case .newPassword:
                return .newPassword
            }
        }

        var isSecure: Bool {
            switch self {
            case .email:
                return false
            case .password, .newPassword:
                return true
            }
        }

        var keyboardType: UIKeyboardType {
            switch self {
            case .email:
                return .emailAddress
            case .password, .newPassword:
                return .default
            }
        }
    }

    let title: String
    @Binding var text: String
    let systemImage: String
    let kind: Kind

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Group {
                if kind.isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }
            .textContentType(kind.textContentType)
            .keyboardType(kind.keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(minHeight: 48)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.vertical, 4)
    }
}
