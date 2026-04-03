//
//  NewFavoriteListView.swift
//  DeFilms
//

import SwiftUI

struct NewFavoriteListView: View {
    let movie: Movie?

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isTextFieldFocused: Bool
    @State private var listName: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.string("favorites.create.heading"))
                    .font(.title2.weight(.bold))

                Text(Localization.string(movie == nil ? "favorites.create.subtitle.empty" : "favorites.create.subtitle.movie"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(Localization.string("favorites.picker.placeholder"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(Localization.string("favorites.picker.placeholder"), text: $listName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(createList)
            }

            Button(action: createList) {
                Text(Localization.string("favorites.action.create"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(listName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(listName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationTitle(Localization.string("favorites.create.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(Localization.string("common.cancel")) {
                    dismiss()
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            isTextFieldFocused = true
        }
    }

    private func createList() {
        guard let list = favoritesStore.createList(named: listName) else { return }
        if let movie {
            favoritesStore.add(movie: movie, to: list.id)
        }
        dismiss()
    }
}
