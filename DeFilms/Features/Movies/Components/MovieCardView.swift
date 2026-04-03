//
//  MovieCardView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    var posterAspectRatio: CGFloat = 0.62
    var titleFont: Font = .subheadline
    var contentSpacing: CGFloat = 14
    var metadataSpacing: CGFloat = 4
    var posterCornerRadius: CGFloat = 14

    @EnvironmentObject private var favoritesStore: FavoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            ZStack(alignment: .topTrailing) {
                PosterImageView(
                    url: movie.posterURL,
                    cornerRadius: posterCornerRadius,
                    placeholderSystemImage: "photo"
                )
                .aspectRatio(posterAspectRatio, contentMode: .fit)
                .background(
                    RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(.secondarySystemBackground),
                                    Color(.tertiarySystemBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .overlay(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous))
                )

                favoriteButton
                    .padding(8)
            }
            .padding(.bottom, 6)

            VStack(alignment: .leading, spacing: metadataSpacing) {
                Text(movie.title)
                    .font(titleFont)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
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
        FavoriteMovieButton(movie: movie, style: .card)
    }
}
