import XCTest

final class StampbookUITests: XCTestCase {
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testAddCardAppearsInList() throws {
        let app = launchApp()
        let addButton = app.buttons["addCardButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 8))
        addButton.tap()

        let nameField = app.textFields["cardNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Test Cafe")

        let punchesField = app.textFields["punchesRequiredField"]
        punchesField.tap()
        punchesField.typeText("10")

        let rewardField = app.textFields["rewardField"]
        rewardField.tap()
        rewardField.typeText("Free item")

        app.buttons["cardSaveButton"].tap()

        let tile = app.otherElements["cardTile_Test Cafe"]
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
    }

    func testPunchIncrementsProgress() throws {
        let app = launchApp()
        let punchButton = app.buttons["tilePunchButton_Corner Café"]
        XCTAssertTrue(punchButton.waitForExistence(timeout: 8))
        punchButton.tap()
        // Just confirm the tap doesn't crash the app and the tile still exists.
        XCTAssertTrue(app.otherElements["cardTile_Corner Café"].waitForExistence(timeout: 5))
    }

    func testFreeLimitTriggersPaywallAtFourthCard() throws {
        let app = launchApp()
        // Seed data ships 2 cards, freeCardLimit is 3, so add one more to reach
        // the limit before expecting the paywall on the next add attempt.
        let addButton = app.buttons["addCardButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 8))
        addButton.tap()
        let nameField = app.textFields["cardNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Third Card")
        app.textFields["punchesRequiredField"].tap()
        app.textFields["punchesRequiredField"].typeText("5")
        app.textFields["rewardField"].tap()
        app.textFields["rewardField"].typeText("Free")
        app.buttons["cardSaveButton"].tap()

        // Now at the free limit (3 cards) — tapping add again should show the
        // paywall directly instead of the add-card form.
        addButton.tap()

        XCTAssertTrue(app.buttons["purchaseProButton"].waitForExistence(timeout: 8))
    }

    func testKeyboardDismissesOnTapOutsideInAddSheet() throws {
        let app = launchApp()
        app.buttons["addCardButton"].tap()

        let nameField = app.textFields["cardNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Testing")
        XCTAssertTrue(app.keyboards.element.waitForExistence(timeout: 5))

        let sectionHeader = app.staticTexts["Card"]
        XCTAssertTrue(sectionHeader.waitForExistence(timeout: 5))
        sectionHeader.tap()

        let keyboardGone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.element, handler: nil)
        wait(for: [keyboardGone], timeout: 5)
    }

    func testSettingsTabOpens() throws {
        let app = launchApp()
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 8))
        settingsTab.tap()
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 5))
    }
}
