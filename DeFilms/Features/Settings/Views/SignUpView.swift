
import Combine
import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: SignUpViewModel
    private let onSubmitSuccess: (() -> Void)?

    init(viewModel: SignUpViewModel, onSubmitSuccess: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSubmitSuccess = onSubmitSuccess
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
                    kind: .email,
                    accessibilityIdentifier: "auth.signUp.email"
                )
                AuthInputField(
                    title: Localization.string("auth.password"),
                    text: $viewModel.password,
                    systemImage: "lock.fill",
                    kind: .password,
                    accessibilityIdentifier: "auth.signUp.password"
                )
                AuthInputField(
                    title: Localization.string("auth.confirmPassword"),
                    text: $viewModel.confirmPassword,
                    systemImage: "checkmark.shield.fill",
                    kind: .password,
                    accessibilityIdentifier: "auth.signUp.confirmPassword"
                )
            }

            Section {
                Button {
                    if viewModel.submit() {
                        onSubmitSuccess?()
                        dismiss()
                    }
                } label: {
                    Text(Localization.string("auth.createAccount"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryProminentButtonStyle())
                .disabled(!isSubmitEnabled)
                .opacity(isSubmitEnabled ? 1 : 0.5)
                .accessibilityIdentifier("auth.signUp.submit")
            }
        }
        .animation(AppAnimation.standard, value: isSubmitEnabled)
        .relayToast(from: viewModel.$toastItem.eraseToAnyPublisher()) {
            viewModel.clearToast()
        }
    }
}
