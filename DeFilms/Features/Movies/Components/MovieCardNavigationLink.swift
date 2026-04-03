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
            return 28
        }
    }

    var width: CGFloat? {
        switch self {
        case .grid:
            return nil
        case .rail:
            return 146
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .grid:
            return 12
        case .rail:
            return 3
        }
    }

    var metadataSpacing: CGFloat {
        switch self {
        case .grid:
            return 2
        case .rail:
            return 0
        }
    }

    var posterCornerRadius: CGFloat {
        switch self {
        case .grid:
            return 14
        case .rail:
            return 18
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
                titleAreaHeight: cardStyle.titleHeight,
                contentSpacing: cardStyle.contentSpacing,
                metadataSpacing: cardStyle.metadataSpacing,
                posterCornerRadius: cardStyle.posterCornerRadius
            )
            .frame(width: cardStyle.width)
        }
        .buttonStyle(.plain)
    }
}
