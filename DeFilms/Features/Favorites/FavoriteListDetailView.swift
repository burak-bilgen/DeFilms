//
//  FavoriteListDetailView.swift
//  DeFilms
//

import SwiftUI

struct FavoriteListDetailView: View {
    let listID: UUID

    @EnvironmentObject private var favoritesStore: FavoritesStore

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        Group {
            if let list = favoritesStore.list(withID: listID) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        FavoriteListDetailHeader(list: list)
                            .padding(.horizontal, 16)

                        if list.movies.isEmpty {
                            FavoriteListDetailEmptyState(listName: list.name)
                                .padding(.horizontal, 16)
                        } else {
                            LazyVGrid(columns: columns, spacing: 18) {
                                ForEach(list.movies) { movie in
                                    MovieCardNavigationLink(movie: movie.asMovie, cardStyle: .grid)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle(list.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                MoviesMessageView(
                    title: Localization.string("favorites.list.unavailable.title"),
                    message: Localization.string("favorites.list.unavailable.message"),
                    buttonTitle: nil,
                    action: nil
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
    }
}

private struct FavoriteListDetailHeader: View {
    let list: FavoriteList

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(list.name)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text(Localization.string("favorites.list.detail.subtitle", list.movies.count))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct FavoriteListDetailEmptyState: View {
    let listName: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(Localization.string("favorites.list.empty.title"))
                .font(.headline.weight(.bold))

            Text(Localization.string("favorites.list.empty.message", listName))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 22)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
