
import XCTest

final class DeFilmsUITests: XCTestCase {
    private var app: XCUIApplication!
    private let baseLaunchArguments = ["UITest.ResetState", "UITest.ForceConnected", "UITest.UseInMemoryKeychain"]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = baseLaunchArguments
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testTabBarShowsAllRootSections() throws {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.tabBars.buttons.count, 3)
    }

    @MainActor
    func testSettingsScreenShowsAppearanceAndLanguageOptions() throws {
        dismissOnboardingIfNeeded()
        tabButton(english: "Settings", turkish: "Ayarlar", arabic: "الإعدادات").tap()

        XCTAssertTrue(element(withIdentifier: "settings.appearance.row").waitForExistence(timeout: 5))
        XCTAssertTrue(element(withIdentifier: "settings.language.row").exists)
    }

    @MainActor
    func testOnboardingCanContinueAsGuest() throws {
        XCTAssertTrue(app.buttons["onboarding.continueAsGuest"].waitForExistence(timeout: 5))

        app.buttons["onboarding.continueAsGuest"].tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
    }

    @MainActor
    func testSignUpFlowFromOnboardingShowsSettingsLogoutState() throws {
        XCTAssertTrue(app.buttons["onboarding.signUp"].waitForExistence(timeout: 5))
        app.buttons["onboarding.signUp"].tap()

        let emailField = app.textFields["auth.signUp.email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText("ui-test@example.com")

        let passwordField = app.secureTextFields["auth.signUp.password"]
        passwordField.tap()
        passwordField.typeText("Secret123")

        let confirmPasswordField = app.secureTextFields["auth.signUp.confirmPassword"]
        confirmPasswordField.tap()
        confirmPasswordField.typeText("Secret123")

        app.buttons["auth.signUp.submit"].tap()

        XCTAssertFalse(emailField.waitForExistence(timeout: 3))
        tabButton(english: "Settings", turkish: "Ayarlar", arabic: "الإعدادات").tap()

        XCTAssertTrue(element(withIdentifier: "settings.account.logout").waitForExistence(timeout: 5))
    }

    @MainActor
    func testFavoritesCanCreateListAsGuest() throws {
        app.buttons["onboarding.continueAsGuest"].tap()

        tabButton(english: "Favorites", turkish: "Favoriler", arabic: "المفضلة").tap()

        let createButton = app.buttons["favorites.create.button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let nameField = app.textFields["favorites.create.textField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Weekend")

        app.buttons["favorites.create.submit"].tap()

        XCTAssertTrue(app.staticTexts["Weekend"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMoviesSearchControlsAreReachableAfterOnboarding() throws {
        app.buttons["onboarding.continueAsGuest"].tap()

        let searchField = app.textFields["movies.search.textField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["movies.search.submitButton"].exists)
    }

    @MainActor
    func testMoviesSearchOpensDetailScreenWithMockMovies() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.MockMovies"])
        dismissOnboardingIfNeeded()

        let searchField = app.textFields["movies.search.textField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Dune")

        let submitButton = app.buttons["movies.search.submitButton"]
        XCTAssertTrue(submitButton.exists)
        submitButton.tap()

        let cardButton = element(withIdentifier: "movie.card.1001")
        XCTAssertTrue(cardButton.waitForExistence(timeout: 5))
        cardButton.tap()

        XCTAssertNotNil(waitForElement(withIdentifier: "movies.detail.screen", timeout: 5))
    }

    @MainActor
    func testFavoritesSeededStateShowsLists() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.SkipOnboarding", "UITest.SeedFavorites"])

        tabButton(english: "Favorites", turkish: "Favoriler", arabic: "المفضلة").tap()

        XCTAssertTrue(app.staticTexts["Weekend Watchlist"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Rewatch Soon"].exists)
    }

    @MainActor
    func testMoviesSearchHistoryCanBeCleared() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.SkipOnboarding", "UITest.SeedSearchHistory"])

        XCTAssertTrue(element(withIdentifier: "movies.searchHistory.item.Dune").waitForExistence(timeout: 5))
        app.buttons[LocalizationProbe.moviesSearchHistoryClearIdentifier].tap()
        app.buttons[localizedString("movies.searchHistory.clear.confirmAction", fallback: "Clear")].tap()

        XCTAssertFalse(element(withIdentifier: "movies.searchHistory.item.Dune").waitForExistence(timeout: 2))
    }

    @MainActor
    func testSettingsCanOpenSignInFromSignedOutState() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.SkipOnboarding"])

        tabButton(english: "Settings", turkish: "Ayarlar", arabic: "الإعدادات").tap()
        element(withIdentifier: "settings.account.signIn").tap()

        XCTAssertTrue(app.textFields["auth.signIn.email"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testVisualReferenceOnboardingLight() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.Theme.Light", "UITest.Locale.English"])
        XCTAssertTrue(app.buttons["onboarding.continueAsGuest"].waitForExistence(timeout: 5))
        assertSnapshot(named: "onboarding-light")
    }

    @MainActor
    func testVisualReferenceMoviesBrowseDark() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.SkipOnboarding", "UITest.MockMovies", "UITest.Theme.Dark"])
        XCTAssertTrue(app.textFields["movies.search.textField"].waitForExistence(timeout: 5))
        assertSnapshot(named: "movies-browse-dark")
    }

    @MainActor
    func testVisualReferenceMovieDetailArabicDark() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.SkipOnboarding", "UITest.MockMovies", "UITest.Theme.Dark", "UITest.Locale.Arabic"])

        let searchField = app.textFields["movies.search.textField"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Dune")
        app.buttons["movies.search.submitButton"].tap()

        let cardButton = element(withIdentifier: "movie.card.1001")
        XCTAssertTrue(cardButton.waitForExistence(timeout: 5))
        cardButton.tap()

        XCTAssertNotNil(waitForElement(withIdentifier: "movies.detail.screen", timeout: 5))
        assertSnapshot(named: "movie-detail-arabic-dark")
    }

    @MainActor
    func testVisualReferenceFavoritesFilledDark() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.SkipOnboarding", "UITest.SeedFavorites", "UITest.Theme.Dark"])

        tabButton(english: "Favorites", turkish: "Favoriler", arabic: "المفضلة").tap()

        XCTAssertTrue(app.staticTexts["Weekend Watchlist"].waitForExistence(timeout: 5))
        assertSnapshot(named: "favorites-filled-dark")
    }

    @MainActor
    func testVisualReferenceSettingsSignedInArabic() throws {
        relaunchApp(arguments: ["UITest.ResetState", "UITest.SkipOnboarding", "UITest.SeedSignedInSession", "UITest.Theme.Dark", "UITest.Locale.Arabic"])

        tabButton(english: "Settings", turkish: "Ayarlar", arabic: "الإعدادات").tap()

        XCTAssertTrue(element(withIdentifier: "settings.account.logout").waitForExistence(timeout: 5))
        assertSnapshot(named: "settings-signed-in-arabic")
    }

    private func relaunchApp(arguments: [String]) {
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = normalizedLaunchArguments(arguments)
        app.launch()
    }

    private func normalizedLaunchArguments(_ arguments: [String]) -> [String] {
        var resolvedArguments = arguments
        if !resolvedArguments.contains("UITest.ForceConnected") {
            resolvedArguments.append("UITest.ForceConnected")
        }
        if !resolvedArguments.contains("UITest.UseInMemoryKeychain") {
            resolvedArguments.append("UITest.UseInMemoryKeychain")
        }
        return resolvedArguments
    }

    private func tabButton(english: String, turkish: String, arabic: String) -> XCUIElement {
        let candidates = [
            app.tabBars.buttons[english],
            app.tabBars.buttons[turkish],
            app.tabBars.buttons[arabic]
        ]

        return candidates.first(where: { $0.exists }) ?? candidates[0]
    }

    private func element(withIdentifier identifier: String) -> XCUIElement {
        let candidates = elementCandidates(withIdentifier: identifier)
        return candidates.first(where: { $0.exists }) ?? candidates[0]
    }

    private func waitForElement(withIdentifier identifier: String, timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            if let element = elementCandidates(withIdentifier: identifier).first(where: { $0.exists }) {
                return element
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline

        return nil
    }

    private func elementCandidates(withIdentifier identifier: String) -> [XCUIElement] {
        [
            app.buttons[identifier],
            app.otherElements[identifier],
            app.scrollViews[identifier],
            app.staticTexts[identifier],
            app.cells[identifier]
        ]
    }

    private func dismissOnboardingIfNeeded() {
        let continueAsGuestButton = app.buttons["onboarding.continueAsGuest"]
        if continueAsGuestButton.waitForExistence(timeout: 2) {
            continueAsGuestButton.tap()
        }
    }

    private func localizedString(_ key: String, fallback: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: Bundle(for: Self.self), value: fallback, comment: "")
    }
}

private enum LocalizationProbe {
    static let moviesSearchHistoryClearIdentifier = "movies.searchHistory.clearButton"
}
