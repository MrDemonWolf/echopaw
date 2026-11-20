import XCTest

@MainActor
final class WorkspaceTests: XCTestCase {
    func testOfflinePreviewAndDeliberateResume() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-useSampleCharacter", "YES", "-blinkAutomatically", "NO"]
        app.launch()
        let sidebar = app.outlines.firstMatch
        sidebar.staticTexts["Dashboard"].click()
        let preview = app.buttons["Preview talking"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Resume AI"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Not connected' OR value CONTAINS 'Not connected'")).count >= 3)
        app.buttons["Mute speech"].click()
        XCTAssertFalse(preview.isEnabled)
        app.buttons["Resume AI"].click()
        XCTAssertTrue(app.buttons["Pause AI"].exists)
        app.buttons["Emergency stop"].click()
        XCTAssertFalse(app.buttons["Unmute speech"].isEnabled)
        app.buttons["Resume preview"].click()
        XCTAssertFalse(preview.isEnabled)
        app.buttons["Unmute speech"].click()
        XCTAssertTrue(app.buttons["Resume AI"].exists)
        sidebar.staticTexts["Character"].click()
        let blink = app.buttons["Preview blink"]
        XCTAssertTrue(blink.waitForExistence(timeout: 4))
        blink.click()
        XCTAssertFalse(app.buttons["Outfit"].exists)
        XCTAssertFalse(app.buttons["Props"].exists)
        XCTAssertTrue(app.buttons["Preview talking"].exists)
    }
}
