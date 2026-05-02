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

    func generate(
        candidates: [Movie],
        statuses: [UserMovieStatus],
        language: AppLanguage,
        preferredProviders: Set<String>
    ) async {
        refreshAvailability()
        guard availability == .available else { return }

        let candidatePool = candidates.uniquedByID().prefix(36).map { $0 }
        guard !candidatePool.isEmpty else { return }

        isGenerating = true
        errorMessage = nil

        do {
            if #available(iOS 26.0, *) {
                picks = try await FoundationModelsMovieRecommendationEngine.generate(
                    mood: moodPrompt,
                    candidates: candidatePool,
                    statuses: statuses,
                    language: language,
                    preferredProviders: preferredProviders
                )
            }
        } catch {
            AppLogger.log("Foundation Models recommendation failed", category: .app, level: .error)
            errorMessage = Localization.string("movies.ai.error")
        }

        isGenerating = false
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
            Prefer movies the user has not watched, use ratings and saved movies as taste signals, and keep reasons short.
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
            .prefix(3)
            .map {
                MovieAIRecommendation(
                    movieID: $0.movieID,
                    confidence: min(max($0.confidence, 0), 1),
                    reason: $0.reason,
                    moodTag: $0.moodTag
                )
            }
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

        let candidateLines = candidates.map { movie in
            let overview = (movie.overview ?? "")
                .replacingOccurrences(of: "\n", with: " ")
                .prefix(180)
            return "- id=\(movie.id); title=\(movie.title); year=\(movie.releaseYear); tmdbRating=\(String(format: "%.1f", movie.voteAverage ?? 0)); watched=\(watchedIDs.contains(movie.id)); genres=\((movie.genreIDs ?? []).map(String.init).joined(separator: ",")); overview=\(overview)"
        }
        .joined(separator: "\n")

        return """
        User mood/request: \(trimmedMood.isEmpty ? "No explicit mood. Choose a strong tonight pick." : trimmedMood)
        Preferred streaming providers: \(preferredProviders.sorted().joined(separator: ", "))

        User taste signals:
        \(statusLines.isEmpty ? "No saved user history yet." : statusLines)

        Candidate movies:
        \(candidateLines)

        Return 3 picks. Each pick must include:
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
}

