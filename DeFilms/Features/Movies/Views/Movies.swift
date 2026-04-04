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
        viewModel.sortOption != .titleAsc
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

    var body: some View {
        VStack(spacing: 2) {
            headerBar
                .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    searchSection
                        .padding(.horizontal)
                        
                    if !viewModel.shouldShowBrowseContent {
                        searchControlsRow
                            .padding(.horizontal)
                    }
                    
                    if viewModel.shouldShowBrowseContent {
                        browseContent
                    } else {
                        searchContent
                    }
                }
                .padding(.top, viewModel.shouldShowBrowseContent ? AppSpacing.xxl : 0)
                .padding(.bottom, AppSpacing.xxl)
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
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 70)
                .accessibilityLabel(Localization.string("app.logo"))

            Spacer()

            Button(action: openFavorites) {
                Image(systemName: "rectangle.stack.badge.play")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 42, height: 42)
                    .background(AppPalette.cardBackground)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(AppPalette.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.string("favorites.navigate"))
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

    private var searchControlsRow: some View {
        HStack(spacing: 10) {
            if shouldShowFilterControl {
                Button {
                    Task {
                        await viewModel.loadGenresIfNeeded()
                        isFilterSheetPresented = true
                    }
                } label: {
                    SearchControlBubble(
                        title: Localization.string("movies.filter.title"),
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
                .buttonStyle(.plain)
            }

            if shouldShowSortControl {
                Menu {
                    ForEach(MovieSortOption.allCases) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            if viewModel.sortOption == option {
                                Label(option.title, systemImage: "checkmark")
                            } else {
                                Text(option.title)
                            }
                        }
                    }

                    Divider()

                    Button(Localization.string("movies.sort.reset")) {
                        viewModel.sortOption = .titleAsc
                    }
                } label: {
                    SearchControlBubble(
                        title: Localization.string("movies.sort.title"),
                        systemImage: "arrow.up.arrow.down.circle"
                    )
                }
            }

            Spacer()

            Text(Localization.string("movies.results.count", searchResultCount))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        if !viewModel.searchHistory.isEmpty {
            SearchHistoryView(history: viewModel.searchHistory) { selected in
                Task {
                    await viewModel.selectRecentSearch(selected)
                }
            }
            .padding(.bottom, 10)
        }

        switch viewModel.screenState {
        case .loadingBrowse:
            ForEach(0..<4, id: \.self) { _ in
                MovieSectionSkeletonView()
                    .padding(.horizontal, 16)
            }
        case let .error(message) where viewModel.browseSections.isEmpty:
            MoviesMessageView(
                title: Localization.string("movies.message.contentUnavailable.title"),
                message: message,
                buttonTitle: Localization.string("common.tryAgain"),
                action: reloadBrowseContent
            )
            .padding(.horizontal, 16)
        default:
            ForEach(viewModel.browseSections) { section in
                MovieHorizontalSection(
                    title: localizedBrowseTitle(for: section.id),
                    movies: section.movies
                )
            }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        let displayedMovies = viewModel.filteredSearchResults

        switch viewModel.screenState {
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
                    action: viewModel.resetFiltersAndSort
                )
            } else {
                VStack(spacing: AppSpacing.lg) {
                    LazyVGrid(columns: searchColumns, alignment: .center, spacing: AppSpacing.xl) {
                        ForEach(displayedMovies) { movie in
                            MovieCardNavigationLink(movie: movie, cardStyle: .rail) {
                                coordinator.push(.detail(movie))
                            }
                            .onAppear {
                                Task {
                                    await viewModel.loadNextSearchPageIfNeeded(currentMovie: movie, displayedMovies: displayedMovies)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)

                    if viewModel.isLoadingNextSearchPage {
                        ProgressView()
                            .padding(.vertical, AppSpacing.xs)
                    }
                }
            }
        case .emptyResults:
            searchEmptyStateContainer(
                title: Localization.string("movies.message.noResults.title"),
                message: Localization.string("movies.message.noResults.body", viewModel.query),
                buttonTitle: nil,
                action: nil,
                animationName: "404"
            )
        case let .error(message):
            MoviesMessageView(
                title: Localization.string("movies.message.searchFailed.title"),
                message: message,
                buttonTitle: Localization.string("movies.action.searchAgain"),
                action: performSearch
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
            Spacer(minLength: AppSpacing.xxl)

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
        .frame(maxWidth: .infinity, minHeight: AppDimension.emptyStateMinHeight)
        .padding(.horizontal, 16)
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

    private func localizedBrowseTitle(for sectionID: String) -> String {
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
}

private struct SearchControlBubble: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .frame(width: 18, height: 18)
                .padding(8)
                .foregroundStyle(.primary)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.06))
                )

            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.primary)
        .frame(height: AppDimension.controlHeight)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(AppPalette.cardBackground)
        )
        .overlay(
            Capsule()
                .stroke(AppPalette.border, lineWidth: 1)
        )
    }
}

private struct MovieSearchEmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?
    let animationName: String?

    var body: some View {
        MoviesMessageView(
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action,
            animationName: animationName
        )
        .frame(maxWidth: .infinity)
    }
}
