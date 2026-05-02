
import SwiftUI

struct MoviesView: View {
    @EnvironmentObject private var coordinator: MovieCoordinator
    @ObservedObject var viewModel: MovieSearchViewModel
    let openLists: () -> Void
    @State private var isFilterSheetPresented = false
    @State private var isSearchHistoryClearConfirmationPresented = false
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var movieStatusStore: UserMovieStatusStore

    private let searchColumns = [
        GridItem(.adaptive(minimum: AppDimension.posterRailWidth, maximum: AppDimension.posterRailWidth), spacing: AppSpacing.xxxl, alignment: .top)
    ]

    init(viewModel: MovieSearchViewModel, openLists: @escaping () -> Void) {
        self.viewModel = viewModel
        self.openLists = openLists
    }

    private var hasActiveFilters: Bool {
        let releaseYearText = viewModel.filterYear.trimmingCharacters(in: .whitespacesAndNewlines)
        return !releaseYearText.isEmpty || viewModel.minRating > 0 || viewModel.selectedGenreID != nil
    }

    private var hasActiveSorting: Bool {
        viewModel.sortOption != .relevance
    }

    private var shouldShowResetControls: Bool {
        hasActiveFilters || hasActiveSorting
    }

    private var searchSummaryBadgeText: String {
        hasActiveFilters || hasActiveSorting
            ? Localization.string("movies.filter.title")
            : Localization.string("movies.sort.relevance")
    }

    private var searchSummaryBadgeSystemImage: String {
        hasActiveFilters || hasActiveSorting ? "slider.horizontal.3" : "sparkles"
    }

