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

            if !viewModel.genreNames.isEmpty {
                detailSection(title: Localization.string("movies.detail.genres")) {
                    MovieGenreBubbleWrapView(items: Array(viewModel.genreNames.prefix(5)))
                }
            }

            detailSection(title: Localization.string("movies.detail.overview")) {
                Text(viewModel.overview)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(primaryBodyColor)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .padding(AppSpacing.xl)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
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

    private var sectionTitleColor: Color {
        colorScheme == .dark ? .white.opacity(0.46) : .black.opacity(0.46)
    }
}

private struct MovieGenreBubbleWrapView: View {
    let items: [String]

    var body: some View {
        ViewThatFits(in: .vertical) {
            HStack(spacing: 10) {
                ForEach(items.prefix(3), id: \.self) { item in
                    chip(item)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(Array(items.prefix(6)).chunked(into: 2).enumerated()), id: \.offset) { entry in
                    HStack(spacing: 10) {
                        ForEach(entry.element, id: \.self) { item in
                            chip(item)
                        }
                    }
                }
            }
        }
    }

    private func chip(_ item: String) -> some View {
        Text(item)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary.opacity(0.86))
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Color(.secondarySystemBackground))
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

struct MoviePeopleCarouselSection: View {
    let title: String
    let people: [PersonItem]

    @Environment(\.openURL) private var openURL

    @MainActor
    init(title: String, members: [MovieCrewMember]) {
        self.title = title
        self.people = members.map(PersonItem.init)
    }

    @MainActor
    init(title: String, members: [MovieCastMember]) {
        self.title = title
        self.people = members.map(PersonItem.init)
    }

    var body: some View {
        MovieDetailCarouselCard(title: title) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(people) { person in
                        CastBubbleView(
                            name: person.name,
                            imageURL: person.imageURL,
                            imdbURL: person.imdbURL
                        ) { url in
                            openURL(url)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 2)
            }
        }
    }
}

struct MoviePlatformCarouselSection: View {
    let title: String
    let platforms: [MovieStreamingPlatform]

    @Environment(\.openURL) private var openURL

    var body: some View {
        MovieDetailCarouselCard(title: title) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(platforms) { platform in
                        StreamingPlatformBubbleView(platform: platform) { url in
                            openURL(url)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 2)
            }
        }
    }
}

struct MovieDetailCarouselSection: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator<MovieRoute>

    let title: String
    let movies: [Movie]

    var body: some View {
        MovieDetailCarouselCard(title: title) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppSpacing.lg + 2) {
                    ForEach(movies) { movie in
                        MovieCardNavigationLink(movie: movie, cardStyle: .rail) {
                            coordinator.push(.detail(movie))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, AppSpacing.xxs - 2)
            }
        }
    }
}

private struct MovieDetailCarouselCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(sectionTitleColor)
                .padding(.horizontal, 4)

            content
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.lg)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.2 : 0.08), radius: 20, y: 10)
        .padding(.horizontal, 18)
    }

    private var cardBackground: Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.11, blue: 0.14)
            : Color(.systemBackground)
    }

    private var sectionTitleColor: Color {
        colorScheme == .dark ? .white.opacity(0.46) : .black.opacity(0.46)
    }
}

extension MoviePeopleCarouselSection {
    struct PersonItem: Identifiable {
        let id: Int
        let name: String
        let imageURL: URL?
        let imdbURL: URL?

        init(member: MovieCrewMember) {
            id = member.id
            name = member.name
            imageURL = member.imageURL
            imdbURL = member.imdbURL
        }

        init(member: MovieCastMember) {
            id = member.id
            name = member.name
            imageURL = member.imageURL
            imdbURL = member.imdbURL
        }
    }
}

private func sectionTitle(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .tracking(0.8)
        .foregroundStyle(.primary.opacity(0.78))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(Capsule())
        .padding(.horizontal, 18)
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
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(imdbURL == nil)
        .opacity(imdbURL == nil ? 0.88 : 1)
    }
}

private struct StreamingPlatformBubbleView: View {
    let platform: MovieStreamingPlatform
    let openLink: (URL) -> Void

    var body: some View {
        Button {
            guard let linkURL = platform.linkURL else { return }
            openLink(linkURL)
        } label: {
            VStack(spacing: 8) {
                PosterImageView(
                    url: platform.logoURL,
                    cornerRadius: 20,
                    placeholderSystemImage: "play.tv.fill"
                )
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )

                Text(platform.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 84, height: 32, alignment: .top)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .frame(width: 104, height: 132, alignment: .top)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(platform.linkURL == nil)
        .opacity(platform.linkURL == nil ? 0.88 : 1)
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
