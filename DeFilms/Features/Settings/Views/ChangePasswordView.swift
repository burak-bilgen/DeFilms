//
//  ChangePasswordView.swift
//  DeFilms
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: ChangePasswordViewModel

    init(viewModel: ChangePasswordViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isSubmitEnabled: Bool {
        !viewModel.currentPassword.isEmpty &&
        !viewModel.newPassword.isEmpty &&
        !viewModel.confirmPassword.isEmpty
    }

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

            Section {
                Button(Localization.string("auth.changePassword")) {
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
