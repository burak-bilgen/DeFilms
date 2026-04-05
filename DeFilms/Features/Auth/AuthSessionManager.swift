//
//  AuthSessionManager.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import CryptoKit
import Foundation

protocol AuthSessionManaging: AnyObject {
    var session: AuthSession? { get }
    var isSignedIn: Bool { get }
    var currentUserIdentifier: String { get }
    var guestUserIdentifier: String { get }
    var legacyUserIdentifiers: [String] { get }
    func signUp(email: String, password: String, confirmPassword: String) throws
    func signIn(email: String, password: String) throws
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws
    func signOut()
}

struct AuthSession: Equatable {
    let email: String
    let token: String
    let userIdentifier: String
}

struct StoredAccount: Codable, Equatable {
    let id: String
    let email: String
    var passwordHash: String

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case passwordHash
    }

    init(id: String, email: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        email = try container.decode(String.self, forKey: .email)
        passwordHash = try container.decode(String.self, forKey: .passwordHash)
    }
}

final class AuthSessionManager: ObservableObject, AuthSessionManaging {
    static let shared = AuthSessionManager(keychainService: KeychainService.shared)

    @Published private(set) var session: AuthSession?
    @Published private(set) var toastItem: ToastItem?

    private let keychainService: KeychainServicing
    private let accountsKey = "auth.accounts"
    private let sessionEmailKey = "auth.session.email"
    private let sessionTokenKey = "auth.session.token"
    private let sessionUserIdentifierKey = "auth.session.userIdentifier"
    private let guestIdentifierKey = "auth.guest.identifier"

    init(keychainService: KeychainServicing) {
        self.keychainService = keychainService
        restoreSession()
        AppLogger.log("Auth session ready", category: .auth)
    }

    var isSignedIn: Bool {
        session != nil
    }

    var currentUserIdentifier: String {
        session?.userIdentifier ?? guestUserIdentifier
    }

    var guestUserIdentifier: String {
        (try? storedGuestUserIdentifier()) ?? "guest.device.default"
    }

    var legacyUserIdentifiers: [String] {
        var identifiers = ["guest", guestUserIdentifier]

        if let session {
            identifiers.append(session.email.lowercased())
        }

        return Array(Set(identifiers)).filter { $0 != currentUserIdentifier }
    }

    func signUp(email: String, password: String, confirmPassword: String) throws {
        let emailAddress = normalizedEmail(from: email)
        let passwordText = password
        let confirmedPassword = confirmPassword

        guard !emailAddress.isEmpty, !passwordText.isEmpty, !confirmedPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        guard isValidEmail(emailAddress) else {
            throw AuthError.invalidEmail
        }

        try validatePassword(passwordText)

        guard passwordText == confirmedPassword else {
            throw AuthError.passwordMismatch
        }

        var accounts = try loadAccounts()
        guard !accounts.contains(where: { $0.email == emailAddress }) else {
            throw AuthError.accountExists
        }

        accounts.append(
            StoredAccount(
                id: UUID().uuidString,
                email: emailAddress,
                passwordHash: makePasswordHash(from: passwordText)
            )
        )
        try saveAccounts(accounts)
        try startSession(for: emailAddress)
        AppLogger.log("Account created", category: .auth, level: .success)
    }

