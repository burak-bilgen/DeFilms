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
    @State private var listPendingRemoval: FavoriteList?

    var body: some View {
        Button(action: handleTap) {
            iconLabel
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .popover(isPresented: $isPickerPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            FavoriteListPickerView(movie: movie)
                .environmentObject(favoritesStore)
                .presentationCompactAdaptation(.popover)
        }
        .confirmationDialog(
            Localization.string("favorites.remove.movie.title"),
            isPresented: Binding(
                get: { listPendingRemoval != nil },
                set: { isPresented in
                    if !isPresented {
                        listPendingRemoval = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(Localization.string("favorites.action.remove"), role: .destructive) {
                guard let listPendingRemoval else { return }
                favoritesStore.remove(movieID: movie.id, from: listPendingRemoval.id)
                self.listPendingRemoval = nil
            }

            Button(Localization.string("common.cancel"), role: .cancel) {
                listPendingRemoval = nil
            }
        } message: {
            Text(Localization.string("favorites.remove.from.list.message", listPendingRemoval?.name ?? ""))
        }
        .sheet(isPresented: $isCreateListPresented) {
            NavigationStack {
                NewFavoriteListView(movie: movie)
            }
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
            return Localization.string("favorites.action.remove")
        }

        return Localization.string("favorites.action.add")
    }

    private func handleTap() {
        let containingLists = favoritesStore.lists.filter { list in
            list.movies.contains { $0.id == movie.id }
        }

        if containingLists.count == 1 {
            listPendingRemoval = containingLists[0]
            return
        }

        if containingLists.count > 1 {
            isPickerPresented = true
            return
        }

        if favoritesStore.lists.isEmpty {
            isCreateListPresented = true
        } else if favoritesStore.lists.count == 1, let list = favoritesStore.lists.first {
            favoritesStore.add(movie: movie, to: list.id)
        } else {
            isPickerPresented = true
        }
    }
}
