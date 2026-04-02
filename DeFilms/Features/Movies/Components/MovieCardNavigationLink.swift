//
//  MovieCardNavigationLink.swift
//  DeFilms
//

import SwiftUI

enum MovieCardStyle {
    case grid
    case rail

    var titleFont: Font {
        switch self {
        case .grid:
            return .subheadline
        case .rail:
            return .footnote
        }
    }

    var titleHeight: CGFloat {
        switch self {
        case .grid:
            return 38
        case .rail:
            return 32
        }
    }

    var width: CGFloat? {
        switch self {
        case .grid:
            return nil
        case .rail:
            return 150
        }
    }
}

struct MovieCardNavigationLink: View {
    let movie: Movie
    let cardStyle: MovieCardStyle

    var body: some View {
        NavigationLink(value: movie) {
            MovieCardView(
                movie: movie,
                titleFont: cardStyle.titleFont,
                titleAreaHeight: cardStyle.titleHeight
            )
            .frame(width: cardStyle.width)
        }
        .buttonStyle(.plain)
    }
}
