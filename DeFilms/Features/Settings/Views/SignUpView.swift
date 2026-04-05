//
//  SignUpView.swift
//  DeFilms
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: SignUpViewModel

    init(viewModel: SignUpViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isSubmitEnabled: Bool {
        !viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.password.isEmpty &&
        !viewModel.confirmPassword.isEmpty
    }

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

            Section {
                Button(Localization.string("auth.createAccount")) {
                    if viewModel.submit() {
                        dismiss()
                    }
                }
                .disabled(!isSubmitEnabled)
            }
        }
        .onChange(of: viewModel.toastItem?.id) { _ in
            guard let item = viewModel.toastItem else { return }
            toastCenter.show(message: item.message, style: item.style)
            viewModel.clearToast()
        }
    }
}
