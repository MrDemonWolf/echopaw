import XCTest

@MainActor
final class WorkspaceTests: XCTestCase {
    func testOfflinePreviewAndDeliberateResume() throws {
        let app = XCUIApplication()
        app.launchEnvironment["ECHOPAW_CONNECTION_TEST_ID"] = UUID().uuidString
        app.launchArguments = ["-useSampleCharacter", "YES", "-blinkAutomatically", "NO", "-ApplePersistenceIgnoreState", "YES", "-setupGuideOffered", "YES"]
        app.launch()
        let window = app.windows["dashboard"]
        let sidebar = window.outlines.firstMatch
        sidebar.staticTexts["Dashboard"].click()
        app.buttons["Open audio settings"].click()
        XCTAssertEqual(window.title, "Audio & capture")
        app.typeKey(",", modifierFlags: .command)
        XCTAssertEqual(window.title, "Audio & capture")
        sidebar.staticTexts["Dashboard"].click()
        app.typeKey(",", modifierFlags: .command)
        XCTAssertEqual(window.title, "General")
        sidebar.staticTexts["Dashboard"].click()
        app.menuBars.menuBarItems["Character"].click()
        XCTAssertTrue(app.menuItems["Preview blink"].exists)
        app.typeKey(.escape, modifierFlags: [])
        app.menuBars.menuBarItems["Session"].click()
        XCTAssertTrue(app.menuItems["Emergency stop"].exists)
        app.typeKey(.escape, modifierFlags: [])
        let preview = app.buttons["Preview talking"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Offline rehearsal"].exists)
        XCTAssertFalse(app.buttons["Resume AI"].exists)
        XCTAssertFalse(app.staticTexts["Connections"].exists)
        app.buttons["Mute speech"].click()
        XCTAssertFalse(preview.isEnabled)
        app.buttons["Emergency stop"].click()
        XCTAssertFalse(app.buttons["Unmute speech"].isEnabled)
        app.buttons["Resume preview"].click()
        XCTAssertFalse(preview.isEnabled)
        app.buttons["Unmute speech"].click()
        sidebar.staticTexts["Character"].click()
        let blink = app.buttons["Preview blink"]
        XCTAssertTrue(blink.waitForExistence(timeout: 4))
        if !app.buttons["Choose idle image"].exists {
            app.buttons["Character inspector"].click()
        }
        for label in ["Choose idle image", "Choose speaking image", "Preview talking", "Preview blink"] {
            XCTAssertTrue(app.buttons[label].isHittable, "\(label) should be reachable with the inspector open")
        }
        blink.click()
        XCTAssertFalse(app.buttons["Outfit"].exists)
        XCTAssertFalse(app.buttons["Props"].exists)
        XCTAssertTrue(app.buttons["Preview talking"].exists)
    }

    func testAccountPreferencesAndLocalKeyLifecycle() {
        let app = XCUIApplication()
        app.launchEnvironment["ECHOPAW_CONNECTION_TEST_ID"] = UUID().uuidString
        app.launch()
        openSidebarPage("API Keys", in: app)
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
        openSidebarPage("API Keys", in: app)
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Add ElevenLabs key"].exists)
        openSidebarPage("Twitch", in: app)
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
        XCTAssertFalse(guide.buttons["Open Twitch settings"].exists)
        guide.buttons["Open API Keys settings"].click()
        XCTAssertTrue(app.windows["dashboard"].buttons["Add OpenAI key"].waitForExistence(timeout: 5))
        guide.buttons["Done"].click()
    }

    func testCompactCharacterWorkspace() throws {
        let fixtureFolder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: fixtureFolder, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: fixtureFolder) }
        let filename = String(repeating: "long-idle-pose-", count: 10) + "final.png"
        let fixture = fixtureFolder.appending(path: filename)
        let sample = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "EchoPaw/Resources/SampleCharacter/idle.png")
        try FileManager.default.copyItem(at: sample, to: fixture)

        for appearance in ["light", "dark"] {
            let app = XCUIApplication()
            app.launchEnvironment["ECHOPAW_CONNECTION_TEST_ID"] = UUID().uuidString
            app.launchArguments = [
                "-ApplePersistenceIgnoreState", "YES", "-setupGuideOffered", "YES",
                "-useSampleCharacter", "YES", "-windowAppearance", appearance
            ]
            app.launch()
            defer { app.terminate() }

            let window = app.windows["dashboard"]
            let character = window.outlines.firstMatch.staticTexts["Character"]
            XCTAssertTrue(character.waitForExistence(timeout: 5))
            character.click()

            let idlePicker = window.buttons["Choose idle image"]
            if !idlePicker.exists {
                window.buttons["Character inspector"].click()
            }
            XCTAssertTrue(idlePicker.waitForExistence(timeout: 5))

            let corner = window.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 1))
                .withOffset(CGVector(dx: -3, dy: -3))
            corner.click(forDuration: 0.1, thenDragTo: corner.withOffset(CGVector(dx: -350, dy: -400)))
            XCTAssertEqual(window.frame.width, 760, accuracy: 4)
            XCTAssertGreaterThanOrEqual(window.frame.height, 480)
            XCTAssertLessThan(window.frame.height, 545)

            for title in ["Choose idle image", "Choose speaking image", "Preview talking", "Preview blink"] {
                XCTAssertTrue(window.buttons[title].isHittable, "\(title) at minimum size in \(appearance) appearance")
            }
            app.typeKey("i", modifierFlags: [.command, .control])
            XCTAssertTrue(idlePicker.waitForNonExistence(timeout: 5))
            app.typeKey("i", modifierFlags: [.command, .control])
            XCTAssertTrue(idlePicker.waitForExistence(timeout: 5))

            idlePicker.click()
            let open = app.sheets.buttons["Open"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            app.typeKey("g", modifierFlags: [.command, .shift])
            app.typeText(fixture.path)
            app.typeKey(.return, modifierFlags: [])
            open.click()
            XCTAssertTrue(open.waitForNonExistence(timeout: 5))
            XCTAssertEqual(idlePicker.value as? String, filename)
            XCTAssertTrue(window.buttons["Choose speaking image"].isHittable)
            XCTAssertFalse(window.buttons["Use these images"].isEnabled)
        }
    }

    private func openSidebarPage(_ title: String, in app: XCUIApplication) {
        let row = app.windows["dashboard"].outlines.firstMatch.staticTexts[title]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.click()
    }
}
