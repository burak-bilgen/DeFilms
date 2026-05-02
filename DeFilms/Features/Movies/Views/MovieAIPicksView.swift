import SwiftUI

struct MovieAIPicksView: View {
    @ObservedObject var moviesViewModel: MovieSearchViewModel
    @ObservedObject var listsStore: ListsStore

    @EnvironmentObject private var coordinator: MovieCoordinator
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var movieStatusStore: UserMovieStatusStore
    @StateObject private var aiRecommendationStore = MovieAIRecommendationStore()
    @State private var isAppleIntelligenceHelpPresented = false

    private var listMovies: [Movie] {
        listsStore.lists
            .flatMap(\.movies)
            .map(\.asMovie)
            .uniquedByID()
    }

    private var browseMovies: [Movie] {
        moviesViewModel.browseSections.flatMap(\.movies).uniquedByID()
    }

    private var candidateMovies: [Movie] {
        [
            listMovies,
            movieStatusStore.watchlistMovies,
            movieStatusStore.recommendations(from: browseMovies, limit: 18),
            browseMovies
        ]
        .flatMap { $0 }
        .uniquedByID()
    }

    private var moviesByID: [Int: Movie] {
        Dictionary(uniqueKeysWithValues: candidateMovies.map { ($0.id, $0) })
    }

    private var resolvedPicks: [(MovieAIRecommendation, Movie)] {
        aiRecommendationStore.picks.compactMap { pick in
            guard let movie = moviesByID[pick.movieID] else { return nil }
            return (pick, movie)
        }
    }

