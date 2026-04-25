
import Combine
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
            .id(preferences.interfaceLayoutRefreshToken)
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
                item: authModalBinding
            ) { destination in
                AuthEntryContainer {
                    switch destination {
                    case .signIn:
                        SignInView(
                            viewModel: container.settingsFactory.makeSignInViewModel(),
                            onSubmitSuccess: flowCoordinator.dismissModal
                        )
                    case .signUp:
                        SignUpView(
                            viewModel: container.settingsFactory.makeSignUpViewModel(),
                            onSubmitSuccess: flowCoordinator.dismissModal
                        )
                    }
                }
                .tint(.primary)
            }
            .environmentObject(flowCoordinator)
            .relayToast(from: sessionManager.$toastItem.eraseToAnyPublisher()) {
                sessionManager.clearToast()
            }
            .relayToast(from: favoritesStore.$toastItem.eraseToAnyPublisher()) {
                favoritesStore.clearToast()
            }
            .onChange(of: preferences.selectedTheme.rawValue) { _ in
                toastCenter.clear()
            }
            .onChange(of: preferences.selectedLanguage.rawValue) { _ in
                toastCenter.clear()
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
}

private struct LanguageChangeLoadingView: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.15)

            Text(Localization.string("settings.language.applying.title"))
                .font(.headline.weight(.semibold))

            Text(Localization.string("settings.language.applying.message"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