    func signIn(email: String, password: String) throws {
        let emailAddress = normalizedEmail(from: email)
        let passwordText = password

        guard !emailAddress.isEmpty, !passwordText.isEmpty else {
            throw AuthError.emptyFields
        }

        guard isValidEmail(emailAddress) else {
            throw AuthError.invalidEmail
        }

        let accounts = try loadAccounts()
        guard let account = accounts.first(where: { $0.email == emailAddress }) else {
            throw AuthError.accountNotFound
        }

        guard account.passwordHash == makePasswordHash(from: passwordText) else {
            throw AuthError.invalidCredentials
        }

        try startSession(for: emailAddress)
        AppLogger.log("Signed in", category: .auth, level: .success)
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws {
        guard let email = session?.email else {
            throw AuthError.notSignedIn
        }

        let currentPassword = currentPassword
        let newPassword = newPassword
        let confirmedPassword = confirmPassword

        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmedPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        var accounts = try loadAccounts()
        guard let index = accounts.firstIndex(where: { $0.email == email }) else {
            throw AuthError.accountNotFound
        }

        guard accounts[index].passwordHash == makePasswordHash(from: currentPassword) else {
            throw AuthError.currentPasswordIncorrect
        }

        guard newPassword != currentPassword else {
            throw AuthError.newPasswordMustDiffer
        }

        try validatePassword(newPassword)

        guard newPassword == confirmedPassword else {
            throw AuthError.passwordMismatch
        }

        accounts[index].passwordHash = makePasswordHash(from: newPassword)
        try saveAccounts(accounts)
        AppLogger.log("Password updated", category: .auth, level: .success)
    }

    func signOut() {
        do {
            try keychainService.delete(account: sessionEmailKey)
            try keychainService.delete(account: sessionTokenKey)
            try keychainService.delete(account: sessionUserIdentifierKey)
        } catch {
            AppLogger.log("Couldn't clear the saved session", category: .auth, level: .error)
        }
        session = nil
        AppLogger.log("Signed out", category: .auth, level: .success)
        toastItem = .success(Localization.string("auth.toast.signedOut"))
    }

    func clearToast() {
        toastItem = nil
    }

    private func restoreSession() {
        guard
            let emailData = try? keychainService.data(for: sessionEmailKey),
            let tokenData = try? keychainService.data(for: sessionTokenKey),
            let email = String(data: emailData, encoding: .utf8),
            let token = String(data: tokenData, encoding: .utf8)
        else {
            session = nil
            AppLogger.log("No saved session found", category: .auth, level: .info)
            return
        }

        let userIdentifier = recoverUserIdentifier(for: email)
        session = AuthSession(email: email, token: token, userIdentifier: userIdentifier)
        AppLogger.log("Session restored", category: .auth, level: .success)
    }

    private func startSession(for email: String) throws {
        let accounts = try loadAccounts()
        guard let account = accounts.first(where: { $0.email == email }) else {
            throw AuthError.accountNotFound
        }

        let token = UUID().uuidString
        try keychainService.save(Data(email.utf8), for: sessionEmailKey)
        try keychainService.save(Data(token.utf8), for: sessionTokenKey)
        try keychainService.save(Data(account.id.utf8), for: sessionUserIdentifierKey)
        session = AuthSession(email: email, token: token, userIdentifier: account.id)
    }

    private func loadAccounts() throws -> [StoredAccount] {
        guard let data = try keychainService.data(for: accountsKey) else {
            return []
        }

        return try JSONDecoder().decode([StoredAccount].self, from: data)
    }

    private func saveAccounts(_ accounts: [StoredAccount]) throws {
        let data = try JSONEncoder().encode(accounts)
        try keychainService.save(data, for: accountsKey)
    }

    private func storedGuestUserIdentifier() throws -> String {
        if
            let data = try keychainService.data(for: guestIdentifierKey),
            let identifier = String(data: data, encoding: .utf8),
            identifier.isEmpty == false
        {
            return identifier
        }

        let identifier = UUID().uuidString
        try keychainService.save(Data(identifier.utf8), for: guestIdentifierKey)
        return identifier
    }

    private func recoverUserIdentifier(for email: String) -> String {
        if let identifierData = try? keychainService.data(for: sessionUserIdentifierKey),
           let identifier = String(data: identifierData, encoding: .utf8),
           identifier.isEmpty == false {
            return identifier
        }

        // Older builds keyed favorites by email. If we can still resolve that
        // account, persist the canonical identifier once and reuse it from then on.
        let emailAddress = normalizedEmail(from: email)
        let accountIdentifier = (try? loadAccounts().first(where: { $0.email == emailAddress })?.id)

        if let accountIdentifier, accountIdentifier.isEmpty == false {
            try? keychainService.save(Data(accountIdentifier.utf8), for: sessionUserIdentifierKey)
            return accountIdentifier
        }

        return emailAddress
    }

    private func normalizedEmail(from email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private func makePasswordHash(from password: String) -> String {
        let data = Data(password.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }

    private func validatePassword(_ password: String) throws {
        let hasMinimumLength = password.count >= 8
        let hasUppercase = password.contains(where: \.isUppercase)
        let hasLowercase = password.contains(where: \.isLowercase)
        let hasDigit = password.contains(where: \.isNumber)
        let hasWhitespace = password.contains(where: \.isWhitespace)

        guard hasMinimumLength, hasUppercase, hasLowercase, hasDigit, !hasWhitespace else {
            throw AuthError.invalidPasswordFormat
        }
    }
}
enum AuthError: Error, LocalizedError, Equatable {
    case emptyFields
    case invalidEmail
    case invalidPasswordFormat
    case passwordMismatch
    case accountExists
    case accountNotFound
    case invalidCredentials
    case currentPasswordIncorrect
    case newPasswordMustDiffer
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .emptyFields:
            return Localization.string("auth.error.emptyFields")
        case .invalidEmail:
            return Localization.string("auth.error.invalidEmail")
        case .invalidPasswordFormat:
            return Localization.string("auth.error.invalidPasswordFormat")
        case .passwordMismatch:
            return Localization.string("auth.error.passwordMismatch")
        case .accountExists:
            return Localization.string("auth.error.accountExists")
        case .accountNotFound:
            return Localization.string("auth.error.accountNotFound")
        case .invalidCredentials:
            return Localization.string("auth.error.invalidCredentials")
        case .currentPasswordIncorrect:
            return Localization.string("auth.error.currentPasswordIncorrect")
        case .newPasswordMustDiffer:
            return Localization.string("auth.error.newPasswordMustDiffer")
        case .notSignedIn:
            return Localization.string("auth.error.notSignedIn")
        }
    }
}
