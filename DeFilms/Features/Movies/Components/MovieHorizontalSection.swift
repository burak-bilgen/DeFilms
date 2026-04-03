//
//  MovieHorizontalSection.swift
//  DeFilms
//

import SwiftUI

struct MovieHorizontalSection: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator<MovieRoute>
    let title: String
    let movies: [Movie]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(movies) { movie in
                        MovieCardNavigationLink(movie: movie, cardStyle: .rail) {
                            coordinator.push(.detail(movie))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
        }
    }
}
