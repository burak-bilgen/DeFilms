
import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    var titleFont: Font = .subheadline
    var contentSpacing: CGFloat = AppSpacing.sm
    var metadataSpacing: CGFloat = AppSpacing.xxs
    var posterCornerRadius: CGFloat = AppCornerRadius.sm
    var posterWidth: CGFloat = AppDimension.posterRailWidth
    var posterHeight: CGFloat = AppDimension.posterRailHeight
    var showsListButton: Bool = true

    @EnvironmentObject private var listsStore: ListsStore
    @EnvironmentObject private var movieStatusStore: UserMovieStatusStore

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            ZStack(alignment: .top) {
                PosterImageView(
                    url: movie.posterURL,
                    cornerRadius: posterCornerRadius,
                    placeholderSystemImage: "photo"
                )
                .frame(width: posterWidth, height: posterHeight)
                .background(
                    RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppPalette.cardBackground,
                                    AppPalette.cardAccentBackground
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.32), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .overlay(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: posterCornerRadius, style: .continuous))
                )
                .fixedSize()

                HStack(alignment: .top) {
                    statusBadge

                    Spacer(minLength: 0)

                    if showsListButton {
                        listButton
                    }
                }
                .padding(AppSpacing.xs)
                .frame(width: posterWidth, alignment: .top)
            }
            .frame(width: posterWidth, height: posterHeight, alignment: .top)
            .padding(.bottom, AppSpacing.xs - 2)

            VStack(alignment: .leading, spacing: metadataSpacing) {
                Text(movie.title)
                    .font(titleFont)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .foregroundStyle(.primary)

                Text(movie.releaseYear)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var listButton: some View {
        MovieListButton(movie: movie, style: .card)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let status = movieStatusStore.status(for: movie)

        if status.isWatched {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.green.opacity(0.9))
                .clipShape(Circle())
                .accessibilityLabel(Localization.string("movies.status.watched"))
        } else if status.isWatchlisted {
            Image(systemName: "clock.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue.opacity(0.9))
                .clipShape(Circle())
                .accessibilityLabel(Localization.string("movies.status.watchlist"))
        }
    }
}
