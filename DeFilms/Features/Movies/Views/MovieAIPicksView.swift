import SwiftUI

struct MovieAIPicksView: View {
    @ObservedObject var moviesViewModel: MovieSearchViewModel
    @ObservedObject var listsStore: ListsStore

    @EnvironmentObject private var coordinator: MovieCoordinator
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var movieStatusStore: UserMovieStatusStore
    @StateObject private var aiRecommendationStore = MovieAIRecommendationStore()
    @State private var messages: [MovieAIChatMessage] = []
    @State private var draftMessage = ""
    @State private var promptMatchedMovies: [Movie] = []
    @State private var isResolvingPromptCandidates = false
    @State private var isAppleIntelligenceHelpPresented = false
    @FocusState private var isComposerFocused: Bool

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
            promptMatchedMovies,
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

    private var canSendMessage: Bool {
        !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !isResolvingPromptCandidates &&
            !aiRecommendationStore.isGenerating
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(messages) { message in
                        chatBubble(for: message)
                            .id(message.id)
                    }

                    if isResolvingPromptCandidates || aiRecommendationStore.isGenerating {
                        typingBubble
                            .id("typing")
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(MovieAIChatPalette.background)
            .safeAreaInset(edge: .bottom) {
                composer
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isAppleIntelligenceHelpPresented) {
                AppleIntelligenceHelpSheet()
                    .presentationDetents([.medium])
            }
            .task {
                aiRecommendationStore.refreshAvailability()
                appendWelcomeMessageIfNeeded()
                await moviesViewModel.loadBrowseContentIfNeeded(for: preferences.selectedLanguage)
            }
            .onChange(of: messages.count) { _ in
                scrollToBottom(with: proxy)
            }
            .onChange(of: isResolvingPromptCandidates || aiRecommendationStore.isGenerating) { _ in
                scrollToBottom(with: proxy)
            }
            .onChange(of: preferences.selectedLanguage.rawValue) { _ in
                resetConversationForLanguageChange()
            }
        }
    }