    var body: some View {
        let displayedSearchMovies = viewModel.filteredSearchResults
        let searchResultCount = displayedSearchMovies.count
        let watchlistMovies = movieStatusStore.watchlistMovies
        let shouldShowFilterControl = hasActiveFilters || searchResultCount > 0
        let shouldShowSortControl = hasActiveSorting || searchResultCount > 1
        let shouldShowSearchControls = !viewModel.shouldShowBrowseContent && viewModel.screenState != .emptyResults
        let shouldShowSearchSummary = !viewModel.shouldShowBrowseContent &&
            (searchResultCount > 0 || hasActiveFilters || hasActiveSorting)

        VStack(spacing: 0) {
            MoviesHeaderBar(openLists: openLists)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if shouldShowSearchSummary {
                        MoviesSearchSummaryCard(
                            title: Localization.string("movies.results.count", searchResultCount),
                            subtitle: summarySubtitle,
                            badgeText: searchSummaryBadgeText,
                            badgeSystemImage: searchSummaryBadgeSystemImage
                        )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    searchBar
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.shouldShowBrowseContent)

                    if viewModel.shouldShowBrowseContent && !viewModel.searchHistory.isEmpty {
                        SearchHistoryView(
                            history: viewModel.searchHistory,
                            onSelect: runRecentSearch,
                            onRequestClearConfirmation: { isSearchHistoryClearConfirmationPresented = true }
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if viewModel.shouldShowBrowseContent {
                        if !watchlistMovies.isEmpty {
                            MovieHorizontalSection(
                                title: Localization.string("movies.section.watchlist"),
                                movies: Array(watchlistMovies.prefix(12))
                            )
                        }
                    }

                    if shouldShowSearchControls {
                        MoviesSearchControlsRow(
                            shouldShowFilterControl: shouldShowFilterControl,
                            shouldShowSortControl: shouldShowSortControl,
                            shouldShowResetControls: shouldShowResetControls,
                            selectedSortOption: viewModel.sortOption,
                            openFilters: openFilters,
                            selectSortOption: { option in
                                viewModel.sortOption = option
                            },
                            resetSort: {
                                viewModel.sortOption = .relevance
                            },
                            resetFiltersAndSort: viewModel.resetFiltersAndSort
                        )
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    if viewModel.shouldShowBrowseContent {
                        MoviesBrowseSectionView(
                            screenState: viewModel.screenState,
                            browseSections: viewModel.browseSections,
                            isSectionLoadingMore: viewModel.isLoadingMoreBrowseSection,
                            onLoadMoreSection: loadNextBrowseSectionPage,
                            onReloadBrowseContent: refreshBrowseContent,
                            localizedBrowseTitle: localizedBrowseTitle
                        )
                            .transition(.opacity)
                    } else {
                        MoviesSearchResultsView(
                            screenState: viewModel.screenState,
                            query: viewModel.query,
                            displayedMovies: displayedSearchMovies,
                            searchColumns: searchColumns,
                            isLoadingNextSearchPage: viewModel.isLoadingNextSearchPage,
                            onOpenMovie: showMovieDetail,
                            onLoadNextPage: loadNextSearchPage,
                            onResetFiltersAndSort: viewModel.resetFiltersAndSort,
                            onPerformSearch: submitSearch
                        )
                            .transition(.opacity)
                    }
                }
                .padding(.top, viewModel.shouldShowBrowseContent ? AppSpacing.xs : 0)
                .padding(.bottom, AppSpacing.xxl)
                .animation(.easeInOut(duration: 0.22), value: viewModel.shouldShowBrowseContent)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.top, 0)
        .background(AppPalette.screenBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
        }
        .task {
            await viewModel.loadBrowseContentIfNeeded(for: preferences.selectedLanguage)
        }
        .onChange(of: preferences.selectedLanguage) { newLanguage in
            Task {
                await viewModel.reloadForLanguageChange(to: newLanguage)
            }
        }
        .onChange(of: viewModel.query) { newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.clearSearch()
            }
        }
        .sheet(isPresented: $isFilterSheetPresented) {
            NavigationStack {
                MovieFilterSheet(viewModel: viewModel)
            }
            .presentationDetents([.medium, .large])
        }
        .alert(
            Localization.string("movies.searchHistory.clear.confirmTitle"),
            isPresented: $isSearchHistoryClearConfirmationPresented
        ) {
            Button(Localization.string("movies.searchHistory.clear.confirmAction"), role: .destructive) {
                Task {
                    await viewModel.clearSearchHistory()
                }
            }
            Button(Localization.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(Localization.string("movies.searchHistory.clear.confirmMessage"))
        }
    }

    private var searchBar: some View {
        MoviesSearchBar(
            text: $viewModel.query,
            isFocused: $isSearchFocused,
            onSubmit: submitSearch,
            onClear: viewModel.clearSearch
        )
    }

    private func submitSearch() {
        Task {
            isSearchFocused = false
            AppLogger.log("Search submitted", category: .search)
            await viewModel.search(force: true)
        }
    }

    private func refreshBrowseContent() {
        Task {
            await viewModel.refreshBrowseContent()
        }
    }

    private func openFilters() {
        Task {
            await viewModel.loadGenresIfNeeded()
            isFilterSheetPresented = true
        }
    }

    private func runRecentSearch(_ recentQuery: String) {
        Task {
            await viewModel.search(usingRecentQuery: recentQuery)
        }
    }

    private func showMovieDetail(_ movie: Movie) {
        coordinator.show(.detail(movie))
    }

    private func loadNextSearchPage(after movie: Movie, in displayedMovies: [Movie]) {
        Task {
            await viewModel.loadNextSearchPageIfNeeded(after: movie, in: displayedMovies)
        }
    }

    private func loadNextBrowseSectionPage(after movie: Movie, in section: MovieBrowseSection) {
        Task {
            await viewModel.loadNextBrowseSectionPageIfNeeded(after: movie, in: section)
        }
    }

    private func localizedBrowseTitle(_ sectionID: String) -> String {
        switch sectionID {
        case "trending-today":
            return Localization.string("movies.section.trendingToday")
        case "trending-week":
            return Localization.string("movies.section.trendingWeek")
        case "popular":
            return Localization.string("movies.section.popular")
        case "upcoming":
            return Localization.string("movies.section.upcoming")
        case "now-playing":
            return Localization.string("movies.section.nowPlaying")
        case "top-rated":
            return Localization.string("movies.section.topRated")
        case "critically-acclaimed":
            return Localization.string("movies.section.criticallyAcclaimed")
        case "hidden-gems":
            return Localization.string("movies.section.hiddenGems")
        case "action-adventure":
            return Localization.string("movies.section.actionAdventure")
        case "family-night":
            return Localization.string("movies.section.familyNight")
        default:
            return sectionID
        }
    }
    private var summarySubtitle: String {
        if hasActiveFilters || hasActiveSorting {
            return Localization.string("movies.message.filteredEmpty.body")
        }

        return viewModel.query
    }
}
