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
                    .submitLabel(.search)
                    .focused(isFocused)
                    .onSubmit(onSubmit)

                if !text.isEmpty {
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Button(Localization.string("movies.search.action")) {
                onSubmit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(.systemBackground))
            .frame(width: 76, height: 54)
            .background(Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}