    @ViewBuilder
    private func chatBubble(for message: MovieAIChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            if message.role == .assistant {
                assistantAvatar
            }

            if message.role == .user {
                Spacer(minLength: AppSpacing.xl)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? MovieAIChatPalette.userText : MovieAIChatPalette.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if !message.picks.isEmpty {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(Array(message.picks.enumerated()), id: \.element.0.id) { index, item in
                            aiPickCard(rank: index + 1, pick: item.0, movie: item.1)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(message.role == .user ? MovieAIChatPalette.userBubble : MovieAIChatPalette.assistantBubble)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(message.role == .user ? Color.clear : MovieAIChatPalette.border, lineWidth: 1)
            )
            .shadow(
                color: message.role == .user ? Color.clear : MovieAIChatPalette.softShadow,
                radius: 14,
                x: 0,
                y: 8
            )
            .frame(maxWidth: message.role == .user ? 310 : .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .assistant {
                Spacer(minLength: AppSpacing.xl)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(MovieAIChatPalette.assistantAvatarBackground)
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundStyle(MovieAIChatPalette.assistantAvatarForeground)
        }
        .frame(width: 32, height: 32)
        .overlay(Circle().stroke(MovieAIChatPalette.border, lineWidth: 1))
        .shadow(color: MovieAIChatPalette.softShadow, radius: 8, x: 0, y: 4)
        .accessibilityHidden(true)
    }

    private var typingBubble: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            assistantAvatar

            HStack(spacing: AppSpacing.xs) {
                ProgressView()
                    .controlSize(.small)
                Text(Localization.string("movies.ai.chat.thinking"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(MovieAIChatPalette.secondaryText)
            }
            .padding(.horizontal, AppSpacing.md)
            .frame(height: 42)
            .background(MovieAIChatPalette.assistantBubble)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(MovieAIChatPalette.border, lineWidth: 1))
            .shadow(color: MovieAIChatPalette.softShadow, radius: 10, x: 0, y: 6)

            Spacer(minLength: AppSpacing.xl)
        }
    }

    private var composer: some View {
        HStack(alignment: .center, spacing: AppSpacing.xs) {
            TextField(
                Localization.string("movies.ai.chat.placeholder"),
                text: $draftMessage
            )
            .focused($isComposerFocused)
            .lineLimit(1)
            .font(.body)
            .foregroundStyle(MovieAIChatPalette.primaryText)
            .textFieldStyle(.plain)
            .submitLabel(.send)
            .onSubmit(sendMessage)
            .padding(.horizontal, 12)
            .frame(height: 36, alignment: .center)
            .background(MovieAIChatPalette.inputBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(MovieAIChatPalette.inputBorder(isFocused: isComposerFocused), lineWidth: 1)
            )

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(MovieAIChatPalette.sendForeground)
                    .frame(width: 32, height: 32)
                    .background(canSendMessage ? MovieAIChatPalette.sendBackground : MovieAIChatPalette.disabledSendBackground)
                    .clipShape(Circle())
            }
            .disabled(!canSendMessage)
            .accessibilityLabel(Localization.string("movies.ai.chat.send"))
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(MovieAIChatPalette.border)
                .frame(height: 1)
        }
    }

    private func aiPickCard(rank: Int, pick: MovieAIRecommendation, movie: Movie) -> some View {
        Button {
            coordinator.show(.detail(movie))
        } label: {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                ZStack(alignment: .topLeading) {
                    PosterImageView(
                        url: movie.posterURL,
                        cornerRadius: AppCornerRadius.sm,
                        placeholderSystemImage: "film"
                    )
                    .frame(width: 58, height: 87)
                    .accessibilityHidden(true)

                    Text("\(rank)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(MovieAIChatPalette.userText)
                        .frame(width: 20, height: 20)
                        .background(MovieAIChatPalette.rankBadgeBackground)
                        .clipShape(Circle())
                        .padding(4)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(movie.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MovieAIChatPalette.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(movieMetaText(for: movie))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(MovieAIChatPalette.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    if !pick.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(pick.reason)
                            .font(.footnote)
                            .foregroundStyle(MovieAIChatPalette.secondaryText)
                            .lineLimit(3)
                    }

                    if !pick.moodTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(pick.moodTag)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                            .padding(.horizontal, AppSpacing.sm)
                            .frame(height: 23)
                            .background(MovieAIChatPalette.chipBackground)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MovieAIChatPalette.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.md, style: .continuous)
                    .stroke(MovieAIChatPalette.border, lineWidth: 1)
            )
            .shadow(color: MovieAIChatPalette.cardShadow, radius: 10, x: 0, y: 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableScaleButtonStyle())
    }

    private func sendMessage() {
        let prompt = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, canSendMessage else { return }

        messages.append(MovieAIChatMessage(role: .user, text: prompt))
        draftMessage = ""
        isComposerFocused = false

        Task {
            await resolve(prompt: prompt)
        }
    }

    private func resolve(prompt: String) async {
        isResolvingPromptCandidates = true
        aiRecommendationStore.moodPrompt = prompt
        aiRecommendationStore.clearPicks()

        do {
            let aiSearchPlan = await aiRecommendationStore.makeSearchPlan(
                for: prompt,
                language: preferences.selectedLanguage
            )
            let matchedMovies = try await moviesViewModel.loadAICandidateMovies(
                matching: prompt,
                aiSearchPlan: aiSearchPlan
            )
            promptMatchedMovies = matchedMovies
            isResolvingPromptCandidates = false

            guard !matchedMovies.isEmpty else {
                messages.append(
                    MovieAIChatMessage(
                        role: .assistant,
                        text: Localization.string("movies.ai.search.empty")
                    )
                )
                return
            }

            let generatedPicks = await aiRecommendationStore.generate(
                candidates: candidateMovies,
                statuses: Array(movieStatusStore.statuses.values),
                language: preferences.selectedLanguage,
                preferredProviders: preferences.selectedStreamingProviders
            )

            let resolvedPicks = generatedPicks.compactMap { pick -> (MovieAIRecommendation, Movie)? in
                guard let movie = moviesByID[pick.movieID] else { return nil }
                return (pick, movie)
            }
            let displayedPicks = resolvedPicks.isEmpty ? fallbackPicks(from: matchedMovies) : resolvedPicks

            messages.append(
                MovieAIChatMessage(
                    role: .assistant,
                    text: responseText(didUseFallback: resolvedPicks.isEmpty),
                    picks: displayedPicks
                )
            )
        } catch {
            isResolvingPromptCandidates = false
            AppLogger.log("AI prompt movie search failed", category: .search, level: .error)
            messages.append(
                MovieAIChatMessage(
                    role: .assistant,
                    text: Localization.string("movies.ai.search.error")
                )
            )
        }
    }

    private func fallbackPicks(from movies: [Movie]) -> [(MovieAIRecommendation, Movie)] {
        movies.prefix(6).map { movie in
            (
                MovieAIRecommendation(
                    movieID: movie.id,
                    confidence: 0,
                    reason: movie.overview ?? "",
                    moodTag: ""
                ),
                movie
            )
        }
    }

    private func responseText(didUseFallback: Bool) -> String {
        if didUseFallback {
            return Localization.string("movies.ai.chat.fallbackResponse")
        }

        return Localization.string("movies.ai.chat.aiResponse")
    }

    private func movieMetaText(for movie: Movie) -> String {
        var parts = [movie.releaseYear]
        if let rating = movie.voteAverage {
            parts.append(String(format: "%.1f", rating))
        }
        return parts.joined(separator: " · ")
    }

    private func appendWelcomeMessageIfNeeded() {
        guard messages.isEmpty else { return }
        messages.append(
            MovieAIChatMessage(
                role: .assistant,
                text: Localization.string("movies.ai.chat.welcome")
            )
        )
    }

    private func resetConversationForLanguageChange() {
        messages = []
        promptMatchedMovies = []
        aiRecommendationStore.clearPicks()
        appendWelcomeMessageIfNeeded()
    }

    private func scrollToBottom(with proxy: ScrollViewProxy) {
        let lastID = messages.last?.id
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.22)) {
                if isResolvingPromptCandidates || aiRecommendationStore.isGenerating {
                    proxy.scrollTo("typing", anchor: .bottom)
                } else if let lastID {
                    proxy.scrollTo(lastID, anchor: .bottom)
                }
            }
        }
    }
}

private struct MovieAIChatMessage: Identifiable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
    var picks: [(MovieAIRecommendation, Movie)] = []
}

private enum MovieAIChatPalette {
    static let background = Color(.systemGroupedBackground)
    static let assistantBubble = Color(.secondarySystemGroupedBackground)
    static let assistantAvatarBackground = Color(.systemBackground)
    static let assistantAvatarForeground = Color.accentColor
    static let userBubble = Color.primary
    static let userText = Color(.systemBackground)
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    static let inputBackground = Color(.secondarySystemGroupedBackground)
    static let cardBackground = Color(.systemBackground)
    static let chipBackground = Color.primary.opacity(0.055)
    static let border = Color.primary.opacity(0.09)
    static let softShadow = Color.black.opacity(0.05)
    static let cardShadow = Color.black.opacity(0.04)
    static let sendBackground = Color.primary
    static let sendForeground = Color(.systemBackground)
    static let disabledSendBackground = Color.secondary.opacity(0.24)
    static let rankBadgeBackground = Color.primary.opacity(0.78)

    static func inputBorder(isFocused: Bool) -> Color {
        isFocused ? Color.accentColor.opacity(0.35) : Color.primary.opacity(0.08)
    }
}
