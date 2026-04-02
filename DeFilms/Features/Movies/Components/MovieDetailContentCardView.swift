//
//  MovieDetailContentCardView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailContentCardView: View {
    let movie: Movie
    @ObservedObject var viewModel: MovieDetailViewModel

    @EnvironmentObject private var favoritesStore: FavoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection

            if let errorMessage = viewModel.errorMessage {
                MoviesMessageView(
                    title: Localization.string("movies.detail.limited.title"),
                    message: errorMessage,
                    buttonTitle: Localization.string("common.retry"),
                    action: {
                        Task {
                            await viewModel.load()
                        }
                    }
                )
            }

            MovieDetailOverviewSectionView(overview: viewModel.overview)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 22, y: 10)
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 18) {
            PosterImageView(
                url: viewModel.posterURL,
                cornerRadius: 20,
                placeholderSystemImage: "photo"
            )
            .frame(width: 118)
            .aspectRatio(2.0 / 3.0, contentMode: .fit)
            .shadow(color: .black.opacity(0.14), radius: 14, y: 10)

            VStack(alignment: .leading, spacing: 14) {
                Text(viewModel.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                MovieDetailMetadataChipsView(viewModel: viewModel)

                if !viewModel.genreNames.isEmpty {
                    WrapChipsView(items: viewModel.genreNames)
                }

                favoriteButton
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var favoriteButton: some View {
        Button(
            favoritesStore.isMovieInAnyList(movieID: movie.id)
                ? Localization.string("favorites.action.remove")
                : Localization.string("favorites.action.add")
        ) {
            favoritesStore.toggleFavorite(movie: movie)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background(Color.primary)
        .clipShape(Capsule())
    }
}

private struct MovieDetailMetadataChipsView: View {
    @ObservedObject var viewModel: MovieDetailViewModel

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 8) {
                chipItems
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    chip(MovieMetaChip(title: viewModel.releaseYear, systemImage: "calendar", style: .light))
                    if let rating = viewModel.ratingText {
                        chip(MovieMetaChip(title: rating, systemImage: "star.fill", style: .light))
                    }
                }

                if let runtime = viewModel.runtimeText {
                    HStack(spacing: 8) {
                        chip(MovieMetaChip(title: runtime, systemImage: "clock", style: .light))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var chipItems: some View {
        chip(MovieMetaChip(title: viewModel.releaseYear, systemImage: "calendar", style: .light))

        if let rating = viewModel.ratingText {
            chip(MovieMetaChip(title: rating, systemImage: "star.fill", style: .light))
        }

        if let runtime = viewModel.runtimeText {
            chip(MovieMetaChip(title: runtime, systemImage: "clock", style: .light))
        }
    }

    private func chip<T: View>(_ content: T) -> some View {
        content.fixedSize()
    }
}

struct MovieDetailOverviewSectionView: View {
    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string("movies.detail.overview"))
                .font(.headline)

            Text(overview)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
