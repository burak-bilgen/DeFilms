
import SwiftUI

struct FavoriteMovieButton: View {
    enum Style {
        case card
        case hero
    }

    let movie: Movie
    let style: Style

    @EnvironmentObject private var favoritesStore: FavoritesStore

    @State private var isPickerPresented = false

    var body: some View {
        Button(action: handleTap) {
            iconLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .fullScreenCover(isPresented: $isPickerPresented) {
            FavoriteListPickerModalView(movie: movie)
                .environmentObject(favoritesStore)
        }
    }

    @ViewBuilder
    private var iconLabel: some View {
        let isSaved = favoritesStore.isMovieInAnyList(movieID: movie.id)
        let selectedBackground = Color(red: 0.96, green: 0.74, blue: 0.22)

        switch style {
        case .card:
            ZStack {
                if isSaved {
                    Circle()
                        .fill(selectedBackground)
                } else {
                    Circle()
                        .fill(.ultraThinMaterial)
                }
                Circle()
                    .strokeBorder(isSaved ? selectedBackground.opacity(0.95) : Color.white.opacity(0.45), lineWidth: 1)

                Image(systemName: isSaved ? "play.rectangle.on.rectangle.fill" : "plus.rectangle.fill.on.rectangle.fill")
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(isSaved ? .black : .white)
            }
            .frame(width: 28, height: 28)
            .shadow(color: isSaved ? selectedBackground.opacity(0.45) : Color.black.opacity(0.16), radius: isSaved ? 10 : 6, x: 0, y: isSaved ? 5 : 3)
            .accessibilityHidden(true)
        case .hero:
            Image(systemName: isSaved ? "play.rectangle.on.rectangle.fill" : "plus.rectangle.fill.on.rectangle.fill")
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSaved ? .black : .white)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(isSaved ? selectedBackground : Color.black.opacity(0.22))
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(isSaved ? selectedBackground.opacity(0.95) : Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: isSaved ? selectedBackground.opacity(0.4) : .clear, radius: 12, x: 0, y: 6)
                .accessibilityHidden(true)
        }
    }

    private var accessibilityLabel: String {
        if favoritesStore.isMovieInAnyList(movieID: movie.id) {
            return Localization.string("favorites.manage.movie")
        }

        return Localization.string("favorites.action.add")
    }

    private func handleTap() {
        guard !isPickerPresented else { return }
        isPickerPresented = true
    }
}
