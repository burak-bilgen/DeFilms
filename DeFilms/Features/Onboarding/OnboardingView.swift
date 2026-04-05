//
//  OnboardingView.swift
//  DeFilms
//

import SwiftUI

struct OnboardingView: View {
    let continueAsGuest: () -> Void
    let signIn: () -> Void
    let signUp: () -> Void

    @State private var isHeaderVisible = false
    @State private var isFeaturesVisible = false
    @State private var isActionsVisible = false

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    featureStack
                    actionStack
                }
                .padding(.horizontal, 24)
            }
        }
        .statusBarHidden()
        .task {
            withAnimation(AppAnimation.gentleSpring) {
                isHeaderVisible = true
            }

            try? await Task.sleep(nanoseconds: 90_000_000)
            withAnimation(AppAnimation.gentleSpring) {
                isFeaturesVisible = true
            }

            try? await Task.sleep(nanoseconds: 90_000_000)
            withAnimation(AppAnimation.gentleSpring) {
                isActionsVisible = true
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.93, blue: 0.88),
                    Color(red: 0.95, green: 0.90, blue: 0.83),
                    Color(red: 0.88, green: 0.90, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.white.opacity(0.46))
                .frame(width: 280, height: 280)
                .blur(radius: 18)
                .offset(x: -110, y: -260)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(18))
                .offset(x: 150, y: -180)
                .blur(radius: 8)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Localization.string("onboarding.eyebrow"))
                .font(.footnote.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(Color.primary.opacity(0.55))

            Text(Localization.string("onboarding.title"))
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.primary)

            Text(Localization.string("onboarding.subtitle"))
                .font(.body)
                .foregroundStyle(Color.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .opacity(isHeaderVisible ? 1 : 0)
        .offset(y: isHeaderVisible ? 0 : 18)
    }

    private var featureStack: some View {
        VStack(spacing: 12) {
            featureCard(
                icon: "popcorn.fill",
                title: Localization.string("onboarding.feature.discovery.title"),
                message: Localization.string("onboarding.feature.discovery.body")
            )
            featureCard(
                icon: "line.3.horizontal.decrease.circle.fill",
                title: Localization.string("onboarding.feature.curation.title"),
                message: Localization.string("onboarding.feature.curation.body")
            )
            featureCard(
                icon: "person.crop.circle.badge.checkmark",
                title: Localization.string("onboarding.feature.account.title"),
                message: Localization.string("onboarding.feature.account.body")
            )
        }
        .opacity(isFeaturesVisible ? 1 : 0)
        .offset(y: isFeaturesVisible ? 0 : 24)
    }

    private var actionStack: some View {
        VStack(spacing: 8) {
            Button(Localization.string("auth.signUp"), action: signUp)
            .buttonStyle(OnboardingPrimaryButtonStyle())
            .accessibilityIdentifier("onboarding.signUp")

            Button(Localization.string("auth.signIn"), action: signIn)
            .buttonStyle(OnboardingSecondaryButtonStyle())
            .accessibilityIdentifier("onboarding.signIn")

            Button(Localization.string("onboarding.action.guest"), action: continueAsGuest)
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.72))
            .padding(.top, 15)
            .accessibilityIdentifier("onboarding.continueAsGuest")
            
            Spacer(minLength: 50)

            Text(Localization.string("onboarding.footnote"))
                .font(.footnote)
                .foregroundStyle(Color.primary.opacity(0.35))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4)
        .opacity(isActionsVisible ? 1 : 0)
        .offset(y: isActionsVisible ? 0 : 20)
    }

    private func featureCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.primary)
                .frame(width: 22)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.62))
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.58), lineWidth: 1)
        )
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(configuration.isPressed ? 0.82 : 0.94))
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

private struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.62 : 0.78))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.84), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
