//
//  MoviesSearchBar.swift
//  DeFilms
//

import SwiftUI

struct MoviesSearchBar: View {
    @Binding var text: String
    let isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                TextField(Localization.string("movies.search.placeholder"), text: $text)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .focused(isFocused)
                    .onSubmit(onSubmit)
                    .accessibilityLabel(Localization.string("movies.accessibility.searchField"))
                    .accessibilityIdentifier("movies.search.textField")

                if !text.isEmpty {
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Localization.string("movies.accessibility.clearSearch"))
                    .accessibilityIdentifier("movies.search.clearButton")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppDimension.controlHeight)
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))

            Button(Localization.string("movies.search.action")) {
                onSubmit()
            }
            .buttonStyle(PrimaryProminentButtonStyle())
            .accessibilityIdentifier("movies.search.submitButton")
        }
        .padding(AppSpacing.xxs + 2)
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
        .shadow(color: AppPalette.shadow, radius: 12, x: 0, y: 6)
    }
}
