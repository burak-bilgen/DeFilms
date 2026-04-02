//
//  Movies.swift
//  DeFilms
//
//  Created by Burak on 2.04.2026.
//

import SwiftUI

struct MoviesView: View {
    @StateObject private var viewModel = MovieSearchViewModel(networkService: NetworkManager.shared)

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    TextField("Film ara...", text: $viewModel.query)
                        .textFieldStyle(.roundedBorder)

                    Button("Ara") {
                        Task { await viewModel.search() }
                    }
                    .buttonStyle(.borderedProminent)
                }

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if viewModel.movies.isEmpty {
                    SearchHistoryView(history: viewModel.searchHistory) { selected in
                        viewModel.query = selected
                        Task { await viewModel.search() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.movies) { movie in
                                MovieCardView(movie: movie)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding()
            .navigationTitle("Filmler")
            .alert("Hata", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("Tamam") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
