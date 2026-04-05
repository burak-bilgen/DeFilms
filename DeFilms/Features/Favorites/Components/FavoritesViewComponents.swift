//
//  FavoritesScreenComponents.swift
//  DeFilms
//

import SwiftUI

struct FavoriteListRow: View {
    let list: FavoriteList
    let openList: () -> Void
    let renameList: () -> Void
    let deleteList: () -> Void
    @State private var isActionsPresented = false

    var body: some View {
        Button(action: openList) {
            FavoriteListCard(list: list)
        }
        .buttonStyle(PressableScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.string("favorites.accessibility.listSummary", list.name, list.movies.count))
        .accessibilityHint(Localization.string("movies.accessibility.openDetails"))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    isActionsPresented = true
                }
        )
        .confirmationDialog(
            list.name,
            isPresented: $isActionsPresented,
            titleVisibility: .visible
        ) {
            Button(Localization.string("favorites.rename.title"), action: renameList)
            Button(Localization.string("favorites.delete.confirm"), role: .destructive, action: deleteList)
            Button(Localization.string("common.cancel"), role: .cancel) {}
        }
    }
}

struct FavoritesEmptyState: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack {
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.title3.weight(.bold))

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xxl)

                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryProminentButtonStyle())
            }
            .padding(AppSpacing.xxl)
            .frame(maxWidth: 420)
            .appElevatedSurface()
            .padding(.horizontal, AppSpacing.md)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppPalette.screenBackground)
        .accessibilityElement(children: .contain)
    }
}

struct FavoritesSummaryCard: View {
    let listCount: Int
    let movieCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(Localization.string("favorites.summary.title"))
                .font(.title2.weight(.bold))

            Text(Localization.string("favorites.summary.subtitle", listCount, movieCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                summaryBadge(systemImage: "square.stack.3d.up.fill", text: Localization.string("favorites.summary.lists", listCount))
                summaryBadge(systemImage: "film.stack.fill", text: Localization.string("favorites.count", movieCount))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
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
        .shadow(color: AppPalette.shadow.opacity(0.75), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }

    private func summaryBadge(systemImage: String, text: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(Color.primary.opacity(0.07))
            .clipShape(Capsule())
    }
}

struct FavoriteListCard: View {
    let list: FavoriteList
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(list.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(Localization.string("favorites.list.card.subtitle", list.movies.count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
            }

            if list.movies.isEmpty {
                Text(Localization.string("favorites.list.empty.inline"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 10) {
                    ForEach(Array(list.movies.prefix(3))) { movie in
                        PosterImageView(
                            url: movie.asMovie.posterURL,
                            cornerRadius: 16,
                            placeholderSystemImage: "film"
                        )
                        .frame(maxWidth: .infinity)
                        .aspectRatio(2.0 / 3.0, contentMode: .fit)
                    }

                    ForEach(0..<max(0, 3 - min(list.movies.count, 3)), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.clear)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(2.0 / 3.0, contentMode: .fit)
                            .hidden()
                    }
                }
            }
        }
        .padding(AppSpacing.md + 2)
        .appElevatedSurface()
        .accessibilityElement(children: .combine)
    }
}
