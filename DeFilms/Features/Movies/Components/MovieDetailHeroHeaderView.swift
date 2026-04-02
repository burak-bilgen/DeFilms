//
//  MovieDetailHeroHeaderView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailHeroHeaderView: View {
    let movie: Movie
    @ObservedObject var viewModel: MovieDetailViewModel

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            PosterImageView(
                url: viewModel.heroPosterURL,
                cornerRadius: 0,
                placeholderSystemImage: "film"
            )
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.08),
                        Color.black.opacity(0.16),
                        Color.black.opacity(0.56)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipped()

            HStack {
                topBarButton(systemImage: "chevron.left") {
                    dismiss()
                }

                Spacer()

                topBarButton(
                    systemImage: favoritesStore.isMovieInAnyList(movieID: movie.id) ? "bookmark.fill" : "bookmark"
                ) {
                    favoritesStore.toggleFavorite(movie: movie)
                }
                .accessibilityLabel(
                    favoritesStore.isMovieInAnyList(movieID: movie.id)
                        ? Localization.string("favorites.accessibility.remove")
                        : Localization.string("favorites.accessibility.add")
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
        }
    }

    private func topBarButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(.black.opacity(0.28))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
