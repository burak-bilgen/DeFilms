//
//  DeFilmsUITests.swift
//  DeFilmsUITests
//
//  Created by Burak on 2.04.2026.
//

import XCTest

final class DeFilmsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testTabBarShowsAllRootSections() throws {
        XCTAssertTrue(app.tabBars.buttons["Movies"].waitForExistence(timeout: 5) || app.tabBars.buttons["Filmler"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Favorites"].exists || app.tabBars.buttons["Favoriler"].exists)
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists || app.tabBars.buttons["Ayarlar"].exists)
    }

    @MainActor
    func testSettingsScreenShowsAppearanceAndLanguageOptions() throws {
        let settingsButton = app.tabBars.buttons["Settings"].exists ? app.tabBars.buttons["Settings"] : app.tabBars.buttons["Ayarlar"]
        settingsButton.tap()

        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: 5) || app.staticTexts["Görünüm"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Language"].exists || app.staticTexts["Dil"].exists)
    }
}
