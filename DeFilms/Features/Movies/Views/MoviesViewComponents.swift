//
//  MoviesScreenComponents.swift
//  DeFilms
//

import SwiftUI

struct MoviesHeaderBar: View {
    let openFavorites: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 72)
                .accessibilityLabel(Localization.string("app.logo"))

            Spacer()

            Button(action: openFavorites) {
                Image(systemName: "rectangle.stack.badge.play")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(AppPalette.cardBackground)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppPalette.border, lineWidth: 1)
                    )
            }
            .buttonStyle(PressableScaleButtonStyle())
            .accessibilityLabel(Localization.string("favorites.navigate"))
        }
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

struct MoviesSearchControlsRow: View {
    let shouldShowFilterControl: Bool
    let shouldShowSortControl: Bool
    let shouldShowResetControls: Bool
    let selectedSortOption: MovieSortOption
    let openFilters: () -> Void
    let selectSortOption: (MovieSortOption) -> Void
    let resetSort: () -> Void
    let resetFiltersAndSort: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if shouldShowFilterControl {
                Button(action: openFilters) {
                    SearchControlBubble(
                        title: Localization.string("movies.filter.title"),
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
                .buttonStyle(.plain)
            }

            if shouldShowSortControl {
                Menu {
                    ForEach(MovieSortOption.allCases) { option in
                        Button {
                            selectSortOption(option)
                        } label: {
                            if selectedSortOption == option {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }

                    Divider()

                    Button(Localization.string("movies.sort.reset"), action: resetSort)
                } label: {
                    SearchControlBubble(
                        title: Localization.string("movies.sort.title"),
                        systemImage: "arrow.up.arrow.down.circle"
                    )
                }
            }

            if shouldShowResetControls {
                Button(action: resetFiltersAndSort) {
                    SearchControlIconBubble(systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.string("movies.filter.reset"))
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.92)))
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppPalette.cardBackground.opacity(0.8))
        .overlay(
            Capsule()
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(Capsule())
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
