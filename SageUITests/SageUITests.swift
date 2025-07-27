//
//  SageUITests.swift
//  SageUITests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - App launch and basic functionality
//  - Recording feature integration
//  - Critical user flows
//
//  MVP Testing Strategy:
//  - Focus on critical user flows and crash prevention
//  - Test app launch and basic navigation
//  - Verify key integrations (recording)
//  - Remove UI text validation and accessibility checks

import XCTest

final class SageUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Critical User Flow Tests
    
    @MainActor
    func testAppLaunch() throws {
        // Given: App launches
        let app = XCUIApplication()
        app.launch()

        // Then: Should launch without crashing
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testRecordingFeature() throws {
        // Given: App is launched
        let app = XCUIApplication()
        app.launch()

        // When: User navigates to recording screen
        app.tabBars.buttons["Record"].tap()

        // Then: Should show recording interface
        let startButton = app.buttons["Start Recording"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 3), "Start Recording button should exist")
        
        // When: User starts recording
        startButton.tap()
        
        // Then: Should show stop button
        let stopButton = app.buttons["Stop Recording"]
        XCTAssertTrue(stopButton.exists, "Stop Recording button should exist")
        
        // When: User stops recording
        stopButton.tap()
        
        // Then: Should handle recording completion
        XCTAssertTrue(app.exists, "App should remain stable after recording")
    }
}
