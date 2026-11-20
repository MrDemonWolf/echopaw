import XCTest

@MainActor
final class WorkspaceTests: XCTestCase {
    func testOfflinePreviewAndDeliberateResume() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ECHOPAW_CONNECTION_TEST_ID"] = UUID().uuidString
        app.launchArguments = ["-useSampleCharacter", "YES", "-blinkAutomatically", "NO"]
        app.launch()
        let sidebar = app.outlines.firstMatch
        sidebar.staticTexts["Dashboard"].click()
        let preview = app.buttons["Preview talking"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Resume AI"].exists)
        XCTAssertGreaterThanOrEqual(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Not connected' OR value CONTAINS 'Not connected'")).count, 2)
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

    func testAccountPreferencesAndLocalKeyLifecycle() {
        let app = XCUIApplication()
        app.launchEnvironment["ECHOPAW_CONNECTION_TEST_ID"] = UUID().uuidString
        app.launchArguments = ["-preferencesTab", "privacy"]
        app.launch()
        openSettings("API Keys", in: app)
        let add = app.buttons["Add OpenAI key"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.click()
        XCTAssertTrue(app.secureTextFields["Paste API key"].exists)
        XCTAssertFalse(app.buttons["Check and save"].isEnabled)
        let field = app.secureTextFields["Paste API key"]
        field.click()
        field.typeText("ep-test-first")
        app.buttons["Check and save"].click()
        let replace = app.buttons["Replace OpenAI key"]
        XCTAssertTrue(replace.waitForExistence(timeout: 5))
        replace.click()
        field.click()
        field.typeText("ep-test-rejected")
        app.buttons["Check and save"].click()
        let checkError = app.descendants(matching: .any).matching(identifier: "key-check-error").firstMatch
        XCTAssertTrue(checkError.waitForExistence(timeout: 5))
        app.buttons["Cancel"].click()
        XCTAssertTrue(replace.waitForExistence(timeout: 5))
        replace.click()
        XCTAssertFalse(app.buttons["Check and save"].isEnabled)
        field.click()
        field.typeText("ep-test-replacement")
        app.buttons["Check and save"].click()
        let remove = app.buttons["Remove OpenAI key"]
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        remove.click()
        app.buttons["Remove key"].click()
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        app.terminate()
        app.launch()
        openSettings("API Keys", in: app)
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add ElevenLabs key"].exists)
        app.terminate()
        app.launchArguments = ["-preferencesTab", "twitch"]
        app.launch()
        openSettings("Twitch", in: app)
        XCTAssertFalse(app.buttons["Connect broadcaster"].isEnabled)
        XCTAssertFalse(app.buttons["Connect bot"].isEnabled)
        XCTAssertTrue(app.textFields["Public client ID"].exists)
    }

    func testSetupGuideRehearsalAndResume() {
        let app = XCUIApplication()
        app.launchEnvironment["ECHOPAW_CONNECTION_TEST_ID"] = UUID().uuidString
        app.launchArguments = ["-useSampleCharacter", "YES"]
        app.launch()
        let openGuide = app.buttons["Setup Guide"]
        XCTAssertTrue(openGuide.waitForExistence(timeout: 5))
        openGuide.click()
        let guide = app.windows["Setup Guide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        let back = guide.buttons["Back"]
        if back.exists { back.click() }
        if back.exists { back.click() }
        guide.buttons["Play sample line"].click()
        XCTAssertTrue(guide.buttons["Stop test"].exists)
        guide.buttons["Continue"].click()
        XCTAssertTrue(guide.staticTexts["Check your OBS output"].exists)
        guide.buttons["Set up later"].click()
        openGuide.click()
        XCTAssertTrue(guide.staticTexts["Check your OBS output"].waitForExistence(timeout: 5))
        guide.buttons["Skip OBS"].click()
        XCTAssertTrue(guide.buttons["Open API Keys settings"].exists)
        XCTAssertTrue(guide.buttons["Open Twitch settings"].exists)
        guide.buttons["Done"].click()
    }

    private func openSettings(_ title: String, in app: XCUIApplication) {
        app.activate()
        if !app.windows[title].exists {
            app.typeKey(",", modifierFlags: .command)
        }
        XCTAssertTrue(app.windows[title].waitForExistence(timeout: 5))
    }
}
