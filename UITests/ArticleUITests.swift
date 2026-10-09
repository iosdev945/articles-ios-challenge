import XCTest

final class ArticleUITests: XCTestCase {
    private func launch(_ scenario: String = "populated", largeText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-scenario=\(scenario)"]
        if largeText { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        return app
    }
    private func card(_ app: XCUIApplication, index: Int = 0) -> XCUIElement {
        app.cells.element(boundBy: index)
    }
    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testListGridDetailBookmarkAndBack() {
        let app = launch()
        XCTAssertTrue(card(app).waitForExistence(timeout: 10))
        capture("List", app: app)
        app.buttons["list.layout"].tap()
        XCTAssertTrue(app.buttons["Show list"].exists)
        XCTAssertGreaterThanOrEqual(card(app).frame.minX, 0)
        XCTAssertLessThanOrEqual(card(app).frame.maxX, app.frame.maxX)
        XCTAssertEqual(card(app).frame.minY, card(app, index: 1).frame.minY, accuracy: 1)
        capture("Grid", app: app)
        card(app).tap()
        XCTAssertTrue(app.buttons["detail.bookmark"].waitForExistence(timeout: 5))
        let bookmark = app.buttons["detail.bookmark"]
        let previous = bookmark.label
        bookmark.tap()
        XCTAssertNotEqual(bookmark.label, previous)
        capture("Detail", app: app)
        if UIDevice.current.userInterfaceIdiom == .phone {
            let back = app.navigationBars.buttons.matching(NSPredicate(format: "label == 'Articles' OR label == 'Back'")).firstMatch
            XCTAssertTrue(back.waitForExistence(timeout: 5))
            back.tap()
            XCTAssertTrue(card(app).waitForExistence(timeout: 5))
        }
    }
    func testInvalidLinkIsDisabledAndMissingTitleHasFallback() {
        let app = launch()
        XCTAssertTrue(card(app).waitForExistence(timeout: 10))
        app.buttons["list.layout"].tap()
        card(app, index: 1).tap()
        XCTAssertTrue(app.staticTexts["Untitled article"].waitForExistence(timeout: 5))
        let open = app.buttons["detail.openArticle"]
        if !open.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertFalse(open.isEnabled)
        capture("Missing data", app: app)
    }
    func testOfflineWithNoCacheAndRetry() {
        let app = launch("offline")
        XCTAssertTrue(app.staticTexts["You’re offline"].waitForExistence(timeout: 10))
        app.buttons["state.retry"].tap()
        XCTAssertTrue(app.staticTexts["You’re offline"].waitForExistence(timeout: 10))
        capture("Offline", app: app)
    }
    func testOfflineCachedArticlesAreBrowsable() {
        let app = launch("offline-cached")
        XCTAssertTrue(card(app).waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'You’re offline. Showing saved articles.'")).firstMatch.exists)
        card(app).tap()
        XCTAssertTrue(app.buttons["detail.bookmark"].waitForExistence(timeout: 5))
        capture("Cached detail", app: app)
    }
    func testEmptyAndMalformedResponseStates() {
        var app = launch("empty")
        XCTAssertTrue(app.staticTexts["No articles yet"].waitForExistence(timeout: 10))
        capture("Empty", app: app)
        app.terminate()
        app = launch("error")
        XCTAssertTrue(app.staticTexts["Unable to load articles"].waitForExistence(timeout: 10))
        capture("Error", app: app)
    }
    func testSearchFiltersAndClears() {
        let app = launch()
        XCTAssertTrue(card(app).waitForExistence(timeout: 10))
        app.buttons["Search articles"].tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("nonexistentkeyword")
        XCTAssertTrue(app.staticTexts["No matching articles"].waitForExistence(timeout: 5))
        capture("Search empty", app: app)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(card(app).waitForExistence(timeout: 5))
    }
    func testAccessibilityTextRemainsBrowsable() {
        let app = launch(largeText: true)
        XCTAssertTrue(card(app).waitForExistence(timeout: 10))
        app.buttons["list.layout"].tap()
        capture("Accessibility list", app: app)
        card(app).tap()
        XCTAssertTrue(app.buttons["detail.bookmark"].waitForExistence(timeout: 5))
        capture("Accessibility detail", app: app)
    }
}
