//
//  FavoriteMovieButton.swift
//  DeFilms
//

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
    @State private var isCreateListPresented = false

    var body: some View {
        Button(action: handleTap) {
            iconLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Localization.string("favorites.accessibility.manage"))
        .popover(isPresented: $isPickerPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            FavoriteListPickerView(movie: movie)
                .environmentObject(favoritesStore)
                .presentationCompactAdaptation(.popover)
        }
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                NewFavoriteListView(movie: movie)
            }
        }
    }

    @ViewBuilder
    private var iconLabel: some View {
        switch style {
        case .card:
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                Circle()
                    .strokeBorder(Color.white.opacity(0.45), lineWidth: 1)

                Image(systemName: favoritesStore.isMovieInAnyList(movieID: movie.id) ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(favoritesStore.isMovieInAnyList(movieID: movie.id) ? .black : .white)
            }
            .frame(width: 32, height: 32)
            .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 4)
        case .hero:
            let isSaved = favoritesStore.isMovieInAnyList(movieID: movie.id)

            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.headline.weight(.semibold))
                .foregroundStyle(isSaved ? .black : .white)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(Color.black.opacity(isSaved ? 0.92 : 0.22))
                )
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
    }

    private func handleTap() {
        if favoritesStore.lists.isEmpty {
            isCreateListPresented = true
        } else {
            isPickerPresented = true
        }
    }
}
