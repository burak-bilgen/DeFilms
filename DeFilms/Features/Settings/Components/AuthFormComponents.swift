
import SwiftUI
import UIKit

struct AuthFormContainer<Content: View>: View {
    var title: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        Form {
            content
        }
        .tint(.primary)
        .scrollContentBackground(.hidden)
        .background(AppPalette.screenBackground)
        .navigationTitle(title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AuthInputField: View {
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
    let accessibilityIdentifier: String?
    @State private var isFocused = false
    @State private var isPasswordVisible = false

    init(
        title: String,
        text: Binding<String>,
        systemImage: String,
        kind: Kind,
        accessibilityIdentifier: String? = nil
    ) {
        self.title = title
        _text = text
        self.systemImage = systemImage
        self.kind = kind
        self.accessibilityIdentifier = accessibilityIdentifier
    }

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
                            onFocusChange: { isFocused = $0 },
                            accessibilityIdentifier: accessibilityIdentifier
                        )
                    } else {
                        TextField(kind.placeholder, text: $text, onEditingChanged: { editing in
                            isFocused = editing
                        })
                        .accessibilityIdentifier(accessibilityIdentifier ?? "")
                    }
                }
                .textContentType(kind.textContentType)
                .keyboardType(kind.keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .environment(\.layoutDirection, .leftToRight)
                .frame(maxWidth: .infinity, alignment: .leading)

                if kind.isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 34, height: 34)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .opacity(text.isEmpty ? 0 : 1)
                    .disabled(text.isEmpty)
                    .accessibilityLabel(
                        Localization.string(
                            isPasswordVisible ? "auth.password.hide" : "auth.password.show"
                        )
                    )
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
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

struct NeutralSecureField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    let isSecureEntry: Bool
    let onFocusChange: (Bool) -> Void
    let accessibilityIdentifier: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onFocusChange: onFocusChange)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.accessibilityIdentifier = accessibilityIdentifier
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
        uiView.accessibilityIdentifier = accessibilityIdentifier
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
            let textWithoutSpaces = (textField.text ?? "").filter { !$0.isWhitespace }
            if textField.text != textWithoutSpaces {
                textField.text = textWithoutSpaces
            }
            text = textWithoutSpaces
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            onFocusChange(true)
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            onFocusChange(false)
        }
    }
}
