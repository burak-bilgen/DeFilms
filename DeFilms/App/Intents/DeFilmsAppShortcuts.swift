import AppIntents

@available(iOS 16.0, *)
struct OpenMoviePickerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pick a Movie"
    static var description = IntentDescription("Open DeFilms when you want help choosing what to watch.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}

@available(iOS 16.0, *)
struct OpenWatchlistIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Watchlist"
    static var description = IntentDescription("Open DeFilms to continue from your saved movies.")
    static var openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}

@available(iOS 16.0, *)
struct DeFilmsAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenMoviePickerIntent(),
            phrases: [
                "Pick a movie in \(.applicationName)",
                "What should I watch in \(.applicationName)"
            ],
            shortTitle: "Pick Movie",
            systemImageName: "sparkles.tv"
        )

        AppShortcut(
            intent: OpenWatchlistIntent(),
            phrases: [
                "Open my watchlist in \(.applicationName)",
                "Show my saved movies in \(.applicationName)"
            ],
            shortTitle: "Watchlist",
            systemImageName: "bookmark"
        )
    }
}
