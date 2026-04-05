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

    private var shouldBlockForConnectivity: Bool {
        connectivityMonitor.hasResolvedInitialStatus && !connectivityMonitor.isConnected
    }

    private var shouldBlockForLanguageChange: Bool {
        preferences.isApplyingLanguageChange
    }

    private var isInteractionBlocked: Bool {
        shouldBlockForConnectivity || shouldBlockForLanguageChange
    }

    private var shouldSuspendModalPresentations: Bool {
        isInteractionBlocked
    }

    var body: some View {
        ZStack {
            MainTabView(
                container: container,
                favoritesStore: favoritesStore
            )
            .blur(radius: isInteractionBlocked ? 6 : 0)
            .allowsHitTesting(!isInteractionBlocked)

            if shouldBlockForConnectivity {
                ConnectionBlockingView(
                    isChecking: connectivityMonitor.isChecking,
                    retryAction: connectivityMonitor.retryConnectionCheck
                )
                .transition(.opacity)
                .zIndex(1)
            }

            if shouldBlockForLanguageChange {
                LanguageChangeLoadingView()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96).combined(with: .opacity),
                        removal: .scale(scale: 0.985).combined(with: .opacity)
                    ))
                    .zIndex(2)
            }
        }
            .animation(AppAnimation.standard, value: shouldBlockForConnectivity)
            .animation(AppAnimation.emphasizedSpring, value: shouldBlockForLanguageChange)
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
            .fullScreenCover(
                item: authModalBinding,
                onDismiss: { flowCoordinator.dismissModal() }
            ) { destination in
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
            get: {
                !preferences.hasCompletedOnboarding &&
                !shouldSuspendModalPresentations &&
                flowCoordinator.modalRoute == nil
            },
            set: { isPresented in
                if isPresented == false {
                    preferences.hasCompletedOnboarding = true
                }
            }
        )
    }

    private var authModalBinding: Binding<AppModalRoute?> {
        Binding(
            get: { shouldSuspendModalPresentations ? nil : flowCoordinator.modalRoute },
            set: { newValue in
                if newValue == nil {
                    flowCoordinator.dismissModal()
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

private struct LanguageChangeLoadingView: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.15)

            Text(Localization.string("settings.language.appLanguage"))
                .font(.headline.weight(.semibold))
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.lg)
        .appElevatedSurface(cornerRadius: AppCornerRadius.lg, background: AppPalette.screenBackground)
        .padding(.horizontal, AppSpacing.lg)
        .scaleEffect(isVisible ? 1 : 0.965)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(AppAnimation.emphasizedSpring) {
                isVisible = true
            }
        }
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
