//
//  MovieDetailView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailView: View {
    private let heroHeight: CGFloat = 420

    let movie: Movie

    @StateObject private var viewModel: MovieDetailViewModel
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollOffset: CGFloat = 0

    init(movie: Movie) {
        self.movie = movie
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(movie: movie, networkService: NetworkManager.shared))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.detail == nil {
                MovieDetailSkeletonView()
            } else {
                ZStack(alignment: .top) {
                    MovieDetailBackdropView(
                        imageURL: viewModel.heroPosterURL,
                        height: heroHeight,
                        scrollOffset: scrollOffset
                    )

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            scrollOffsetReader

                            MovieDetailHeroHeaderView(
                                movie: movie,
                                viewModel: viewModel,
                                heroHeight: heroHeight,
                                scrollOffset: scrollOffset
                            )

                            MovieDetailContentCardView(viewModel: viewModel)
                                .padding(.horizontal, 18)
                        }
                        .padding(.bottom, 30)
                    }
                    .coordinateSpace(name: "movieDetailScroll")
                }
                .background(
                    LinearGradient(
                        colors: [
                            topBackgroundColor,
                            middleBackgroundColor,
                            bottomBackgroundColor
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .ignoresSafeArea(edges: .top)
                .onPreferenceChange(MovieDetailScrollOffsetKey.self) { scrollOffset = $0 }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: preferences.selectedLanguage.rawValue) { _ in
            Task {
                await viewModel.reloadForLanguageChange()
            }
        }
        .sheet(isPresented: $viewModel.isTrailerPresented) {
            if let trailerURL = viewModel.trailerURL {
                MovieTrailerPlayerSheet(url: trailerURL)
                    .ignoresSafeArea()
            }
        }
    }

    private var scrollOffsetReader: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: MovieDetailScrollOffsetKey.self,
                    value: geometry.frame(in: .named("movieDetailScroll")).minY
                )
        }
        .frame(height: 0)
    }

    private var topBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.05, green: 0.06, blue: 0.08)
            : Color(red: 0.08, green: 0.09, blue: 0.12)
    }

    private var middleBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.11, green: 0.12, blue: 0.15)
            : Color(red: 0.95, green: 0.95, blue: 0.96)
    }

    private var bottomBackgroundColor: Color {
        colorScheme == .dark ? Color.black : Color(.systemBackground)
    }
}

private struct MovieDetailBackdropView: View {
    let imageURL: URL?
    let height: CGFloat
    let scrollOffset: CGFloat
    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width

    var body: some View {
        let stretchOffset = max(0, scrollOffset)
        let collapseOffset = min(0, scrollOffset)

        PosterImageView(
            url: imageURL,
            cornerRadius: 0,
            placeholderSystemImage: "film"
        )
        .frame(width: screenWidth)
        .frame(height: height + stretchOffset)
        .overlay(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.14),
                    Color.black.opacity(0.34),
                    Color.black.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 40,
                bottomTrailingRadius: 40,
                topTrailingRadius: 0
            )
        )
        .offset(y: collapseOffset * 0.35 - stretchOffset)
        .ignoresSafeArea(edges: .top)
        .background {
            GeometryReader { geometry in
                Color.clear
                    .task(id: geometry.size.width) {
                        if geometry.size.width > 0 {
                            screenWidth = geometry.size.width
                        }
                    }
            }
        }
    }
}

private struct MovieDetailScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
