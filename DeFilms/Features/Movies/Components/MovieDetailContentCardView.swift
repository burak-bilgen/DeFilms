//
//  MovieDetailContentCardView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailContentCardView: View {
    @ObservedObject var viewModel: MovieDetailViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

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

            if !viewModel.genreNames.isEmpty {
                detailSection(title: Localization.string("movies.detail.genres")) {
                    WrapChipsView(items: Array(viewModel.genreNames.prefix(5)))
                }
            }

            detailSection(title: Localization.string("movies.detail.overview")) {
                Text(viewModel.overview)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(primaryBodyColor)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !viewModel.directors.isEmpty {
                detailSection(title: Localization.string("movies.detail.director")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(viewModel.directors) { member in
                                CastBubbleView(
                                    name: member.name,
                                    imageURL: member.imageURL,
                                    imdbURL: member.imdbURL
                                ) { url in
                                    openURL(url)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !viewModel.cast.isEmpty {
                detailSection(title: Localization.string("movies.detail.cast")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(viewModel.cast) { member in
                                CastBubbleView(
                                    name: member.name,
                                    imageURL: member.imageURL,
                                    imdbURL: member.imdbURL
                                ) { url in
                                    openURL(url)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
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

private struct CastBubbleView: View {
    let name: String
    let imageURL: URL?
    let imdbURL: URL?
    let openIMDb: (URL) -> Void

    var body: some View {
        Button {
            guard let imdbURL else { return }
            openIMDb(imdbURL)
        } label: {
            VStack(spacing: 8) {
                PosterImageView(
                    url: imageURL,
                    cornerRadius: 22,
                    placeholderSystemImage: "person.fill"
                )
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 1))

                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 82, height: 32, alignment: .top)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .frame(width: 102, height: 136, alignment: .top)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(imdbURL == nil)
        .opacity(imdbURL == nil ? 0.88 : 1)
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
