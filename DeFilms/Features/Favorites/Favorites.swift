//
//  Favorites.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @EnvironmentObject private var sessionManager: AuthSessionManager

    var body: some View {
        NavigationStack {
            Group {
                if favoritesStore.lists.isEmpty {
                    FavoritesEmptyState(
                        title: Localization.string("favorites.empty.title"),
                        message: Localization.string(sessionManager.isSignedIn ? "favorites.empty.signedIn" : "favorites.empty.signedOut")
                    )
                } else {
                    List {
                        ForEach(favoritesStore.lists) { list in
                            Section(list.name) {
                                ForEach(list.movies) { movie in
                                    HStack(spacing: 12) {
                                        PosterThumbnailView(path: movie.posterPath)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(movie.title)
                                                .font(.headline)
                                            Text(movie.releaseDate?.prefix(4) ?? "--")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(Localization.string("favorites.title"))
        }
    }
}

private struct PosterThumbnailView: View {
    let path: String?

    var body: some View {
        PosterImageView(
            url: path.flatMap { URL(string: APIConfig.imageBaseURL + $0) },
            cornerRadius: 10,
            placeholderSystemImage: "photo"
        )
        .frame(width: 54)
        .aspectRatio(2.0 / 3.0, contentMode: .fit)
    }
}

private struct FavoritesEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.weight(.semibold))

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
