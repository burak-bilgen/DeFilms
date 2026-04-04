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

    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var toastCenter: ToastCenter
    @State private var authDestination: AuthDestination?

    var body: some View {
        MainTabView()
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
                        SignInView()
                    case .signUp:
                        SignUpView()
                    }
                }
                .tint(.primary)
                .toast(item: $toastCenter.item, duration: 1.8)
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
