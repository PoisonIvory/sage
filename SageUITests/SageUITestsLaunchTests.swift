//
//  SageUITestsLaunchTests.swift
//  SageUITests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - App launch stability
//  - Crash prevention
//
//  MVP Testing Strategy:
//  - Focus on critical crash prevention
//  - Test app launch without crashing
//  - Remove unnecessary setup and validation

import XCTest

final class SageUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        // Given: App launches
        let app = XCUIApplication()
        app.launch()

        // Then: Should launch without crashing
        XCTAssertTrue(app.exists)
        
        // Capture screenshot for visual verification
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
