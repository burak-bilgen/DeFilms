//
//  SettingsFactory.swift
//  DeFilms
//

import Foundation

final class SettingsFactory {
    private let sessionManager: AuthSessionManager
    private let authFormService: AuthFormServicing
    private let accountDeletionService: LocalAccountDeleting

    init(
        sessionManager: AuthSessionManager,
        favoritesRepository: FavoritesRepositoryProtocol,
        recentSearchRepository: RecentSearchRepositoryProtocol
    ) {
        self.sessionManager = sessionManager
        self.authFormService = AuthFormService(sessionManager: sessionManager)
        self.accountDeletionService = LocalAccountDeletionService(
            sessionManager: sessionManager,
            favoritesRepository: favoritesRepository,
            recentSearchRepository: recentSearchRepository
        )
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            bundle: .main,
            sessionManager: sessionManager,
            accountDeletionService: accountDeletionService
        )
    }

    func makeSignInViewModel() -> SignInViewModel {
        SignInViewModel(authFormService: authFormService)
    }

    func makeSignUpViewModel() -> SignUpViewModel {
        SignUpViewModel(authFormService: authFormService)
    }

    func makeChangePasswordViewModel() -> ChangePasswordViewModel {
        ChangePasswordViewModel(authFormService: authFormService)
    }
}
