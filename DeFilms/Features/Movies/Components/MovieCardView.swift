
import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    var posterAspectRatio: CGFloat = 0.62
    var titleFont: Font = .subheadline
    var contentSpacing: CGFloat = AppSpacing.sm
    var metadataSpacing: CGFloat = AppSpacing.xxs
    var posterCornerRadius: CGFloat = AppCornerRadius.sm
    var showsFavoriteButton: Bool = true

    @EnvironmentObject private var favoritesStore: FavoritesStore

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            ZStack(alignment: .topTrailing) {
                PosterImageView(
                    url: movie.posterURL,
                    cornerRadius: posterCornerRadius,
                    placeholderSystemImage: "photo"
                )
                .aspectRatio(posterAspectRatio, contentMode: .fit)
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
                .frame(maxWidth: 150)

                if showsFavoriteButton {
                    favoriteButton
                        .padding(AppSpacing.xs)
                }
            }
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

    private var favoriteButton: some View {
        FavoriteMovieButton(movie: movie, style: .card)
    }
}
