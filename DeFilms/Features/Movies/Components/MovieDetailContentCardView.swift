//
//  MovieDetailContentCardView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailContentCardView: View {
    @ObservedObject var viewModel: MovieDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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

            detailSection(title: Localization.string("movies.detail.overview")) {
                Text(viewModel.overview)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let castLine = viewModel.castLine {
                detailSection(title: Localization.string("movies.detail.cast")) {
                    Text(castLine)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.66))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !viewModel.genreNames.isEmpty {
                detailSection(title: Localization.string("movies.detail.genres")) {
                    WrapChipsView(items: Array(viewModel.genreNames.prefix(5)))
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
    }

    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.black.opacity(0.46))

            content()
        }
    }
}

struct MovieDetailRatingBadge: View {
    enum Style {
        case card
        case hero
    }

    let ratingText: String?
    var style: Style = .card

    var body: some View {
        ZStack {
            Circle()
                .fill(style == .hero ? Color.white.opacity(0.18) : Color.white)
            Circle()
                .stroke(borderColor, lineWidth: style == .hero ? 1 : 2)

            Text(ratingText ?? "--")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
        }
        .frame(width: 60, height: 60)
        .accessibilityLabel(Localization.string("movies.detail.rating", ratingText ?? "--"))
    }

    private var textColor: Color {
        style == .hero ? .white : .black
    }

    private var borderColor: Color {
        style == .hero ? Color.white.opacity(0.35) : Color.black.opacity(0.72)
    }
}
