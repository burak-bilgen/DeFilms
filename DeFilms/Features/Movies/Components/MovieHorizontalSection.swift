//
//  MovieHorizontalSection.swift
//  DeFilms
//

import SwiftUI

struct MovieHorizontalSection: View {
    @EnvironmentObject private var coordinator: MovieCoordinator
    let title: String
    let movies: [Movie]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.title3.weight(.semibold))
                .padding(.horizontal, AppSpacing.md)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: AppSpacing.lg + 2) {
                    ForEach(movies) { movie in
                        MovieCardNavigationLink(movie: movie, cardStyle: .rail) {
                            coordinator.show(.detail(movie))
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xxs - 2)
            }
        }
    }
}
