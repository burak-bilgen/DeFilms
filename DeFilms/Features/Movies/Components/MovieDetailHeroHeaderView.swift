//
//  MovieDetailHeroHeaderView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailHeroHeaderView: View {
    let movie: Movie
    @ObservedObject var viewModel: MovieDetailViewModel
    let heroHeight: CGFloat
    let scrollOffset: CGFloat

    @Environment(\.dismiss) private var dismiss
    var body: some View {
        let collapseProgress = min(max(-scrollOffset / (heroHeight * 0.55), 0), 1)
        let contentOpacity = Double(1 - (collapseProgress * 0.22))

        VStack(spacing: AppSpacing.xl) {
            topBar
                .padding(.horizontal, 30)
                .padding(.top, 40)
                .offset(y: collapseProgress * 8)

            Spacer()

            heroContent
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
                .offset(y: -collapseProgress * 26)
                .scaleEffect(1 - (collapseProgress * 0.06), anchor: .bottomLeading)
                .opacity(contentOpacity)
        }
        .frame(height: heroHeight)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            topBarButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            VStack(spacing: 10) {
                FavoriteMovieButton(movie: movie, style: .hero)

                if let imdbURL = viewModel.imdbURL {
                    imdbShareButton(url: imdbURL)
                }
            }
        }
    }

    private var heroContent: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.lg - 2) {
            PosterImageView(
                url: viewModel.posterURL,
                cornerRadius: AppCornerRadius.md + 4,
                placeholderSystemImage: "film"
            )
            .frame(width: AppDimension.posterHeroWidth, height: AppDimension.posterHeroHeight)
            .shadow(color: .black.opacity(0.25), radius: 18, y: 12)

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(viewModel.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    if !viewModel.heroFacts.isEmpty {
                        heroFacts
                    }
                    
                    MovieDetailRatingBadge(ratingText: viewModel.ratingText, style: .hero)
                        .padding(.leading, AppSpacing.md)
                }

                if viewModel.hasTrailer {
                    trailerButton
                        .padding(.leading, -6)
                }
            }
            .padding(.bottom, AppSpacing.sm - 2)

            Spacer(minLength: 0)
        }
    }

    private var heroFacts: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            ForEach(viewModel.heroFacts, id: \.self) { fact in
                Text(fact)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.84))
            }
        }
    }

    private var trailerButton: some View {
        Button {
            viewModel.presentTrailer()
        } label: {
            detailActionButtonLabel(
                title: Localization.string("movies.detail.trailer.watch"),
                systemImage: "play.rectangle.fill"
            )
        }
        .buttonStyle(.plain)
    }

    private func imdbShareButton(url: URL) -> some View {
        ShareLink(item: url) {
            topBarIconButtonLabel(systemImage: "square.and.arrow.up")
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func detailActionButtonLabel(title: String, systemImage: String?) -> some View {
        HStack(spacing: AppSpacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
            }

            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.md + 2)
        .frame(height: AppDimension.controlHeight)
        .background(Color.black.opacity(0.28))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private func topBarButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            topBarIconButtonLabel(systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func topBarIconButtonLabel(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(
                Circle()
                    .fill(Color.black.opacity(0.22))
            )
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }
}
