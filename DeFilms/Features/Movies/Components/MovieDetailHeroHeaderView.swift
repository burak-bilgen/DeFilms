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

        VStack(spacing: 24) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .offset(y: collapseProgress * 8)

            Spacer()

            heroContent
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .offset(y: -collapseProgress * 26)
                .scaleEffect(1 - (collapseProgress * 0.06), anchor: .bottomLeading)
                .opacity(contentOpacity)
        }
        .frame(height: heroHeight)
    }

    private var topBar: some View {
        HStack {
            topBarButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            FavoriteMovieButton(movie: movie, style: .hero)
        }
    }

    private var heroContent: some View {
        HStack(alignment: .bottom, spacing: 18) {
            PosterImageView(
                url: viewModel.posterURL,
                cornerRadius: 22,
                placeholderSystemImage: "film"
            )
            .frame(width: 132, height: 198)
            .shadow(color: .black.opacity(0.25), radius: 18, y: 12)

            VStack(alignment: .leading, spacing: 14) {
                Text(viewModel.title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if !viewModel.heroFacts.isEmpty {
                    heroFacts
                }

                HStack(spacing: 12) {
                    MovieDetailRatingBadge(ratingText: viewModel.ratingText, style: .hero)

                    trailerButton
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var heroFacts: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.subheadline.weight(.bold))

                Text(viewModel.trailerButtonTitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(viewModel.hasTrailer ? .white : Color.white.opacity(0.5))
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.black.opacity(0.34))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.hasTrailer)
    }

    private func topBarButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
    }
}
