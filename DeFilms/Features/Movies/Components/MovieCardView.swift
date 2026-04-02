//
//  MovieCardView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    var posterAspectRatio: CGFloat = 2.0 / 3.0
    var titleFont: Font = .subheadline
    var titleAreaHeight: CGFloat = 36

    @EnvironmentObject private var favoritesStore: FavoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                PosterImageView(
                    url: movie.posterURL,
                    cornerRadius: 14,
                    placeholderSystemImage: "photo"
                )
                .aspectRatio(posterAspectRatio, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                favoriteButton
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(titleFont)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(-0.5)
                    .frame(maxWidth: .infinity, minHeight: titleAreaHeight, maxHeight: titleAreaHeight, alignment: .topLeading)
                    .foregroundStyle(.primary)

                Text(movie.releaseYear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var favoriteButton: some View {
        Button {
            favoritesStore.toggleFavorite(movie: movie)
        } label: {
            Image(systemName: favoritesStore.isMovieInAnyList(movieID: movie.id) ? "bookmark.fill" : "bookmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(10)
                .background(Color.black.opacity(0.72))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            favoritesStore.isMovieInAnyList(movieID: movie.id)
                ? Localization.string("favorites.accessibility.remove")
                : Localization.string("favorites.accessibility.add")
        )
    }
}
