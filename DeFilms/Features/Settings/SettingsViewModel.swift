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
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    var appVersionText: String {
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var signedInEmail: String? {
        sessionManager?.session?.email
    }

    private weak var sessionManager: AuthSessionManaging?

    func bind(sessionManager: AuthSessionManaging) {
        self.sessionManager = sessionManager
    }

    func signOut() {
        sessionManager?.signOut()
    }
}
