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
    func signUp(email: String, password: String, confirmPassword: String) throws
    func signIn(email: String, password: String) throws
    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws
    func signOut()
}

struct AuthSession: Equatable {
    let email: String
    let token: String
}

struct StoredAccount: Codable, Equatable {
    let email: String
    var passwordHash: String
}

final class AuthSessionManager: ObservableObject, AuthSessionManaging {
    static let shared = AuthSessionManager(keychainService: KeychainService.shared)

    @Published private(set) var session: AuthSession?

    private let keychainService: KeychainServicing
    private let accountsKey = "auth.accounts"
    private let sessionEmailKey = "auth.session.email"
    private let sessionTokenKey = "auth.session.token"

    init(keychainService: KeychainServicing) {
        self.keychainService = keychainService
        restoreSession()
        AppLogger.log("Auth session manager initialized", category: .auth)
    }

    var isSignedIn: Bool {
        session != nil
    }

    var currentUserIdentifier: String {
        session?.email.lowercased() ?? "guest"
    }

    func signUp(email: String, password: String, confirmPassword: String) throws {
        let sanitizedEmail = normalize(email: email)
        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitizedEmail.isEmpty, !sanitizedPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        guard sanitizedEmail.contains("@") else {
            throw AuthError.invalidEmail
        }

        guard sanitizedPassword.count >= 6 else {
            throw AuthError.weakPassword
        }

        guard sanitizedPassword == confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw AuthError.passwordMismatch
        }

        var accounts = try loadAccounts()
        guard !accounts.contains(where: { $0.email == sanitizedEmail }) else {
            throw AuthError.accountExists
        }

        accounts.append(StoredAccount(email: sanitizedEmail, passwordHash: hash(password: sanitizedPassword)))
        try saveAccounts(accounts)
        try startSession(for: sanitizedEmail)
        AppLogger.log("User signed up: \(sanitizedEmail)", category: .auth, level: .success)
    }

    func signIn(email: String, password: String) throws {
        let sanitizedEmail = normalize(email: email)
        let sanitizedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitizedEmail.isEmpty, !sanitizedPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        let accounts = try loadAccounts()
        guard let account = accounts.first(where: { $0.email == sanitizedEmail }) else {
            throw AuthError.accountNotFound
        }

        guard account.passwordHash == hash(password: sanitizedPassword) else {
            throw AuthError.invalidCredentials
        }

        try startSession(for: sanitizedEmail)
        AppLogger.log("User signed in: \(sanitizedEmail)", category: .auth, level: .success)
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) throws {
        guard let email = session?.email else {
            throw AuthError.notSignedIn
        }

        let currentPassword = currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let newPassword = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !currentPassword.isEmpty, !newPassword.isEmpty else {
            throw AuthError.emptyFields
        }

        guard newPassword.count >= 6 else {
            throw AuthError.weakPassword
        }

        guard newPassword == confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw AuthError.passwordMismatch
        }

        var accounts = try loadAccounts()
        guard let index = accounts.firstIndex(where: { $0.email == email }) else {
            throw AuthError.accountNotFound
        }

        guard accounts[index].passwordHash == hash(password: currentPassword) else {
            throw AuthError.invalidCredentials
        }

        accounts[index].passwordHash = hash(password: newPassword)
        try saveAccounts(accounts)
        AppLogger.log("Password changed for \(email)", category: .auth, level: .success)
    }

    func signOut() {
        do {
            try keychainService.delete(account: sessionEmailKey)
            try keychainService.delete(account: sessionTokenKey)
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

        session = AuthSession(email: email, token: token)
        AppLogger.log("Session restored for \(email)", category: .auth, level: .success)
    }

    private func startSession(for email: String) throws {
        let token = UUID().uuidString
        try keychainService.save(Data(email.utf8), for: sessionEmailKey)
        try keychainService.save(Data(token.utf8), for: sessionTokenKey)
        session = AuthSession(email: email, token: token)
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

    private func normalize(email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func hash(password: String) -> String {
        let data = Data(password.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}


enum AuthError: Error, LocalizedError {
    case emptyFields
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case accountExists
    case accountNotFound
    case invalidCredentials
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
        case .notSignedIn:
            return Localization.string("auth.error.notSignedIn")
        }
    }
}