    private var candidateSignature: String {
        candidateMovies.map(\.id).prefix(80).map(String.init).joined(separator: "-")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                hero

                switch aiRecommendationStore.availability {
                case .available:
                    promptPanel
                    resultsSection
                case .appleIntelligenceDisabled:
                    availabilityPanel(
                        systemImage: "apple.intelligence",
                        title: Localization.string("movies.ai.disabled.title"),
                        message: Localization.string("movies.ai.disabled.message"),
                        actionTitle: Localization.string("movies.ai.disabled.action"),
                        action: { isAppleIntelligenceHelpPresented = true }
                    )
                case .modelNotReady:
                    availabilityPanel(
                        systemImage: "hourglass",
                        title: Localization.string("movies.ai.modelNotReady.title"),
                        message: Localization.string("movies.ai.modelNotReady.message"),
                        actionTitle: nil,
                        action: nil
                    )
                case .unsupportedOS, .deviceNotEligible, .unavailable:
                    MoviesMessageView(
                        title: Localization.string("movies.ai.unavailable.title"),
                        message: Localization.string("movies.ai.unavailable.message"),
                        buttonTitle: nil,
                        action: nil
                    )
                }

                sourceSections
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppPalette.screenBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(Localization.string("tab.ai"))
                    .font(.headline.weight(.semibold))
            }
        }
        .sheet(isPresented: $isAppleIntelligenceHelpPresented) {
            AppleIntelligenceHelpSheet()
                .presentationDetents([.medium])
        }
        .task {
            aiRecommendationStore.refreshAvailability()
            await moviesViewModel.loadBrowseContentIfNeeded(for: preferences.selectedLanguage)
        }
        .onChange(of: candidateSignature) { _ in
            aiRecommendationStore.clearPicks()
        }
        .onChange(of: preferences.selectedLanguage.rawValue) { _ in
            aiRecommendationStore.clearPicks()
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(Localization.string("movies.ai.tab.title"))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(Localization.string("movies.ai.tab.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.md)

                Image(systemName: "sparkles")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [Color.indigo, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
            }

            HStack(spacing: AppSpacing.xs) {
                sourceChip(value: listMovies.count, title: Localization.string("movies.ai.source.lists"))
                sourceChip(value: movieStatusStore.watchlistMovies.count, title: Localization.string("movies.stats.watchlist"))
                sourceChip(value: candidateMovies.count, title: Localization.string("movies.ai.sources.candidates"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [
                    Color(.secondarySystemBackground),
                    Color.indigo.opacity(0.11),
                    Color.cyan.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous)
                .stroke(AppPalette.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.xl, style: .continuous))
        .shadow(color: AppPalette.shadow.opacity(0.7), radius: 14, x: 0, y: 8)
    }

    private var promptPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(Localization.string("movies.ai.prompt.title"))
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            TextField(
                Localization.string("movies.ai.prompt.placeholder"),
                text: $aiRecommendationStore.moodPrompt,
                axis: .vertical
            )
            .font(.body)
            .lineLimit(2...4)
            .padding(AppSpacing.md)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )

            Button(action: generatePicks) {
                HStack {
                    if aiRecommendationStore.isGenerating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "sparkles.tv")
                    }

                    Text(Localization.string("movies.ai.generate"))
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryProminentButtonStyle())
            .disabled(aiRecommendationStore.isGenerating || candidateMovies.isEmpty)

            if let errorMessage = aiRecommendationStore.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .appCardSurface(cornerRadius: AppCornerRadius.lg)
    }

    @ViewBuilder
    private var resultsSection: some View {
        if resolvedPicks.isEmpty && !aiRecommendationStore.isGenerating {
            emptyResultsPanel
        } else if !resolvedPicks.isEmpty {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(Localization.string("movies.ai.results.title"))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(resolvedPicks.enumerated()), id: \.element.0.id) { index, item in
                        aiPickCard(rank: index + 1, pick: item.0, movie: item.1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyResultsPanel: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: "lock.shield")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 38, height: 38)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(Localization.string("movies.ai.empty.title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(Localization.string("movies.ai.empty"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .appCardSurface(cornerRadius: AppCornerRadius.lg)
    }

    @ViewBuilder
    private var sourceSections: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if !listMovies.isEmpty {
                MovieHorizontalSection(
                    title: Localization.string("movies.ai.source.lists"),
                    movies: Array(listMovies.prefix(18))
                )
                .padding(.horizontal, -AppSpacing.md)
            }

            if !movieStatusStore.watchlistMovies.isEmpty {
                MovieHorizontalSection(
                    title: Localization.string("movies.section.watchlist"),
                    movies: Array(movieStatusStore.watchlistMovies.prefix(18))
                )
                .padding(.horizontal, -AppSpacing.md)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func availabilityPanel(
        systemImage: String,
        title: String,
        message: String,
        actionTitle: String?,
        action: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Color.primary.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryProminentButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .appCardSurface(cornerRadius: AppCornerRadius.lg)
    }

    private func aiPickCard(rank: Int, pick: MovieAIRecommendation, movie: Movie) -> some View {
        Button {
            openMovie(movie)
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                ZStack(alignment: .topLeading) {
                    PosterImageView(
                        url: movie.posterURL,
                        cornerRadius: AppCornerRadius.md,
                        placeholderSystemImage: "film"
                    )
                    .frame(width: 76, height: 114)
                    .accessibilityHidden(true)

                    Text("\(rank)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.black.opacity(0.72))
                        .clipShape(Circle())
                        .padding(6)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(movie.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(pick.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)

                    HStack(spacing: AppSpacing.xs) {
                        Text(pick.moodTag)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, AppSpacing.sm)
                            .frame(height: 26)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Capsule())

                        Text("\(Int(pick.confidence * 100))%")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.md)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.lg, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func sourceChip(value: Int, title: String) -> some View {
        HStack(spacing: AppSpacing.xxs) {
            Text("\(value)")
                .font(.caption.weight(.bold))
            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, AppSpacing.sm)
        .frame(height: 28)
        .background(Color.primary.opacity(0.06))
        .clipShape(Capsule())
    }

    private func generatePicks() {
        Task {
            await aiRecommendationStore.generate(
                candidates: candidateMovies,
                statuses: Array(movieStatusStore.statuses.values),
                language: preferences.selectedLanguage,
                preferredProviders: preferences.selectedStreamingProviders
            )
        }
    }

    private func openMovie(_ movie: Movie) {
        coordinator.show(.detail(movie))
    }
}
