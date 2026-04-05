//
//  AppEntryView.swift
//  DeFilms
//

import SwiftUI

struct AppEntryView: View {
    enum AuthDestination: Identifiable {
        case signIn
        case signUp

        var id: Self { self }
    }

    let container: AppContainer
    let favoritesStore: FavoritesStore
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @EnvironmentObject private var toastCenter: ToastCenter
    @State private var authDestination: AuthDestination?

    var body: some View {
        MainTabView(
            container: container,
            favoritesStore: favoritesStore
        )
            .fullScreenCover(isPresented: onboardingBinding) {
                OnboardingView(
                    continueAsGuest: dismissOnboarding,
                    signIn: {
                        dismissOnboarding()
                        authDestination = .signIn
                    },
                    signUp: {
                        dismissOnboarding()
                        authDestination = .signUp
                    }
                )
            }
            .fullScreenCover(item: $authDestination) { destination in
                AuthEntryContainer {
                    switch destination {
                    case .signIn:
                        SignInView(viewModel: container.settingsFactory.makeSignInViewModel())
                    case .signUp:
                        SignUpView(viewModel: container.settingsFactory.makeSignUpViewModel())
                    }
                }
                .tint(.primary)
                .toast(item: $toastCenter.item, duration: 1.8)
            }
            .onChange(of: sessionManager.toastItem?.id) { _ in
                relayToast(from: sessionManager.toastItem) {
                    sessionManager.clearToast()
                }
            }
            .onChange(of: favoritesStore.toastItem?.id) { _ in
                relayToast(from: favoritesStore.toastItem) {
                    favoritesStore.clearToast()
                }
            }
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !preferences.hasCompletedOnboarding },
            set: { isPresented in
                if isPresented == false {
                    preferences.hasCompletedOnboarding = true
                }
            }
        )
    }

    private func dismissOnboarding() {
        preferences.hasCompletedOnboarding = true
    }

    private func relayToast(from item: ToastItem?, onConsumed: () -> Void) {
        guard let item else { return }
        toastCenter.show(message: item.message, style: item.style)
        onConsumed()
    }
}

private struct AuthEntryContainer<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Localization.string("common.close")) {
                            dismiss()
                        }
                    }
                }
        }
    }
}
