//
//  MovieDetailView.swift
//  DeFilms
//

import SwiftUI

struct MovieDetailView: View {
    private let heroHeight: CGFloat = 420

    @StateObject private var viewModel: MovieDetailViewModel
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var toastCenter: ToastCenter
    @Environment(\.colorScheme) private var colorScheme
    @State private var scrollOffset: CGFloat = 0
    @State private var isContentVisible = false

    init(viewModel: MovieDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                                movie: viewModel.movie,
                                viewModel: viewModel,
                                heroHeight: heroHeight,
                                scrollOffset: scrollOffset
                            )

                            MovieDetailContentCardView(viewModel: viewModel)
                                .padding(.horizontal, 18)
                                .opacity(isContentVisible ? 1 : 0)
                                .offset(y: isContentVisible ? 0 : 24)

                            if !viewModel.directors.isEmpty {
                                MoviePeopleCarouselSection(
                                    title: Localization.string("movies.detail.director"),
                                    members: viewModel.directors
                                )
                                .opacity(isContentVisible ? 1 : 0)
                                .offset(y: isContentVisible ? 0 : 28)
                            }

                            if !viewModel.cast.isEmpty {
                                MoviePeopleCarouselSection(
                                    title: Localization.string("movies.detail.cast"),
                                    members: viewModel.cast
                                )
                                .opacity(isContentVisible ? 1 : 0)
                                .offset(y: isContentVisible ? 0 : 32)
                            }

                            if !viewModel.streamingPlatforms.isEmpty {
                                MoviePlatformCarouselSection(
                                    title: Localization.string("movies.detail.availableOn"),
                                    platforms: viewModel.streamingPlatforms
                                )
                                .opacity(isContentVisible ? 1 : 0)
                                .offset(y: isContentVisible ? 0 : 36)
                            }

                            if !viewModel.similarMovies.isEmpty {
                                MovieDetailCarouselSection(
                                    title: Localization.string("movies.detail.similar"),
                                    movies: viewModel.similarMovies
                                )
                                .opacity(isContentVisible ? 1 : 0)
                                .offset(y: isContentVisible ? 0 : 40)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
        .statusBar(hidden: true)
        .accessibilityIdentifier("movies.detail.screen")
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.detail?.id) { detailID in
            guard detailID != nil else {
                isContentVisible = false
                return
            }

            withAnimation(AppAnimation.emphasizedSpring) {
                isContentVisible = true
            }
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
        .onChange(of: viewModel.toastItem?.id) { _ in
            relayToast(from: viewModel.toastItem)
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

    private func relayToast(from item: ToastItem?) {
        guard let item else { return }
        toastCenter.show(message: item.message, style: item.style)
        viewModel.clearToast()
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
