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

    private let keychainService: KeychainServicing
    private let accountsKey = "auth.accounts"
    private let sessionEmailKey = "auth.session.email"
    private let sessionTokenKey = "auth.session.token"
    private let sessionUserIdentifierKey = "auth.session.userIdentifier"
    private let guestIdentifierKey = "auth.guest.identifier"

    init(keychainService: KeychainServicing) {
        self.keychainService = keychainService
        restoreSession()
        AppLogger.log("Auth session manager initialized", category: .auth)
    }

    var isSignedIn: Bool {
        session != nil
    }

    var currentUserIdentifier: String {
        session?.userIdentifier ?? guestUserIdentifier
    }

    var guestUserIdentifier: String {
        (try? loadGuestUserIdentifier()) ?? "guest.device.default"
    }

    var legacyUserIdentifiers: [String] {
        var identifiers = ["guest", guestUserIdentifier]

        if let session {
            identifiers.append(session.email.lowercased())
        }

        return Array(Set(identifiers)).filter { $0 != currentUserIdentifier }
    }

    func signUp(email: String, password: String, confirmPassword: String) throws {
        let emailAddress = normalize(email: email)
        let passwordText = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailAddress.isEmpty, !passwordText.isEmpty else {
            throw AuthError.emptyFields
        }

        guard emailAddress.contains("@") else {
            throw AuthError.invalidEmail
        }

        guard passwordText.count >= 6 else {
            throw AuthError.weakPassword
        }

        guard passwordText == confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) else {
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
                passwordHash: hash(password: passwordText)
            )
        )
        try saveAccounts(accounts)
        try startSession(for: emailAddress)
        AppLogger.log("User signed up: \(emailAddress)", category: .auth, level: .success)
    }

    func signIn(email: String, password: String) throws {
        let emailAddress = normalize(email: email)
        let passwordText = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !emailAddress.isEmpty, !passwordText.isEmpty else {
            throw AuthError.emptyFields
        }

        guard emailAddress.contains("@") else {
            throw AuthError.invalidEmail
        }

        let accounts = try loadAccounts()
        guard let account = accounts.first(where: { $0.email == emailAddress }) else {
            throw AuthError.accountNotFound
        }

        guard account.passwordHash == hash(password: passwordText) else {
            throw AuthError.invalidCredentials
        }

        try startSession(for: emailAddress)
        AppLogger.log("User signed in: \(emailAddress)", category: .auth, level: .success)
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws {
        guard let email = session?.email else {
            throw AuthError.notSignedIn
        }

        let currentPassword = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let newPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let confirmedPassword = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmedPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        var accounts = try loadAccounts()
        guard let index = accounts.firstIndex(where: { $0.email == email }) else {
            throw AuthError.accountNotFound
        }

        guard accounts[index].passwordHash == hash(password: currentPassword) else {
            throw AuthError.currentPasswordIncorrect
        }

        guard newPassword != currentPassword else {
            throw AuthError.newPasswordMustDiffer
        }

        guard newPassword.count >= 6 else {
            throw AuthError.weakPassword
        }

        guard newPassword == confirmedPassword else {
            throw AuthError.passwordMismatch
        }

        accounts[index].passwordHash = hash(password: newPassword)
        try saveAccounts(accounts)
        AppLogger.log("Password changed for \(email)", category: .auth, level: .success)
    }

    func signOut() {
        do {
            try keychainService.delete(account: sessionEmailKey)
            try keychainService.delete(account: sessionTokenKey)
            try keychainService.delete(account: sessionUserIdentifierKey)
        } catch {
            AppLogger.log("Failed to clear keychain session", category: .auth, level: .error)
        }
        session = nil
        AppLogger.log("User signed out", category: .auth, level: .success)
        ToastCenter.shared.showSuccess(Localization.string("auth.toast.signedOut"))
    }

    private func restoreSession() {
        guard
            let emailData = try? keychainService.data(for: sessionEmailKey),
            let tokenData = try? keychainService.data(for: sessionTokenKey),
            let email = String(data: emailData, encoding: .utf8),
            let token = String(data: tokenData, encoding: .utf8)
        else {
            session = nil
            AppLogger.log("No active session restored", category: .auth, level: .info)
            return
        }

        let restoredIdentifier = restoreUserIdentifier(for: email)
        session = AuthSession(email: email, token: token, userIdentifier: restoredIdentifier)
        AppLogger.log("Session restored for \(email)", category: .auth, level: .success)
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

    private func loadGuestUserIdentifier() throws -> String {
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

    private func restoreUserIdentifier(for email: String) -> String {
        if let identifierData = try? keychainService.data(for: sessionUserIdentifierKey),
           let identifier = String(data: identifierData, encoding: .utf8),
           identifier.isEmpty == false {
            return identifier
        }

        let emailAddress = normalize(email: email)
        let accountIdentifier = (try? loadAccounts().first(where: { $0.email == emailAddress })?.id)

        if let accountIdentifier, accountIdentifier.isEmpty == false {
            try? keychainService.save(Data(accountIdentifier.utf8), for: sessionUserIdentifierKey)
            return accountIdentifier
        }

        return emailAddress
    }

    private func normalize(email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func hash(password: String) -> String {
        let data = Data(password.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}


enum AuthError: Error, LocalizedError, Equatable {
    case emptyFields
    case invalidEmail
    case weakPassword
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
        case .weakPassword:
            return Localization.string("auth.error.weakPassword")
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
