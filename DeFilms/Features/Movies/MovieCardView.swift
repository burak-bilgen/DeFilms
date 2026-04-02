//
//  MovieCardView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MovieCardView: View {
    let movie: Movie

    @EnvironmentObject private var favoritesStore: FavoritesStore
    @State private var isPickerPresented: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                PosterImageView(
                    url: movie.posterURL,
                    cornerRadius: 8,
                    placeholderSystemImage: "photo",
                )
                .frame(height: 240)

                Button {
                    isPickerPresented = true
                } label: {
                    Image(systemName: favoritesStore.isMovieInAnyList(movieID: movie.id) ? "bookmark.fill" : "bookmark")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(8)
            }

            Text(movie.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(movie.releaseYear)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $isPickerPresented) {
            FavoriteListPickerView(movie: movie)
                .environmentObject(favoritesStore)
        }
    }
}
