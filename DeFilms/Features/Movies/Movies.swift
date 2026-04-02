//
//  Movies.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MoviesView: View {
    @StateObject private var viewModel = MovieSearchViewModel(networkService: NetworkManager.shared)
    @State private var isFilterPopoverPresented: Bool = false
    @State private var isSortPopoverPresented: Bool = false
    @State private var toastItem: ToastItem?
    @FocusState private var isSearchFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private let searchColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    searchSection

                    if showCarousel {
                        Text("Popular Movies")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.25), value: isSearching)
                        
                        popularCarousel
                            .transition(.opacity)
                            .padding(.horizontal, -16)
                            .animation(.easeInOut(duration: 0.25), value: showCarousel)
                    }

                    if isSearching {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if viewModel.filteredMovies.isEmpty {
                            Text("Arama sonucu bulunamadı.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            searchResultsGrid
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    } else if viewModel.popularMovies.isEmpty {
                        SearchHistoryView(history: viewModel.searchHistory) { selected in
                            viewModel.query = selected
                            Task { await viewModel.search() }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .task {
                await viewModel.loadPopularMoviesIfNeeded()
            }
            .safeAreaInset(edge: .top) {
                headerBar
                    .padding(.horizontal)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isSearchFocused = false
            }
            .scrollDismissesKeyboard(.interactively)
            .toast(item: $toastItem)
            .onChange(of: viewModel.errorMessage) { newValue in
                guard let message = newValue, !message.isEmpty else { return }
                toastItem = ToastItem(message: message, style: .error)
                viewModel.clearError()
            }
            .onChange(of: viewModel.query) { newValue in
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    viewModel.clearSearchResults()
                } else {
                    viewModel.searchDebounced()
                }
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 75)
                .padding(.leading, -5)
                .accessibilityLabel("DeFilms Logo")

            Spacer()
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            searchField
        }
    }

    private var popularCarousel: some View {
        PosterCarousel(movies: viewModel.popularMovies)
            .frame(height: 480)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Film ara...", text: $viewModel.query)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search() }
                }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                    viewModel.clearSearchResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if showFilterSortButtons {
                HStack(spacing: 10) {
                    Button {
                        isFilterPopoverPresented = true
                        Task { await viewModel.loadGenresIfNeeded() }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isFilterPopoverPresented) {
                        filterPopover
                            .presentationCompactAdaptation(.none)
                    }

                    Button {
                        isSortPopoverPresented = true
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $isSortPopoverPresented) {
                        sortPopover
                            .presentationCompactAdaptation(.none)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.12))
        )
    }

    private var searchResultsGrid: some View {
        LazyVGrid(columns: searchColumns, spacing: 16) {
            ForEach(viewModel.filteredMovies) { movie in
                MovieCardView(movie: movie)
            }
        }
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.25), value: viewModel.filteredMovies)
    }


    private var filterPopover: some View {
        let genres = viewModel.genres

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filtreler")
                    .font(.headline)
                Spacer()
                Button("Temizle") { viewModel.resetFilters() }
                    .font(.caption)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Yıl")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Örn: 2024", text: $viewModel.filterYear)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.filterYear) { newValue in
                        let digits = newValue.filter { $0.isNumber }
                        viewModel.filterYear = String(digits.prefix(4))
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Puan")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text("\(Int(viewModel.minRating))+")
                    Slider(value: $viewModel.minRating, in: 0...10, step: 1)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Genre")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Genre", selection: selectedGenreBinding) {
                    Text("Tümü").tag(0)
                    ForEach(genres, id: \.id) { genre in
                        Text(genre.name).tag(genre.id)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Uygula") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.applyFilters()
                    }
                    toastItem = ToastItem(message: "Filtreler uygulandı", style: .success)
                    isFilterPopoverPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 300)
    }

    private var selectedGenreBinding: Binding<Int> {
        Binding(
            get: { viewModel.selectedGenreID ?? 0 },
            set: { viewModel.selectedGenreID = $0 == 0 ? nil : $0 }
        )
    }

    private var sortPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sıralama")
                    .font(.headline)
                Spacer()
                Button("Temizle") { viewModel.resetSort() }
                    .font(.caption)
            }

            ForEach(MovieSortOption.allCases) { option in
                HStack {
                    Text(option.rawValue)
                    Spacer()
                    if viewModel.sortOption == option {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.sortOption = option
                }
            }

            HStack {
                Spacer()
                Button("Uygula") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.applySort()
                    }
                    toastItem = ToastItem(message: "Sıralama uygulandı", style: .success)
                    isSortPopoverPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 260)
    }

    private var isSearching: Bool {
        !viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var showFilterSortButtons: Bool {
        isSearching && viewModel.filteredMovies.count > 1
    }

    private var showCarousel: Bool {
        !isSearching && !isSearchFocused
    }
}

private struct PosterCarousel: View {
    let movies: [Movie]

    @State private var internalIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let containerWidth = proxy.size.width
            let cardWidth = min(containerWidth * 0.72, 340)
            let cardHeight = cardWidth * 1.5
            let spacing: CGFloat = 16
            let totalWidth = cardWidth + spacing
            let count = movies.count

            HStack(spacing: spacing) {
                ForEach(Array(movies.enumerated()), id: \.offset) { index, movie in
                    MovieCarouselCard(
                        movie: movie,
                        isActive: index == internalIndex,
                        width: cardWidth,
                        height: cardHeight
                    )
                    .scaleEffect(scale(for: index, totalWidth: totalWidth, containerWidth: containerWidth))
                }
            }
            .padding(.horizontal, (containerWidth - cardWidth) / 2)
            .offset(x: -CGFloat(internalIndex) * totalWidth + dragOffset)
            .animation(.easeOut(duration: 0.35), value: internalIndex)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        guard count > 0 else { return }
                        let threshold = totalWidth * 0.35
                        var target = internalIndex
                        if dragOffset < -threshold {
                            target = internalIndex + 1
                        } else if dragOffset > threshold {
                            target = internalIndex - 1
                        }
                        let clamped = min(max(target, 0), max(count - 1, 0))

                        withAnimation(.easeOut(duration: 0.35)) {
                            internalIndex = clamped
                            dragOffset = 0
                        }
                    }
            )
            .padding(.vertical, 16)
        }
    }

    private func scale(for index: Int, totalWidth: CGFloat, containerWidth: CGFloat) -> CGFloat {
        let centerOffset = (CGFloat(index) - CGFloat(internalIndex)) * totalWidth + dragOffset
        let normalized = min(abs(centerOffset) / containerWidth, 1)
        return 1 - (normalized * 0.18)
    }
}

private struct MovieCarouselCard: View {
    let movie: Movie
    let isActive: Bool
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        PosterImageView(
            url: movie.posterURL,
            cornerRadius: 18,
            placeholderSystemImage: "photo"
        )
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(isActive ? 0.28 : 0), radius: isActive ? 12 : 0, y: isActive ? 10 : 0)
    }
}

private struct MovieSearchRow: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: 12) {
            PosterImageView(
                url: movie.posterURL,
                cornerRadius: 8,
                placeholderSystemImage: "photo"
            )
            .frame(width: 56, height: 84)

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Text(movie.releaseYear)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

