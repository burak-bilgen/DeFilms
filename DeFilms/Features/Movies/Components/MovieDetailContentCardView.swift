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
        GenreFlowLayout(horizontalSpacing: 10, verticalSpacing: 10) {
            ForEach(items, id: \.self) { item in
                chip(item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chip(_ item: String) -> some View {
        Text(item)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary.opacity(0.86))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, AppSpacing.md)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(people) { person in
                        CastBubbleView(
                            name: person.name,
                            imageURL: person.imageURL,
                            destinationURL: person.destinationURL
                        ) { url in
                            openURL(url)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
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
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, AppSpacing.md)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(platforms) { platform in
                        StreamingPlatformBubbleView(platform: platform) { url in
                            openURL(url)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, 2)
            }
        }
    }
}

struct MovieDetailCarouselSection: View {
    @EnvironmentObject private var coordinator: MovieCoordinator

    let title: String
    let movies: [Movie]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, AppSpacing.md)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppSpacing.xl + 6) {
                    ForEach(movies) { movie in
                        MovieCardNavigationLink(movie: movie, cardStyle: .rail) {
                            coordinator.show(.detail(movie))
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xxs - 2)
            }
        }
    }
}

struct MovieDetailSupplementarySectionsView: View {
    let directors: [MovieCrewMember]
    let cast: [MovieCastMember]
    let streamingPlatforms: [MovieStreamingPlatform]
    let similarMovies: [Movie]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if !directors.isEmpty {
                MoviePeopleCarouselSection(
                    title: Localization.string("movies.detail.director"),
                    members: directors
                )
            }

            if !cast.isEmpty {
                MoviePeopleCarouselSection(
                    title: Localization.string("movies.detail.cast"),
                    members: cast
                )
            }

            if !streamingPlatforms.isEmpty {
                MoviePlatformCarouselSection(
                    title: Localization.string("movies.detail.availableOn"),
                    platforms: streamingPlatforms
                )
            }

            if !similarMovies.isEmpty {
                MovieDetailCarouselSection(
                    title: Localization.string("movies.detail.similar"),
                    movies: similarMovies
                )
            }
        }
        .movieDetailSectionSurface()
    }
}

extension MoviePeopleCarouselSection {
    struct PersonItem: Identifiable {
        let id: Int
        let name: String
        let imageURL: URL?
        let destinationURL: URL?

        init(member: MovieCrewMember) {
            id = member.id
            name = member.name
            imageURL = member.imageURL
            destinationURL = member.tmdbURL
        }

        init(member: MovieCastMember) {
            id = member.id
            name = member.name
            imageURL = member.imageURL
            destinationURL = member.tmdbURL
        }
    }
}

private struct CastBubbleView: View {
    let name: String
    let imageURL: URL?
    let destinationURL: URL?
    let openDestination: (URL) -> Void

    var body: some View {
        Button {
            guard let destinationURL else { return }
            openDestination(destinationURL)
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
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(destinationURL == nil)
        .opacity(destinationURL == nil ? 0.88 : 1)
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
            .background(Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(platform.linkURL == nil)
        .opacity(platform.linkURL == nil ? 0.88 : 1)
    }
}

private struct GenreFlowLayout: Layout {
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = max(proposal.width ?? 320, 1)
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0

        // Measure chips row by row so long genres can wrap naturally instead of
        // being forced into a fixed-width grid.
        for subview in subviews {
            let size = measuredSize(for: subview, availableWidth: maxWidth)
            let spacing = currentRowWidth == 0 ? 0 : horizontalSpacing

            if currentRowWidth + spacing + size.width > maxWidth {
                totalWidth = max(totalWidth, currentRowWidth)
                if currentRowHeight > 0 {
                    totalHeight += currentRowHeight + verticalSpacing
                }
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth += spacing + size.width
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        totalWidth = max(totalWidth, currentRowWidth)
        totalHeight += currentRowHeight

        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = measuredSize(for: subview, availableWidth: max(bounds.width, 1))
            let spacing = currentX == bounds.minX ? 0 : horizontalSpacing

            if currentX + spacing + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + verticalSpacing
                rowHeight = 0
            } else {
                currentX += spacing
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func measuredSize(for subview: LayoutSubview, availableWidth: CGFloat) -> CGSize {
        let width = max(availableWidth, 1)
        return subview.sizeThatFits(
            ProposedViewSize(width: width, height: nil)
        )
    }
}

private struct MovieDetailSectionSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.vertical, AppSpacing.sm)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous))
            .padding(.horizontal, AppSpacing.md)
    }
}

private extension View {
    func movieDetailSectionSurface() -> some View {
        modifier(MovieDetailSectionSurfaceModifier())
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
