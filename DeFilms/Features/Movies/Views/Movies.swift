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
        GridItem(.flexible(), spacing: 24),
        GridItem(.flexible(), spacing: 24)
    ]

    init(viewModel: MovieSearchViewModel, openFavorites: @escaping () -> Void) {
        self.viewModel = viewModel
        self.openFavorites = openFavorites
    }

    var body: some View {
        VStack(spacing: 2) {
            headerBar
                .padding(.horizontal)

            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
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
                .padding(.top, viewModel.shouldShowBrowseContent ? 25 : 0)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.top, 0)
        .background(Color(.systemGroupedBackground))
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
        HStack {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 70)
                .padding(.leading, -4)
                .padding(.top, -12)
                .accessibilityLabel(Localization.string("app.logo"))

            Spacer()
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
            Button {
                Task {
                    await viewModel.loadGenresIfNeeded()
                    isFilterSheetPresented = true
                }
            } label: {
                Label(Localization.string("movies.filter.title"), systemImage: "line.3.horizontal.decrease.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(height: 38)
                    .padding(.horizontal, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

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
                Label(Localization.string("movies.sort.title"), systemImage: "arrow.up.arrow.down.circle")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(height: 38)
                    .padding(.horizontal, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(Localization.string("movies.results.count", viewModel.filteredSearchResults.count))
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
            .padding(.bottom, -8)
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
                MovieSearchEmptyStateView(
                    title: Localization.string("movies.message.filteredEmpty.title"),
                    message: Localization.string("movies.message.filteredEmpty.body"),
                    buttonTitle: Localization.string("movies.filter.reset"),
                    action: viewModel.resetFiltersAndSort
                )
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 420, alignment: .center)
            } else {
                LazyVGrid(columns: searchColumns, spacing: 24) {
                    ForEach(displayedMovies) { movie in
                        MovieCardNavigationLink(movie: movie, cardStyle: .search) {
                            coordinator.push(.detail(movie))
                        }
                        .onAppear {
                            Task {
                                await viewModel.loadNextSearchPageIfNeeded(currentMovie: movie, displayedMovies: displayedMovies)
                            }
                        }
                    }

                    if viewModel.isLoadingNextSearchPage {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .gridCellColumns(searchColumns.count)
                    }
                }
                .padding(.horizontal, 16)
            }
        case .emptyResults:
            MovieSearchEmptyStateView(
                title: Localization.string("movies.message.noResults.title"),
                message: Localization.string("movies.message.noResults.body", viewModel.query),
                buttonTitle: nil,
                action: nil
            )
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 420, alignment: .center)
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
private struct MovieSearchEmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String?
    let action: (() -> Void)?

    var body: some View {
        MoviesMessageView(
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action
        )
    }
}

