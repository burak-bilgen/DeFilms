//
//  MovieCardView.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MovieCardView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                        .scaledToFill()
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
            .frame(height: 180)
            .clipped()
            .cornerRadius(8)

            Text(movie.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(movie.releaseYear)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
