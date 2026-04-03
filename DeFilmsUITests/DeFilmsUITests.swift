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
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(app.tabBars.buttons.count, 3)
    }

    @MainActor
    func testSettingsScreenShowsAppearanceAndLanguageOptions() throws {
        let settingsButton = app.tabBars.buttons["Settings"].exists ? app.tabBars.buttons["Settings"] : app.tabBars.buttons["Ayarlar"]
        settingsButton.tap()

        XCTAssertTrue(app.otherElements["settings.appearance.row"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["settings.language.row"].exists)
    }
}
