//
//  SettingsAccountViews.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI
import UIKit

struct SignInView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = SignInViewModel()

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
                    if viewModel.submit(using: sessionManager) {
                        dismiss()
                    }
                }
                .disabled(!isSubmitEnabled)
            }
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = SignUpViewModel()

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
                    if viewModel.submit(using: sessionManager) {
                        dismiss()
                    }
                }
                .disabled(!isSubmitEnabled)
            }
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel = ChangePasswordViewModel()

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
                    if viewModel.submit(using: sessionManager) {
                        dismiss()
                    }
                }
                .disabled(!isSubmitEnabled)
            }
        }
    }
}

private struct AuthFormContainer<Content: View>: View {
    var title: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            content
        }
        .tint(.primary)
        .navigationTitle(title ?? "")
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
                return nil
            case .newPassword:
                return nil
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

        var placeholder: String {
            switch self {
            case .email:
                return Localization.string("auth.placeholder.email")
            case .password:
                return Localization.string("auth.placeholder.password")
            case .newPassword:
                return Localization.string("auth.placeholder.newPassword")
            }
        }
    }

    let title: String
    @Binding var text: String
    let systemImage: String
    let kind: Kind
    @State private var isFocused = false
    @State private var isPasswordVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Group {
                    if kind.isSecure {
                        NeutralSecureField(
                            placeholder: kind.placeholder,
                            text: $text,
                            isSecureEntry: !isPasswordVisible,
                            onFocusChange: { isFocused = $0 }
                        )
                    } else {
                        TextField(kind.placeholder, text: $text, onEditingChanged: { editing in
                            isFocused = editing
                        })
                    }
                }
                .textContentType(kind.textContentType)
                .keyboardType(kind.keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .environment(\.layoutDirection, .leftToRight)

                if kind.isSecure && text.isEmpty == false {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 18, height: 18)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        Localization.string(
                            isPasswordVisible ? "auth.password.hide" : "auth.password.show"
                        )
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppPalette.cardBackground,
                                AppPalette.cardAccentBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isFocused ? Color.primary.opacity(0.22) : AppPalette.border,
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(
                color: isFocused ? Color.primary.opacity(0.08) : AppPalette.shadow,
                radius: isFocused ? 12 : 8,
                x: 0,
                y: isFocused ? 6 : 4
            )
        }
        .padding(.vertical, 4)
    }
}

private struct NeutralSecureField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let isSecureEntry: Bool
    let onFocusChange: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onFocusChange: onFocusChange)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.isSecureTextEntry = isSecureEntry
        textField.textContentType = nil
        textField.passwordRules = nil
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no
        textField.keyboardType = .asciiCapable
        textField.returnKeyType = .done
        textField.borderStyle = .none
        textField.backgroundColor = .clear
        textField.tintColor = UIColor.label
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        uiView.placeholder = placeholder
        if uiView.isSecureTextEntry != isSecureEntry {
            uiView.isSecureTextEntry = isSecureEntry
            if uiView.isFirstResponder {
                let existingText = uiView.text
                uiView.text = nil
                uiView.text = existingText
            }
        }

    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String
        private let onFocusChange: (Bool) -> Void

        init(text: Binding<String>, onFocusChange: @escaping (Bool) -> Void) {
            _text = text
            self.onFocusChange = onFocusChange
        }

        @objc func textDidChange(_ textField: UITextField) {
            let sanitizedText = (textField.text ?? "").filter { !$0.isWhitespace }
            if textField.text != sanitizedText {
                textField.text = sanitizedText
            }
            text = sanitizedText
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            onFocusChange(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            onFocusChange(false)
        }
    }
}
