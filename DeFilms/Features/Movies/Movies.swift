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
    @State private var isSearchPopoverPresented: Bool = false
    @State private var toastItem: ToastItem?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                headerBar

                popularHeader

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.movies.isEmpty {
                    SearchHistoryView(history: viewModel.searchHistory) { selected in
                        viewModel.query = selected
                        Task { await viewModel.search() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if viewModel.filteredMovies.isEmpty {
                    Text("Filtrelere uygun sonuç bulunamadı.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.filteredMovies) { movie in
                                MovieCardView(movie: movie)
                                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .animation(.easeInOut(duration: 0.25), value: viewModel.filteredMovies)
                }
            }
            .task {
                await viewModel.loadPopularMoviesIfNeeded()
            }
            .padding()
            .toast(item: $toastItem)
            .onChange(of: viewModel.errorMessage) { newValue in
                guard let message = newValue, !message.isEmpty else { return }
                toastItem = ToastItem(message: message, style: .error)
                viewModel.clearError()
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 12) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
                .accessibilityLabel("DeFilms Logo")

            Text("DeFilms")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                isSearchPopoverPresented = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundColor(.primary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isSearchPopoverPresented) {
                searchPopover
                    .presentationCompactAdaptation(.none)
            }
        }
    }

    private var popularHeader: some View {
        HStack(spacing: 12) {
            Text("Popular Movies")
                .font(.headline)

            Spacer()

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
    }

    private var searchPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ara")
                .font(.headline)

            TextField("Film ara...", text: $viewModel.query)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Ara") {
                    Task { await viewModel.search() }
                    isSearchPopoverPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 280)
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
}
