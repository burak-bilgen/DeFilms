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
                    kind: .email,
                    accessibilityIdentifier: "auth.signIn.email"
                )

                AuthInputField(
                    title: Localization.string("auth.password"),
                    text: $viewModel.password,
                    systemImage: "lock.fill",
                    kind: .password,
                    accessibilityIdentifier: "auth.signIn.password"
                )
            }

            Section {
                Button {
                    if viewModel.submit() {
                        dismiss()
                    }
                } label: {
                    Text(Localization.string("auth.signIn"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryProminentButtonStyle())
                .disabled(!isSubmitEnabled)
                .opacity(isSubmitEnabled ? 1 : 0.5)
                .accessibilityIdentifier("auth.signIn.submit")
            }
        }
        .animation(AppAnimation.standard, value: isSubmitEnabled)
        .onChange(of: viewModel.toastItem?.id) { _ in
            guard let item = viewModel.toastItem else { return }
            toastCenter.show(message: item.message, style: item.style)
            viewModel.clearToast()
        }
    }
}
