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
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(Localization.string("movies.search.placeholder"), text: $text)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .focused(isFocused)
                    .onSubmit(onSubmit)
                    .accessibilityIdentifier("movies.search.textField")

                if !text.isEmpty {
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("movies.search.clearButton")
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .padding(.horizontal, 16)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(Localization.string("movies.search.action")) {
                onSubmit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(.systemBackground))
            .frame(width: 78, height: 44)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityIdentifier("movies.search.submitButton")
        }
        .padding(6)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color(.tertiarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}
