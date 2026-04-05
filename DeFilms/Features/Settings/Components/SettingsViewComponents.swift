//
//  SettingsScreenComponents.swift
//  DeFilms
//

import SwiftUI

struct SettingsAccountOverviewCard: View {
    let email: String?
    let isSignedIn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 52, height: 52)

                Image(systemName: isSignedIn ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle.badge.plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(isSignedIn ? Localization.string("settings.account.status") : Localization.string("settings.section.account"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(email ?? Localization.string("settings.account.signedOutDescription"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [
                    AppPalette.cardBackground,
                    AppPalette.cardAccentBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct SettingsValueRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 28)
        .accessibilityElement(children: .combine)
    }
}

struct SettingsSimpleRow: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(title)
        }
        .frame(minHeight: 28)
        .accessibilityElement(children: .combine)
    }
}

struct ThemeSelectionView: View {
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        List {
            themeRow(.system)
            themeRow(.light)
            themeRow(.dark)
        }
        .navigationTitle(Localization.string("settings.appearance.theme"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func themeRow(_ theme: AppTheme) -> some View {
        Button {
            preferences.selectedTheme = theme
        } label: {
            HStack {
                Text(Localization.string("theme.\(theme.rawValue)"))
                    .foregroundStyle(.primary)
                Spacer()
                if preferences.selectedTheme == theme {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                }
            }
        }
        .accessibilityValue(preferences.selectedTheme == theme ? Localization.string("common.selected") : "")
    }
}

struct LanguageSelectionView: View {
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        List {
            languageRow(.english)
            languageRow(.turkish)
            languageRow(.arabic)
        }
        .navigationTitle(Localization.string("settings.language.appLanguage"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func languageRow(_ language: AppLanguage) -> some View {
        Button {
            preferences.selectedLanguage = language
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Localization.string("language.\(language.rawValue)"))
                        .foregroundStyle(.primary)
                    Text(language.rawValue.uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if preferences.selectedLanguage == language {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                }
            }
        }
        .accessibilityValue(preferences.selectedLanguage == language ? Localization.string("common.selected") : "")
    }
}
