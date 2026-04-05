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

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            headerBar
                .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if shouldShowSearchSummary {
                        searchSummaryCard
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    searchSection
                        .padding(.horizontal)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.shouldShowBrowseContent)

                    if !viewModel.shouldShowBrowseContent {
                        searchControlsRow
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    if viewModel.shouldShowBrowseContent {
                        browseContent
                            .transition(.opacity)
                    } else {
                        searchContent
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

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 72)
                    .accessibilityLabel(Localization.string("app.logo"))
            }

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

    private var searchSummaryCard: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(
                    viewModel.shouldShowBrowseContent
                    ? Localization.string("movies.search.placeholder")
                    : Localization.string("movies.results.count", searchResultCount)
                )
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

                Text(summarySubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: AppSpacing.md)

            summaryBadge(
                text: hasActiveFilters || hasActiveSorting
                ? Localization.string("movies.filter.title")
                : Localization.string("movies.sort.relevance"),
                systemImage: hasActiveFilters || hasActiveSorting
                ? "slider.horizontal.3"
                : "sparkles"
            )
        }
        .padding(AppSpacing.md)
        .background(
            LinearGradient(
                colors: [
                    AppPalette.cardBackground,
                    AppPalette.cardAccentBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous))
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
                        viewModel.sortOption = .relevance
                    }
                } label: {
                    SearchControlBubble(
                        title: Localization.string("movies.sort.title"),
                        systemImage: "arrow.up.arrow.down.circle"
                    )
                }
            }

            if shouldShowResetControls {
                Button(action: viewModel.resetFiltersAndSort) {
                    SearchControlIconBubble(systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Localization.string("movies.filter.reset"))
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.92)))
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppPalette.cardBackground.opacity(0.8))
        .overlay(
            Capsule()
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var browseContent: some View {
        if !viewModel.searchHistory.isEmpty {
            SearchHistoryView(
                history: viewModel.searchHistory,
                onSelect: { selected in
                    Task {
                        await viewModel.selectRecentSearch(selected)
                    }
                },
                onClear: viewModel.clearSearchHistory
            )
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
                    .animation(.easeInOut(duration: 0.22), value: displayedMovies.map(\.id))

                    paginationFooter
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

    @ViewBuilder
    private var paginationFooter: some View {
        ZStack {
            if viewModel.isLoadingNextSearchPage {
                ProgressView()
                    .transition(.opacity)
            }
        }
        .frame(height: 28)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoadingNextSearchPage)
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

    private func summaryBadge(text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color.primary.opacity(0.06))
            .clipShape(Capsule())
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

private struct SearchControlIconBubble: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: AppDimension.controlHeight, height: AppDimension.controlHeight)
            .background(
                Circle()
                    .fill(AppPalette.cardBackground)
            )
            .overlay(
                Circle()
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
