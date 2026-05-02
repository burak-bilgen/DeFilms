
import SwiftUI

struct MoviesBrowseSectionView: View {
    let screenState: MoviesScreenState
    let browseSections: [MovieBrowseSection]
    let isSectionLoadingMore: (String) -> Bool
    let onLoadMoreSection: (Movie, MovieBrowseSection) -> Void
    let onReloadBrowseContent: () -> Void
    let localizedBrowseTitle: (String) -> String

    var body: some View {
        switch screenState {
        case .loadingBrowse:
            browseLoadingState
        case let .error(message) where browseSections.isEmpty:
            browseErrorState(message: message)
        default:
            ForEach(browseSections) { section in
                MovieHorizontalSection(
                    title: localizedBrowseTitle(section.id),
                    movies: section.movies,
                    isLoadingMore: isSectionLoadingMore(section.id),
                    onLoadMore: { movie, _ in
                        onLoadMoreSection(movie, section)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var browseLoadingState: some View {
        ForEach(0..<4, id: \.self) { _ in
            MovieSectionSkeletonView()
                .padding(.horizontal, 16)
        }
    }

    private func browseErrorState(message: String) -> some View {
        MoviesMessageView(
            title: Localization.string("movies.message.contentUnavailable.title"),
            message: message,
            buttonTitle: Localization.string("common.tryAgain"),
            action: onReloadBrowseContent
        )
        .padding(.horizontal, 16)
    }
}

struct MoviesSearchResultsView: View {
    let screenState: MoviesScreenState
    let query: String
    let displayedMovies: [Movie]
    let searchColumns: [GridItem]
    let isLoadingNextSearchPage: Bool
    let onOpenMovie: (Movie) -> Void
    let onLoadNextPage: (Movie, [Movie]) -> Void
    let onResetFiltersAndSort: () -> Void
    let onPerformSearch: () -> Void

    var body: some View {
        switch screenState {
        case .searching:
            MovieGridSkeletonView(columns: searchColumns)
                .padding(.horizontal, 16)
                .padding(.top, 6)
        case .loadedResults:
            if displayedMovies.isEmpty {
                searchEmptyStateContainer(
                    title: Localization.string("movies.message.filteredEmpty.title"),
                    message: Localization.string("movies.message.filteredEmpty.body"),
                    buttonTitle: Localization.string("movies.filter.reset"),
                    action: onResetFiltersAndSort
                )
            } else {
                VStack(spacing: AppSpacing.lg) {
                    LazyVGrid(columns: searchColumns, alignment: .center, spacing: AppSpacing.xl) {
                        ForEach(displayedMovies) { movie in
                            MovieCardNavigationLink(movie: movie, cardStyle: .rail) {
                                onOpenMovie(movie)
                            }
                            .onAppear {
                                onLoadNextPage(movie, displayedMovies)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .animation(.easeInOut(duration: 0.22), value: displayedMovies.map(\.id))

                    paginationFooter
                }
            }
        case .emptyResults:
            searchEmptyStateContainer(
                title: Localization.string("movies.message.noResults.title"),
                message: Localization.string("movies.message.noResults.body", query),
                buttonTitle: nil,
                action: nil,
                animationName: "404"
            )
        case let .error(message):
            MoviesMessageView(
                title: Localization.string("movies.message.searchFailed.title"),
                message: message,
                buttonTitle: Localization.string("movies.action.searchAgain"),
                action: onPerformSearch
            )
            .padding(.horizontal, 16)
        case .browse, .loadingBrowse:
            EmptyView()
        }
    }

    @ViewBuilder
    private func searchEmptyStateContainer(
        title: String,
        message: String,
        buttonTitle: String?,
        action: (() -> Void)?,
        animationName: String? = nil
    ) -> some View {
        VStack {
            MovieSearchEmptyStateView(
                title: title,
                message: message,
                buttonTitle: buttonTitle,
                action: action,
                animationName: animationName
            )
            .frame(maxWidth: 380)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: animationName == nil ? 320 : 240)
        .padding(.top, animationName == nil ? AppSpacing.lg : 0)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var paginationFooter: some View {
        ZStack {
            if isLoadingNextSearchPage {
                ProgressView()
                    .transition(.opacity)
            }
        }
        .frame(height: 28)
        .animation(.easeInOut(duration: 0.2), value: isLoadingNextSearchPage)
    }
}
