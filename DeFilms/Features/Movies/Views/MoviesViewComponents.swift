
import SwiftUI

struct MoviesHeaderBar: View {
    let openLists: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 72)
                .accessibilityLabel(Localization.string("app.logo"))

            Spacer()

            Button(action: openLists) {
                Image(systemName: "rectangle.stack.badge.play")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppPalette.border, lineWidth: 1)
                    )
            }
            .buttonStyle(PressableScaleButtonStyle())
            .accessibilityLabel(Localization.string("lists.navigate"))
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, 2)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity)
        .background(.clear)
        .shadow(color: AppPalette.shadow.opacity(0.8), radius: 10, x: 0, y: 6)
        .zIndex(1)
    }
}

struct MoviesSearchSummaryCard: View {
    let title: String
    let subtitle: String
    let badgeText: String
    let badgeSystemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: AppSpacing.md)

            Label(badgeText, systemImage: badgeSystemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())
        }
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [
                    AppPalette.cardBackground,
                    AppPalette.cardAccentBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous))
        .shadow(color: AppPalette.shadow.opacity(0.7), radius: 12, x: 0, y: 8)
    }
}

struct MovieDecisionCard: View {
    let stats: UserMovieStats
    let primaryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: "sparkles.tv")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(Color.primary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(Localization.string("movies.decision.title"))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(decisionSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.sm) {
                    statChip(value: stats.watchlistCount, title: Localization.string("movies.stats.watchlist"))
                    statChip(value: stats.watchedCount, title: Localization.string("movies.stats.watched"))
                    if let averageRating = stats.averageRating {
                        statChip(value: String(format: "%.1f", averageRating), title: Localization.string("movies.stats.avgRating"))
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    statChip(value: stats.watchlistCount, title: Localization.string("movies.stats.watchlist"))
                    statChip(value: stats.watchedCount, title: Localization.string("movies.stats.watched"))
                    if let averageRating = stats.averageRating {
                        statChip(value: String(format: "%.1f", averageRating), title: Localization.string("movies.stats.avgRating"))
                    }
                }
            }

            Button(action: primaryAction) {
                Label(Localization.string("movies.decision.action"), systemImage: "shuffle")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryProminentButtonStyle())
        }
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [
                    AppPalette.cardBackground,
                    AppPalette.cardAccentBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous))
        .shadow(color: AppPalette.shadow.opacity(0.7), radius: 12, x: 0, y: 8)
    }

    private var decisionSubtitle: String {
        if stats.watchlistCount > 0 {
            return Localization.string("movies.decision.subtitle.watchlist", stats.watchlistCount)
        }

        if stats.watchedCount > 0 || stats.ratedCount > 0 {
            return Localization.string("movies.decision.subtitle.personal")
        }

        return Localization.string("movies.decision.subtitle.empty")
    }

    private func statChip(value: Int, title: String) -> some View {
        statChip(value: "\(value)", title: title)
    }

    private func statChip(value: String, title: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Text(value)
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, AppSpacing.sm)
        .frame(height: 30)
        .background(Color.primary.opacity(0.06))
        .clipShape(Capsule())
    }
}

struct AppleIntelligenceHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Image(systemName: "apple.intelligence")
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 58, height: 58)
                    .background(Color.primary.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(Localization.string("movies.ai.help.title"))
                        .font(.title3.weight(.bold))

                    Text(Localization.string("movies.ai.help.message"))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    helpStep(Localization.string("movies.ai.help.step1"))
                    helpStep(Localization.string("movies.ai.help.step2"))
                    helpStep(Localization.string("movies.ai.help.step3"))
                }

                Spacer(minLength: 0)
            }
            .padding(AppSpacing.lg)
            .background(AppPalette.screenBackground)
            .navigationTitle(Localization.string("movies.ai.help.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Localization.string("common.done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func helpStep(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .font(.subheadline)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct MoviesSearchControlsRow: View {
    let shouldShowFilterControl: Bool
    let shouldShowSortControl: Bool
    let shouldShowResetControls: Bool
    let selectedSortOption: MovieSortOption
    let openFilters: () -> Void
    let selectSortOption: (MovieSortOption) -> Void
    let resetSort: () -> Void
    let resetFiltersAndSort: () -> Void
    @State private var isSortOptionsPresented = false

    var body: some View {
        ViewThatFits(in: .horizontal) {
            controls

            ScrollView(.horizontal, showsIndicators: false) {
                controls
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppPalette.cardBackground.opacity(0.8))
        .overlay(
            Capsule()
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(Capsule())
        .confirmationDialog(
            Localization.string("movies.sort.title"),
            isPresented: $isSortOptionsPresented,
            titleVisibility: .visible
        ) {
            ForEach(MovieSortOption.allCases) { option in
                Button {
                    selectSortOption(option)
                } label: {
                    Text(
                        selectedSortOption == option
                            ? "\(option.title) ✓"
                            : option.title
                    )
                }
            }

            Button(Localization.string("movies.sort.reset")) {
                resetSort()
            }

            Button(Localization.string("common.cancel"), role: .cancel) {}
        }
    }

    @ViewBuilder
    private var controls: some View {
        HStack(spacing: 10) {
            if shouldShowFilterControl {
                Button(action: openFilters) {
                    SearchControlBubble(
                        title: Localization.string("movies.filter.title"),
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
                .buttonStyle(PressableScaleButtonStyle())
            }

            if shouldShowSortControl {
                Button {
                    isSortOptionsPresented = true
                } label: {
                    SearchControlBubble(
                        title: Localization.string("movies.sort.title"),
                        systemImage: "arrow.up.arrow.down.circle"
                    )
                }
                .buttonStyle(PressableScaleButtonStyle())
            }

            if shouldShowResetControls {
                Button(action: resetFiltersAndSort) {
                    SearchControlIconBubble(systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PressableScaleButtonStyle())
                .accessibilityLabel(Localization.string("movies.filter.reset"))
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.92)))
            }
        }
    }
}

private struct SearchControlBubble: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .frame(width: 18, height: 18)
                .padding(8)
                .foregroundStyle(.primary)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                )

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.86)
        }
        .foregroundStyle(.primary)
        .frame(height: AppDimension.controlHeight)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(AppPalette.cardBackground)
        )
        .overlay(
            Capsule()
                .stroke(AppPalette.border, lineWidth: 1)
        )
    }
}

private struct SearchControlIconBubble: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: AppDimension.controlHeight, height: AppDimension.controlHeight)
            .background(
                Circle()
                    .fill(AppPalette.cardBackground)
            )
            .overlay(
                Circle()
                    .stroke(AppPalette.border, lineWidth: 1)
            )
    }
}

struct MovieSearchEmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    let animationName: String?

    var body: some View {
        MoviesMessageView(
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action,
            animationName: animationName
        )
        .frame(maxWidth: .infinity)
    }
}
