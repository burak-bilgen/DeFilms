
import SwiftUI

struct MovieDetailHeroHeaderView: View {
    let movie: Movie
    @ObservedObject var viewModel: MovieDetailViewModel
    let heroHeight: CGFloat
    let topSafeAreaInset: CGFloat
    let scrollOffset: CGFloat

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var movieStatusStore: UserMovieStatusStore
    @EnvironmentObject private var toastCenter: ToastCenter
    var body: some View {
        let collapseProgress = min(max(-scrollOffset / (heroHeight * 0.55), 0), 1)
        let contentOpacity = Double(1 - (collapseProgress * 0.22))

        ZStack(alignment: .top) {
            topBar
                .padding(.horizontal, 30)
                .padding(.top, topBarTopPadding)
                .offset(y: reduceMotion ? 0 : collapseProgress * 8)
                .zIndex(1)

            VStack {
                Spacer(minLength: 0)

                GeometryReader { geometry in
                    heroContent(width: geometry.size.width)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
                .frame(height: heroContentHeight)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxl)
            }
            .offset(y: reduceMotion ? -30 : -30 - (collapseProgress * 10))
            .scaleEffect(reduceMotion ? 1 : 1 - (collapseProgress * 0.06), anchor: .bottomLeading)
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

                if let tmdbURL = viewModel.tmdbURL {
                    shareButton(url: tmdbURL)
                }
            }
        }
    }

    private func heroContent(width: CGFloat) -> some View {
        Group {
            if shouldUseCompactLayout(for: width) {
                compactHeroContent(width: width)
            } else {
                regularHeroContent(width: width)
            }
        }
    }

    private var posterView: some View {
        PosterImageView(
            url: viewModel.posterURL,
            cornerRadius: AppCornerRadius.md + 4,
            placeholderSystemImage: "film"
        )
        .frame(width: AppDimension.posterHeroWidth, height: AppDimension.posterHeroHeight)
        .shadow(color: .black.opacity(0.25), radius: 18, y: 12)
        .accessibilityHidden(true)
    }

    private func titleBlock(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(viewModel.title)
                .font(.system(size: titleFontSize(for: width), weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 4 : 3)
                .minimumScaleFactor(0.84)
                .allowsTightening(true)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .vertical) {
                HStack(alignment: .top) {
                    if !viewModel.heroFacts.isEmpty {
                        heroFacts
                    }

                    if let ratingText = viewModel.ratingText {
                        MovieDetailRatingBadge(ratingText: ratingText, style: .hero)
                            .padding(.leading, AppSpacing.md)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if !viewModel.heroFacts.isEmpty {
                        heroFacts
                    }

                    if let ratingText = viewModel.ratingText {
                        MovieDetailRatingBadge(ratingText: ratingText, style: .hero)
                    }
                }
            }

            statusActions

            if viewModel.hasTrailer {
                trailerButton
                    .padding(.leading, -6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .layoutPriority(1)
    }

    private func regularHeroContent(width: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: heroContentSpacing(for: width)) {
            VStack(alignment: .leading, spacing: 0) {
                posterView
            }
            .fixedSize()

            VStack(alignment: .leading, spacing: 0) {
                titleBlock(width: width)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactHeroContent(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            posterView
            titleBlock(width: width)
        }
    }

    private var topBarTopPadding: CGFloat {
        max(topSafeAreaInset + 8, 34)
    }

    private var heroContentHeight: CGFloat {
        max(heroHeight - topBarTopPadding - 54, 260)
    }

    private func shouldUseCompactLayout(for width: CGFloat) -> Bool {
        width < 340 || dynamicTypeSize.isAccessibilitySize
    }

    private func titleFontSize(for width: CGFloat) -> CGFloat {
        guard !dynamicTypeSize.isAccessibilitySize else { return width < 360 ? 24 : 26 }

        switch (viewModel.title.count, width) {
        case (28..., ..<380):
            return 22
        case (22..., ..<380):
            return 24
        case (28..., _):
            return 26
        case (22..., _):
            return 28
        default:
            return width < 360 ? 27 : 30
        }
    }

    private func heroContentSpacing(for width: CGFloat) -> CGFloat {
        width < 380 || viewModel.title.count >= 22 ? AppSpacing.md : AppSpacing.lg
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

    private var statusActions: some View {
        let status = movieStatusStore.status(for: viewModel.movie)

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.xs) {
                watchlistButton(isSelected: status.isWatchlisted)
                watchedButton(isSelected: status.isWatched)
                ratingMenu(rating: status.rating)
                reminderButton
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                watchlistButton(isSelected: status.isWatchlisted)
                watchedButton(isSelected: status.isWatched)
                ratingMenu(rating: status.rating)
                reminderButton
            }
        }
    }

    private func watchlistButton(isSelected: Bool) -> some View {
        Button {
            movieStatusStore.toggleWatchlist(for: viewModel.movie)
        } label: {
            detailActionButtonLabel(
                title: Localization.string(isSelected ? "movies.status.watchlist.remove" : "movies.status.watchlist.add"),
                systemImage: isSelected ? "clock.fill" : "clock"
            )
        }
        .buttonStyle(.plain)
    }

    private var reminderButton: some View {
        Button {
            Task {
                let result = await MovieWatchReminderScheduler.scheduleTonightReminder(for: viewModel.movie)
                switch result {
                case .scheduled:
                    toastCenter.showSuccess(Localization.string("movies.reminder.scheduled"))
                case .denied:
                    toastCenter.showError(Localization.string("movies.reminder.denied"))
                case .failed:
                    toastCenter.showError(Localization.string("movies.reminder.failed"))
                }
            }
        } label: {
            detailActionButtonLabel(
                title: Localization.string("movies.reminder.action"),
                systemImage: "bell"
            )
        }
        .buttonStyle(.plain)
    }

    private func watchedButton(isSelected: Bool) -> some View {
        Button {
            movieStatusStore.toggleWatched(for: viewModel.movie)
        } label: {
            detailActionButtonLabel(
                title: Localization.string(isSelected ? "movies.status.watched" : "movies.status.markWatched"),
                systemImage: isSelected ? "checkmark.circle.fill" : "checkmark.circle"
            )
        }
        .buttonStyle(.plain)
    }

    private func ratingMenu(rating: Int?) -> some View {
        Menu {
            ForEach(1...5, id: \.self) { value in
                Button {
                    movieStatusStore.setRating(value, for: viewModel.movie)
                } label: {
                    Text(Localization.string("movies.status.rating.value", value))
                }
            }

            if rating != nil {
                Button(Localization.string("movies.status.rating.clear"), role: .destructive) {
                    movieStatusStore.setRating(nil, for: viewModel.movie)
                }
            }
        } label: {
            detailActionButtonLabel(
                title: rating.map { Localization.string("movies.status.rating.short", $0) } ?? Localization.string("movies.status.rating.add"),
                systemImage: rating == nil ? "star" : "star.fill"
            )
        }
        .buttonStyle(.plain)
    }

    private func shareButton(url: URL) -> some View {
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
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.md + 2)
        .frame(minHeight: AppDimension.controlHeight)
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
