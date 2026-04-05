//
//  Movies.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MoviesView: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator<MovieRoute>
    @ObservedObject var viewModel: MovieSearchViewModel
    let openFavorites: () -> Void
    @State private var isFilterSheetPresented = false
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var toastCenter: ToastCenter

    private let searchColumns = [
        GridItem(.adaptive(minimum: AppDimension.posterRailWidth, maximum: AppDimension.posterRailWidth), spacing: AppSpacing.xxxl, alignment: .top)
    ]

    init(viewModel: MovieSearchViewModel, openFavorites: @escaping () -> Void) {
        self.viewModel = viewModel
        self.openFavorites = openFavorites
    }

    private var hasActiveFilters: Bool {
        let trimmedYear = viewModel.filterYear.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedYear.isEmpty || viewModel.minRating > 0 || viewModel.selectedGenreID != nil
    }

    private var hasActiveSorting: Bool {
        viewModel.sortOption != .relevance
    }

    private var searchResultCount: Int {
        viewModel.filteredSearchResults.count
    }

    private var shouldShowFilterControl: Bool {
        hasActiveFilters || searchResultCount > 0
    }

    private var shouldShowSortControl: Bool {
        hasActiveSorting || searchResultCount > 1
    }

    private var shouldShowResetControls: Bool {
        hasActiveFilters || hasActiveSorting
    }

    private var shouldShowSearchSummary: Bool {
        !viewModel.shouldShowBrowseContent && (searchResultCount > 0 || hasActiveFilters || hasActiveSorting)
    }

    private var searchSummaryTitle: String {
        Localization.string("movies.results.count", searchResultCount)
    }

    private var searchSummaryBadgeText: String {
        hasActiveFilters || hasActiveSorting
            ? Localization.string("movies.filter.title")
            : Localization.string("movies.sort.relevance")
    }

    private var searchSummaryBadgeSystemImage: String {
        hasActiveFilters || hasActiveSorting ? "slider.horizontal.3" : "sparkles"
    }

    private var displayedSearchMovies: [Movie] {
        viewModel.filteredSearchResults
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            MoviesHeaderBar(openFavorites: openFavorites)
                .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if shouldShowSearchSummary {
                        MoviesSearchSummaryCard(
                            title: searchSummaryTitle,
                            subtitle: summarySubtitle,
                            badgeText: searchSummaryBadgeText,
                            badgeSystemImage: searchSummaryBadgeSystemImage
                        )
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    searchSection
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.shouldShowBrowseContent)

                    if !viewModel.shouldShowBrowseContent {
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
                        MoviesBrowseContentSection(
                            searchHistory: viewModel.searchHistory,
                            screenState: viewModel.screenState,
                            browseSections: viewModel.browseSections,
                            onSelectRecentSearch: selectRecentSearch,
                            onClearSearchHistory: viewModel.clearSearchHistory,
                            onReloadBrowseContent: reloadBrowseContent,
                            localizedBrowseTitle: localizedBrowseTitle
                        )
                            .transition(.opacity)
                    } else {
                        MoviesSearchContentSection(
                            screenState: viewModel.screenState,
                            query: viewModel.query,
                            displayedMovies: displayedSearchMovies,
                            searchColumns: searchColumns,
                            isLoadingNextSearchPage: viewModel.isLoadingNextSearchPage,
                            onOpenMovie: openMovieDetail,
                            onLoadNextPage: loadNextSearchPage,
                            onResetFiltersAndSort: viewModel.resetFiltersAndSort,
                            onPerformSearch: performSearch
                        )
                            .transition(.opacity)
                    }
                }
                .padding(.top, viewModel.shouldShowBrowseContent ? AppSpacing.lg : 0)
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
        .onChange(of: viewModel.toastItem?.id) { _ in
            relayToast(from: viewModel.toastItem)
        }
    }

    private var searchSection: some View {
        MoviesSearchBar(
            text: $viewModel.query,
            isFocused: $isSearchFocused,
            onSubmit: performSearch,
            onClear: viewModel.clearSearch
        )
    }

    private func performSearch() {
        Task {
            isSearchFocused = false
            AppLogger.log("Search submitted from UI", category: .search)
            await viewModel.search(force: true)
        }
    }

    private func reloadBrowseContent() {
        Task {
            await viewModel.reloadBrowseContent()
        }
    }

    private func openFilters() {
        Task {
            await viewModel.loadGenresIfNeeded()
            isFilterSheetPresented = true
        }
    }

    private func selectRecentSearch(_ selected: String) {
        Task {
            await viewModel.selectRecentSearch(selected)
        }
    }

    private func openMovieDetail(_ movie: Movie) {
        coordinator.push(.detail(movie))
    }

    private func loadNextSearchPage(for movie: Movie, displayedMovies: [Movie]) {
        Task {
            await viewModel.loadNextSearchPageIfNeeded(currentMovie: movie, displayedMovies: displayedMovies)
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
        default:
            return sectionID
        }
    }

    private func relayToast(from item: ToastItem?) {
        guard let item else { return }
        toastCenter.show(message: item.message, style: item.style)
        viewModel.clearToast()
    }

    private var summarySubtitle: String {
        if hasActiveFilters || hasActiveSorting {
            return Localization.string("movies.message.filteredEmpty.body")
        }

        return viewModel.query
    }
}
