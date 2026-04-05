//
//  Settings.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct SettingsView: View {
    let container: AppContainer
    @StateObject private var viewModel: SettingsViewModel

    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var sessionManager: AuthSessionManager
    @EnvironmentObject private var coordinator: SettingsCoordinator

    @State private var showLogoutConfirmation = false

    init(container: AppContainer, viewModel: SettingsViewModel) {
        self.container = container
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            accountOverviewSection
            appearanceSection
            languageSection
            accountSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppPalette.screenBackground)
        .navigationTitle(Localization.string("settings.title"))
        .animation(AppAnimation.standard, value: sessionManager.isSignedIn)
        .alert(Localization.string("settings.account.logout"), isPresented: $showLogoutConfirmation) {
            Button(Localization.string("settings.account.logout"), role: .destructive) {
                viewModel.signOut()
            }

            Button(Localization.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(Localization.string("settings.account.logout.message"))
        }
    }

    private var accountOverviewSection: some View {
        Section {
            SettingsAccountOverviewCard(
                email: viewModel.signedInEmail,
                isSignedIn: sessionManager.isSignedIn
            )
            .listRowInsets(EdgeInsets(top: AppSpacing.xxs, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
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
            .accessibilityIdentifier("settings.appearance.row")
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
            .accessibilityIdentifier("settings.language.row")
        }
    }

    private var accountSection: some View {
        Section {
            if sessionManager.isSignedIn {
                Button {
                    coordinator.show(.changePassword)
                } label: {
                    SettingsSimpleRow(symbol: "key.fill", title: Localization.string("auth.changePassword"))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.account.changePassword")

                Button(role: .destructive) {
                    showLogoutConfirmation = true
                } label: {
                    SettingsSimpleRow(symbol: "rectangle.portrait.and.arrow.right", title: Localization.string("settings.account.logout"))
                }
                .accessibilityIdentifier("settings.account.logout")
            } else {
                Button {
                    coordinator.show(.signIn)
                } label: {
                    SettingsSimpleRow(symbol: "person.badge.key", title: Localization.string("auth.signIn"))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.account.signIn")

                Button {
                    coordinator.show(.signUp)
                } label: {
                    SettingsSimpleRow(symbol: "person.crop.circle.badge.plus", title: Localization.string("auth.signUp"))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.account.signUp")
            }
        } header: {
            Text(Localization.string("settings.section.account"))
        } footer: {
            if !sessionManager.isSignedIn {
                Text(Localization.string("settings.account.signedOutDescription"))
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
