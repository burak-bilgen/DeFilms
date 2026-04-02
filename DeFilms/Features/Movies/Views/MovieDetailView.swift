//
//  MovieDetailView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailView: View {
    let movie: Movie

    @StateObject private var viewModel: MovieDetailViewModel
    @EnvironmentObject private var preferences: AppPreferences

    init(movie: Movie) {
        self.movie = movie
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(movie: movie, networkService: NetworkManager.shared))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                MovieDetailSkeletonView()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        MovieDetailHeroHeaderView(movie: movie, viewModel: viewModel)

                        MovieDetailContentCardView(movie: movie, viewModel: viewModel)
                            .padding(.top, -42)
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 28)
                }
                .background(Color(.systemGroupedBackground))
                .ignoresSafeArea(edges: .top)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: preferences.selectedLanguage.rawValue) { _ in
            Task {
                await viewModel.reloadForLanguageChange()
            }
        }
    }
}
