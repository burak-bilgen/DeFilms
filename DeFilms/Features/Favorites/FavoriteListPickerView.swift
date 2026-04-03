//
//  FavoriteListPickerView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct FavoriteListPickerView: View {
    let movie: Movie

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss

    @State private var isCreateListPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Localization.string("favorites.picker.title"))
                        .font(.headline.weight(.bold))

                    Text(Localization.string("favorites.picker.subtitle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(Localization.string("common.done")) {
                    dismiss()
                }
                .font(.caption.weight(.semibold))
                .buttonStyle(.plain)
            }

            ForEach(favoritesStore.lists) { list in
                Button {
                    if favoritesStore.isMovieInList(movieID: movie.id, listID: list.id) {
                        favoritesStore.remove(movieID: movie.id, from: list.id)
                    } else {
                        favoritesStore.add(movie: movie, to: list.id)
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(list.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(Localization.string("favorites.count", list.movies.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: favoritesStore.isMovieInList(movieID: movie.id, listID: list.id) ? "checkmark.circle.fill" : "plus.circle")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(
                                favoritesStore.isMovieInList(movieID: movie.id, listID: list.id)
                                    ? Color.accentColor
                                    : .secondary
                            )
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button {
                isCreateListPresented = true
            } label: {
                Label(Localization.string("favorites.picker.newList"), systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 300)
        .background(Color(.systemBackground))
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                NewFavoriteListView(movie: movie)
            }
        }
    }
}
