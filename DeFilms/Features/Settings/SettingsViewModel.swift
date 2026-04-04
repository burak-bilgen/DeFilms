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
    private weak var sessionManager: AuthSessionManaging?

    init(
        bundle: Bundle = .main,
        sessionManager: AuthSessionManaging? = nil
    ) {
        self.bundle = bundle
        self.sessionManager = sessionManager
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
}
