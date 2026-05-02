
import SwiftUI

struct MovieListRow: View {
    let list: MovieList
    let openList: () -> Void

    var body: some View {
        Button(action: openList) {
            MovieListCard(list: list)
        }
        .buttonStyle(PressableScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.string("lists.accessibility.listSummary", list.name, list.movies.count))
        .accessibilityHint(Localization.string("movies.accessibility.openDetails"))
    }
}

struct ListsEmptyState: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
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
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryProminentButtonStyle())
            }
            .padding(AppSpacing.xxl)
            .frame(maxWidth: 420)
            .appElevatedSurface()
            .padding(.horizontal, AppSpacing.md)

            Spacer(minLength: 0)
                .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, AppSpacing.xxl)
        .background(AppPalette.screenBackground)
        .accessibilityElement(children: .contain)
    }
}

struct ListsSummaryCard: View {
    let listCount: Int
    let movieCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(Localization.string("lists.summary.title"))
                .font(.title2.weight(.bold))

            Text(Localization.string("lists.summary.subtitle", listCount, movieCount))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                summaryBadge(systemImage: "square.stack.3d.up.fill", text: Localization.string("lists.summary.lists", listCount))
                summaryBadge(systemImage: "film.stack.fill", text: Localization.string("lists.count", movieCount))
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

struct MovieListCard: View {
    let list: MovieList
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(list.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(Localization.string("lists.list.card.subtitle", list.movies.count))
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
                Text(Localization.string("lists.list.empty.inline"))
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
                        .aspectRatio(AppDimension.posterAspectRatio, contentMode: .fit)
                    }

                    ForEach(0..<max(0, 3 - min(list.movies.count, 3)), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.clear)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(AppDimension.posterAspectRatio, contentMode: .fit)
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
