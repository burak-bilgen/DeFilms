
import Combine
import SwiftUI

struct ChangePasswordView: View {
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
                    kind: .password,
                    accessibilityIdentifier: "auth.changePassword.currentPassword"
                )
                AuthInputField(
                    title: Localization.string("auth.newPassword"),
                    text: $viewModel.newPassword,
                    systemImage: "lock.open.fill",
                    kind: .newPassword,
                    accessibilityIdentifier: "auth.changePassword.newPassword"
                )
                AuthInputField(
                    title: Localization.string("auth.confirmPassword"),
                    text: $viewModel.confirmPassword,
                    systemImage: "checkmark.shield.fill",
                    kind: .newPassword,
                    accessibilityIdentifier: "auth.changePassword.confirmPassword"
                )
            }

            Section {
                Button(Localization.string("auth.changePassword")) {
                    if viewModel.submit() {
                        dismiss()
                    }
                }
                .buttonStyle(PrimaryProminentButtonStyle())
                .disabled(!isSubmitEnabled)
                .accessibilityIdentifier("auth.changePassword.submit")
            }
        }
        .animation(AppAnimation.standard, value: isSubmitEnabled)
        .relayToast(from: viewModel.$toastItem.eraseToAnyPublisher()) {
            viewModel.clearToast()
        }
    }
}
