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
                AsyncImage(url: movie.posterURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                    case .failure:
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        }
                    @unknown default:
                        Color.gray.opacity(0.2)
                    }
                }
                .frame(height: 240)
                .cornerRadius(8)

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
