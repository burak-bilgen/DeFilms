//
//  SettingsViewModel.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var isDeletingAccount = false
    @Published private(set) var toastItem: ToastItem?

    private let bundle: Bundle
    private weak var sessionManager: AuthSessionManaging?
    private let accountDeletionService: LocalAccountDeleting?

    init(
        bundle: Bundle = .main,
        sessionManager: AuthSessionManaging? = nil,
        accountDeletionService: LocalAccountDeleting? = nil
    ) {
        self.bundle = bundle
        self.sessionManager = sessionManager
        self.accountDeletionService = accountDeletionService
    }

    var appVersionText: String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var signedInEmail: String? {
        sessionManager?.session?.email
    }

    func signOut() {
        sessionManager?.signOut()
    }

    func deleteLocalAccount() async {
        guard !isDeletingAccount else { return }
        guard let accountDeletionService else {
            toastItem = .error(Localization.string("settings.account.delete.error"))
            return
        }

        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await accountDeletionService.deleteCurrentAccountAndData()
            toastItem = .success(Localization.string("settings.account.delete.success"))
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? Localization.string("settings.account.delete.error")
            toastItem = .error(message)
        }
    }

    func clearToast() {
        toastItem = nil
    }
}
