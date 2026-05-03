import Combine
import Foundation
import FoundationModels

enum MovieAIRecommendationAvailability: Equatable {
    case unsupportedOS
    case available
    case appleIntelligenceDisabled
    case deviceNotEligible
    case modelNotReady
    case unavailable

    var shouldShowAICard: Bool {
        switch self {
        case .available, .appleIntelligenceDisabled, .modelNotReady:
            return true
        case .unsupportedOS, .deviceNotEligible, .unavailable:
            return false
        }
    }
}

struct MovieAIRecommendation: Equatable, Identifiable {
    let movieID: Int
    let confidence: Double
    let reason: String
    let moodTag: String

    var id: Int { movieID }
}

struct MovieAISearchPlan: Equatable {
    let titleQueries: [String]
    let keywordQueries: [String]
    let semanticTerms: [String]
    let semanticPhrases: [String]
}

@MainActor
final class MovieAIRecommendationStore: ObservableObject {
    @Published private(set) var availability: MovieAIRecommendationAvailability = .unsupportedOS
    @Published private(set) var picks: [MovieAIRecommendation] = []
    @Published private(set) var isGenerating = false
    @Published private(set) var errorMessage: String?
    @Published var moodPrompt = ""

    init() {
        refreshAvailability()
    }

    func refreshAvailability() {
        if #available(iOS 26.0, *) {
            availability = FoundationModelsMovieRecommendationEngine.currentAvailability()
        } else {
            availability = .unsupportedOS
        }
    }

    func clearPicks() {
        picks = []
        errorMessage = nil
    }

    func showError(_ message: String) {
        errorMessage = message
    }

    func makeSearchPlan(for prompt: String, language: AppLanguage) async -> MovieAISearchPlan? {
        refreshAvailability()
        guard availability == .available else { return nil }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return nil }

        do {
            if #available(iOS 26.0, *) {
                return try await FoundationModelsMovieRecommendationEngine.makeSearchPlan(
                    prompt: trimmedPrompt,
                    language: language
                )
            }
        } catch {
            AppLogger.log("Foundation Models search planning failed", category: .app, level: .error)
        }

        return nil
    }

    func generate(
        candidates: [Movie],
        statuses: [UserMovieStatus],
        language: AppLanguage,
        preferredProviders: Set<String>
    ) async -> [MovieAIRecommendation] {
        refreshAvailability()
        guard availability == .available else { return [] }

        let candidatePool = candidates.uniquedByID().prefix(64).map { $0 }
        guard !candidatePool.isEmpty else { return [] }

        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        do {
            if #available(iOS 26.0, *) {
                let generatedPicks = try await FoundationModelsMovieRecommendationEngine.generate(
                    mood: moodPrompt,
                    candidates: candidatePool,
                    statuses: statuses,
                    language: language,
                    preferredProviders: preferredProviders
                )
                picks = generatedPicks
                return generatedPicks
            }
        } catch {
            AppLogger.log("Foundation Models recommendation failed", category: .app, level: .error)
            errorMessage = Localization.string("movies.ai.error")
        }

        return []
    }
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedMovieRecommendationResponse {
    var picks: [GeneratedMovieRecommendationPick]
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedMovieRecommendationPick {
    var movieID: Int
    var confidence: Double
    var reason: String
    var moodTag: String
}

@available(iOS 26.0, *)
@Generable
private struct GeneratedMovieSearchPlanResponse {
    var titleQueries: [String]
    var keywordQueries: [String]
    var semanticTerms: [String]
    var semanticPhrases: [String]
}

@available(iOS 26.0, *)
private enum FoundationModelsMovieRecommendationEngine {
    static func currentAvailability() -> MovieAIRecommendationAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case let .unavailable(reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return .appleIntelligenceDisabled
            case .deviceNotEligible:
                return .deviceNotEligible
            case .modelNotReady:
                return .modelNotReady
            @unknown default:
                return .unavailable
            }
        @unknown default:
            return .unavailable
        }
    }

    static func generate(
        mood: String,
        candidates: [Movie],
        statuses: [UserMovieStatus],
        language: AppLanguage,
        preferredProviders: Set<String>
    ) async throws -> [MovieAIRecommendation] {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return [] }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are DeFilms' private on-device movie recommendation assistant.
            Rank only the candidate movies provided by the app. Never invent movie IDs.
            The app already ordered candidates by TMDB title, keyword, and overview relevance. Treat earlier candidates as stronger request matches.
            Prefer movies the user has not watched, use ratings and saved movies as taste signals, and keep reasons short.
            When the user names a theme, genre, creature, actor, franchise, or keyword, prioritize candidates that match that request.
            Infer cinematic intent from combinations of concepts and prefer iconic matches when the candidate set supports them.
            Respond in \(languageInstruction(for: language)).
            """
        )

        let response = try await session.respond(
            to: prompt(
                mood: mood,
                candidates: candidates,
                statuses: statuses,
                preferredProviders: preferredProviders
            ),
            generating: GeneratedMovieRecommendationResponse.self,
            options: GenerationOptions(
                sampling: .greedy,
                temperature: 0.2,
                maximumResponseTokens: 520
            )
        )

        let candidateIDs = Set(candidates.map(\.id))
        return response.content.picks
            .filter { candidateIDs.contains($0.movieID) }
            .prefix(6)
            .map {
                MovieAIRecommendation(
                    movieID: $0.movieID,
                    confidence: min(max($0.confidence, 0), 1),
                    reason: $0.reason,
                    moodTag: $0.moodTag
                )
            }
    }

    static func makeSearchPlan(prompt: String, language: AppLanguage) async throws -> MovieAISearchPlan {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            return MovieAISearchPlan(titleQueries: [], keywordQueries: [], semanticTerms: [], semanticPhrases: [])
        }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You convert natural movie requests into TMDB search strategy.
            Do not simply echo the user's words. Infer cinematic concepts, subgenres, settings, creatures, story patterns, eras, and iconic search phrases.
            Return concise English search terms because TMDB keyword data is strongest in English.
            For vague requests, include both broad keyword concepts and a few representative title/franchise queries.
            """
        )

        let response = try await session.respond(
            to: """
            User request in \(languageInstruction(for: language)): \(prompt)

            Generate:
            - titleQueries: up to 6 TMDB movie title/franchise queries, only when a title/franchise is likely.
            - keywordQueries: up to 16 TMDB keyword searches for themes, settings, creatures, actions, and genres.
            - semanticTerms: up to 14 single concept terms useful for ranking title/overview matches.
            - semanticPhrases: up to 10 multi-word phrases useful for ranking title/overview matches.
            """,
            generating: GeneratedMovieSearchPlanResponse.self,
            options: GenerationOptions(
                sampling: .greedy,
                temperature: 0.15,
                maximumResponseTokens: 420
            )
        )

        return MovieAISearchPlan(
            titleQueries: sanitized(response.content.titleQueries, limit: 6),
            keywordQueries: sanitized(response.content.keywordQueries, limit: 16),
            semanticTerms: sanitized(response.content.semanticTerms, limit: 14),
            semanticPhrases: sanitized(response.content.semanticPhrases, limit: 10)
        )
    }

    private static func prompt(
        mood: String,
        candidates: [Movie],
        statuses: [UserMovieStatus],
        preferredProviders: Set<String>
    ) -> String {
        let trimmedMood = mood.trimmingCharacters(in: .whitespacesAndNewlines)
        let watchedIDs = Set(statuses.filter(\.isWatched).map(\.id))
        let statusLines = statuses
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(18)
            .map { status in
                let rating = status.rating.map { "\($0)/5" } ?? "-"
                return "- id=\(status.id); title=\(status.movie.title); watched=\(status.isWatched); watchlist=\(status.isWatchlisted); rating=\(rating); genres=\((status.movie.genreIDs ?? []).map(String.init).joined(separator: ","))"
            }
            .joined(separator: "\n")

        let candidateLines = candidates.enumerated().map { index, movie in
            let overview = (movie.overview ?? "")
                .replacingOccurrences(of: "\n", with: " ")
                .prefix(220)
            return "- rank=\(index + 1); id=\(movie.id); title=\(movie.title); year=\(movie.releaseYear); tmdbRating=\(String(format: "%.1f", movie.voteAverage ?? 0)); watched=\(watchedIDs.contains(movie.id)); genres=\((movie.genreIDs ?? []).map(String.init).joined(separator: ",")); overview=\(overview)"
        }
        .joined(separator: "\n")

        return """
        User mood/request: \(trimmedMood.isEmpty ? "No explicit mood. Choose a strong tonight pick." : trimmedMood)
        Preferred streaming providers: \(preferredProviders.sorted().joined(separator: ", "))

        User taste signals:
        \(statusLines.isEmpty ? "No saved user history yet." : statusLines)

        Candidate movies:
        \(candidateLines)

        Return up to 6 picks. Each pick must include:
        - movieID from the candidates only
        - confidence between 0 and 1
        - reason under 120 characters
        - moodTag under 24 characters
        """
    }

    private static func languageInstruction(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return "English"
        case .turkish:
            return "Turkish"
        case .arabic:
            return "Arabic"
        }
    }

    private static func sanitized(_ values: [String], limit: Int) -> [String] {
        var seen = Set<String>()
        return values
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty && seen.insert($0).inserted }
            .prefix(limit)
            .map { $0 }
    }
}
