//
//  DesignSystem.swift
//  DeFilms
//

import SwiftUI

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 28
    static let xxxl: CGFloat = 38
}

enum AppCornerRadius {
    static let sm: CGFloat = 14
    static let md: CGFloat = 18
    static let lg: CGFloat = 24
    static let xl: CGFloat = 28
}

enum AppDimension {
    static let controlHeight: CGFloat = 44
    static let prominentButtonHeight: CGFloat = 50
    static let chipHeight: CGFloat = 30
    static let posterHeroWidth: CGFloat = 132
    static let posterHeroHeight: CGFloat = 198
    static let posterRailWidth: CGFloat = 146
    static let emptyStateMinHeight: CGFloat = 460
}

enum AppPalette {
    static let screenBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemBackground)
    static let cardAccentBackground = Color(.tertiarySystemBackground)
    static let border = Color.primary.opacity(0.08)
    static let shadow = Color.black.opacity(0.06)
}

enum AppAnimation {
    static let standard = Animation.easeInOut(duration: 0.22)
    static let gentleSpring = Animation.spring(response: 0.38, dampingFraction: 0.86)
    static let emphasizedSpring = Animation.spring(response: 0.46, dampingFraction: 0.82)
}

struct AppCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.lg
    var background: Color = AppPalette.cardBackground

    func body(content: Content) -> some View {
        content
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct AppElevatedCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppCornerRadius.lg
    var background: Color = AppPalette.cardBackground

    func body(content: Content) -> some View {
        content
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: AppPalette.shadow, radius: 14, x: 0, y: 8)
    }
}

struct PrimaryProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(.systemBackground))
            .frame(height: AppDimension.prominentButtonHeight)
            .padding(.horizontal, AppSpacing.lg)
            .background(Color.primary.opacity(configuration.isPressed ? 0.86 : 1))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct PressableScaleButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.985

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(AppAnimation.gentleSpring, value: configuration.isPressed)
    }
}

extension View {
    func appCardSurface(
        cornerRadius: CGFloat = AppCornerRadius.lg,
        background: Color = AppPalette.cardBackground
    ) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius, background: background))
    }

    func appElevatedSurface(
        cornerRadius: CGFloat = AppCornerRadius.lg,
        background: Color = AppPalette.cardBackground
    ) -> some View {
        modifier(AppElevatedCardModifier(cornerRadius: cornerRadius, background: background))
    }
}
