//
//  AppEntryView.swift
//  DeFilms
//

import SwiftUI

struct AppEntryView: View {
    let container: AppContainer
    let favoritesStore: FavoritesStore
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @EnvironmentObject private var toastCenter: ToastCenter
    @EnvironmentObject private var connectivityMonitor: ConnectivityMonitor
    @StateObject private var flowCoordinator = AppFlowCoordinator()

    var body: some View {
        ZStack {
            MainTabView(
                container: container,
                favoritesStore: favoritesStore
            )
            .blur(radius: connectivityMonitor.isConnected ? 0 : 6)
            .allowsHitTesting(connectivityMonitor.isConnected)

            if !connectivityMonitor.isConnected {
                ConnectionBlockingView(
                    isChecking: connectivityMonitor.isChecking,
                    retryAction: connectivityMonitor.retryConnectionCheck
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
            .animation(AppAnimation.standard, value: connectivityMonitor.isConnected)
            .fullScreenCover(isPresented: onboardingBinding) {
                OnboardingView(
                    continueAsGuest: dismissOnboarding,
                    signIn: {
                        dismissOnboarding()
                        flowCoordinator.presentSignIn()
                    },
                    signUp: {
                        dismissOnboarding()
                        flowCoordinator.presentSignUp()
                    }
                )
            }
            .fullScreenCover(item: $flowCoordinator.modalRoute) { destination in
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
            .environmentObject(flowCoordinator)
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
            get: { !preferences.hasCompletedOnboarding && connectivityMonitor.isConnected },
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
    @EnvironmentObject private var flowCoordinator: AppFlowCoordinator
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(Localization.string("common.close")) {
                            flowCoordinator.dismissModal()
                            dismiss()
                        }
                    }
                }
        }
    }
}
