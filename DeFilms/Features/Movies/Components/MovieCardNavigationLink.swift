//
//  MovieCardNavigationLink.swift
//  DeFilms
//

import SwiftUI

enum MovieCardStyle {
    case grid
    case rail
    case search

    var titleFont: Font {
        switch self {
        case .grid:
            return .subheadline
        case .rail, .search:
            return .footnote
        }
    }

    var width: CGFloat? {
        switch self {
        case .grid:
            return nil
        case .rail:
            return AppDimension.posterRailWidth
        case .search:
            return nil
        }
    }

    var contentSpacing: CGFloat {
        switch self {
        case .grid:
            return 12
        case .rail, .search:
            return 3
        }
    }

    var metadataSpacing: CGFloat {
        4
    }

    var posterCornerRadius: CGFloat {
        switch self {
        case .grid:
            return 14
        case .rail, .search:
            return 18
        }
    }
}

struct MovieCardNavigationLink: View {
    let movie: Movie
    let cardStyle: MovieCardStyle
    let action: (() -> Void)?

    init(movie: Movie, cardStyle: MovieCardStyle, action: (() -> Void)? = nil) {
        self.movie = movie
        self.cardStyle = cardStyle
        self.action = action
    }

    var body: some View {
        Button(action: {
            action?()
        }) {
            MovieCardView(
                movie: movie,
                titleFont: cardStyle.titleFont,
                contentSpacing: cardStyle.contentSpacing,
                metadataSpacing: cardStyle.metadataSpacing,
                posterCornerRadius: cardStyle.posterCornerRadius
            )
            .frame(width: cardStyle.width)
        }
        .buttonStyle(PressableScaleButtonStyle(pressedScale: 0.978))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Localization.string("movies.accessibility.cardSummary", movie.title, movie.releaseYear))
        .accessibilityHint(Localization.string("movies.accessibility.openDetails"))
        .accessibilityIdentifier("movie.card.\(movie.id)")
    }
}
