//
//  OnboardingJourneyUITests.swift
//  SageUITests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - End-to-end onboarding completion
//  - Critical user flows (anonymous signup)
//  - Recording functionality
//  - Navigation between screens
//
//  MVP Testing Strategy:
//  - Focus on critical user flows and crash prevention
//  - Test complete user journeys from start to finish
//  - Verify key integrations (recording, navigation)
//  - Remove UI text validation and accessibility checks

import XCTest

class OnboardingJourneyUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["-UITesting"]  
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Critical User Flow Tests
    
    func testCompleteOnboardingJourney() {
        // Given: User starts onboarding
        // When: User completes entire onboarding flow
        app.buttons["Get Started"].tap()
        app.buttons["Continue Anonymously"].tap()
        app.buttons["Begin"].tap()
        
        // Then: Should navigate to vocal test
        XCTAssertTrue(app.staticTexts["Please say 'ahh' for 10 seconds."].exists)
        
        // When: User starts recording
        app.buttons["Begin"].tap()
        
        // Then: Should show recording UI
        XCTAssertTrue(app.otherElements["CountdownTimer"].exists)
        
        // When: Recording completes and user continues
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 15))
        nextButton.tap()
        
        // Then: Should navigate to reading prompt
        XCTAssertTrue(app.navigationBars["Reading Prompt"].exists)
        
        // When: User completes final step
        app.buttons["Finish"].tap()
        
        // Then: Should complete onboarding
        XCTAssertTrue(app.otherElements["HomeView"].exists)
    }
    
    func testRecordingFunctionality() {
        // Given: User is on vocal test screen
        app.buttons["Get Started"].tap()
        app.buttons["Continue Anonymously"].tap()
        app.buttons["Begin"].tap()
        
        // When: User starts recording
        app.buttons["Begin"].tap()
        
        // Then: Should show recording indicators
        XCTAssertTrue(app.otherElements["CountdownTimer"].exists)
        XCTAssertTrue(app.otherElements["ProgressBar"].exists)
        
        // When: Recording completes
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 15))
        
        // Then: Should show next button
        XCTAssertTrue(nextButton.exists)
    }
    
    func testAppLaunchAndBasicNavigation() {
        // Given: App launches
        // Then: Should show initial screen
        XCTAssertTrue(app.buttons["Get Started"].exists)
        XCTAssertTrue(app.buttons["I already have an account"].exists)
        
        // When: User taps Get Started
        app.buttons["Get Started"].tap()
        
        // Then: Should show signup options
        XCTAssertTrue(app.buttons["Continue Anonymously"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
    }
}
