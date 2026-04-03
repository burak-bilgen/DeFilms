//
//  MovieDetailContentCardView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailContentCardView: View {
    @ObservedObject var viewModel: MovieDetailViewModel
    @Environment(\.colorScheme) private var colorScheme

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
                    .foregroundStyle(primaryBodyColor)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

//            if let castLine = viewModel.castLine {
//                detailSection(title: Localization.string("movies.detail.cast")) {
//                    Text(castLine)
//                        .font(.system(size: 15, weight: .medium, design: .rounded))
//                        .foregroundStyle(secondaryBodyColor)
//                        .lineSpacing(4)
//                        .fixedSize(horizontal: false, vertical: true)
//                }
//            }

            if !viewModel.genreNames.isEmpty {
                detailSection(title: Localization.string("movies.detail.genres")) {
                    WrapChipsView(items: Array(viewModel.genreNames.prefix(5)))
                }
            }
        }
        .padding(24)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.28 : 0.08), radius: 24, y: 12)
    }

    private func detailSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(sectionTitleColor)

            content()
        }
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.11, blue: 0.14)
            : Color(.systemBackground)
    }

    private var primaryBodyColor: Color {
        colorScheme == .dark ? .white.opacity(0.82) : .black.opacity(0.72)
    }

    private var secondaryBodyColor: Color {
        colorScheme == .dark ? .white.opacity(0.68) : .black.opacity(0.66)
    }

    private var sectionTitleColor: Color {
        colorScheme == .dark ? .white.opacity(0.46) : .black.opacity(0.46)
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
                .fill(style == .hero ? Color.white.opacity(0.18) : Color(.secondarySystemBackground))
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
        style == .hero ? .white : .primary
    }

    private var borderColor: Color {
        style == .hero ? Color.white.opacity(0.35) : Color.primary.opacity(0.72)
    }
}
