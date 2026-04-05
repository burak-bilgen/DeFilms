//
//  SignInView.swift
//  DeFilms
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: SignInViewModel

    init(viewModel: SignInViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isSubmitEnabled: Bool {
        !viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.password.isEmpty
    }

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

            Section {
                Button(Localization.string("auth.signIn")) {
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
