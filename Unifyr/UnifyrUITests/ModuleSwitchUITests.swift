//
//  ModuleSwitchUITests.swift
//  UnifyrUITests
//
//  Regression: switching modules from the icon rail (regular widths) must
//  not crash. Added after a report that tapping a new module on iPad
//  terminated the app (2026-07-24).
//

import XCTest

final class ModuleSwitchUITests: XCTestCase {

    @MainActor
    func testRailModuleSwitchingDoesNotCrash() throws {
        let app = XCUIApplication()
        app.launch()

        // The rail exists only on regular widths; skip on iPhone.
        let mail = app.buttons["Mail"].firstMatch
        guard mail.waitForExistence(timeout: 10) else {
            throw XCTSkip("No module rail (compact layout) — nothing to test")
        }

        for module in ["Mail", "Calendar", "Reminders", "Notes", "Contacts",
                       "Photos", "Clock", "Drive", "Claude", "Dashboard"] {
            let button = app.buttons[module].firstMatch
            if button.waitForExistence(timeout: 5) {
                button.tap()
                // Give the module a beat to mount; the assertion is simply
                // that the process is still alive afterwards.
                Thread.sleep(forTimeInterval: 1.0)
                XCTAssertEqual(
                    app.state, .runningForeground,
                    "App terminated after switching to \(module)"
                )
            }
        }
    }
}
