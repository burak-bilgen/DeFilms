//
//  Settings.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var sessionManager: AuthSessionManager

    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                languageSection
                accountSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Localization.string("settings.title"))
            .confirmationDialog(Localization.string("settings.account.logout"), isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
                Button(Localization.string("settings.account.logout"), role: .destructive) {
                    sessionManager.signOut()
                }

                Button(Localization.string("common.cancel"), role: .cancel) {}
            } message: {
                Text(Localization.string("settings.account.logout.message"))
            }
        }
    }

    private var appearanceSection: some View {
        Section(Localization.string("settings.section.appearance")) {
            NavigationLink {
                ThemeSelectionView()
            } label: {
                SettingsValueRow(
                    symbol: "circle.lefthalf.filled",
                    title: Localization.string("settings.appearance.theme"),
                    value: Localization.string("theme.\(preferences.selectedTheme.rawValue)")
                )
            }
        }
    }

    private var languageSection: some View {
        Section(Localization.string("settings.section.language")) {
            NavigationLink {
                LanguageSelectionView()
            } label: {
                SettingsValueRow(
                    symbol: "globe",
                    title: Localization.string("settings.language.appLanguage"),
                    value: Localization.string("language.\(preferences.selectedLanguage.rawValue)")
                )
            }
        }
    }

    private var accountSection: some View {
        Section(Localization.string("settings.section.account")) {
            if sessionManager.isSignedIn {
                SettingsValueRow(
                    symbol: "person.crop.circle",
                    title: Localization.string("settings.account.status"),
                    value: sessionManager.session?.email ?? ""
                )

                NavigationLink {
                    ChangePasswordView()
                } label: {
                    SettingsSimpleRow(symbol: "key.fill", title: Localization.string("auth.changePassword"))
                }

                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    SettingsSimpleRow(symbol: "rectangle.portrait.and.arrow.right", title: Localization.string("settings.account.logout"))
                }
            } else {
                NavigationLink {
                    SignInView()
                } label: {
                    SettingsSimpleRow(symbol: "person.badge.key", title: Localization.string("auth.signIn"))
                }

                NavigationLink {
                    SignUpView()
                } label: {
                    SettingsSimpleRow(symbol: "person.crop.circle.badge.plus", title: Localization.string("auth.signUp"))
                }

                Text(Localization.string("settings.account.signedOutDescription"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var aboutSection: some View {
        Section(Localization.string("settings.section.about")) {
            SettingsValueRow(
                symbol: "info.circle",
                title: Localization.string("settings.about.version"),
                value: viewModel.appVersionText
            )
        }
    }
}

private struct SettingsValueRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            Text(title)

            Spacer()

            Text(value)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 28)
    }
}

private struct SettingsSimpleRow: View {
    let symbol: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(title)
        }
        .frame(minHeight: 28)
    }
}

private struct ThemeSelectionView: View {
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
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

private struct LanguageSelectionView: View {
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        List {
            languageRow(.english)
            languageRow(.turkish)
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
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}
