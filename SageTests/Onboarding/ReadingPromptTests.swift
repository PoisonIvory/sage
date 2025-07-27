//
//  ReadingPromptTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - UI content verification for reading prompt screen
//  - Navigation from reading prompt to final step
//  - Screen state management
//  - Button interactions
//  - Localization key verification
//
//  Improvements:
//  - Consolidated redundant navigation tests
//  - Merged string consistency and validation tests
//  - Limited localization key tests to essential checks
//  - Removed overzealous state checks
//  - Removed flow tests (should be in dedicated onboarding flow test)

import XCTest
@testable import Sage

// MARK: - Reading Prompt Screen Test Requirements

// Given the user is on View 3
// Then the UI displays the heading: "Reading Prompt"
// Then the UI displays the button labeled "Next"

// When the user taps "Next"
// Then they are navigated to View 4

@MainActor
final class ReadingPromptTests: XCTestCase {
    
    // MARK: - Test Properties
    private var harness: OnboardingTestHarness!
    private var viewModel: OnboardingJourneyViewModel!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        harness = OnboardingTestHarness()
        viewModel = harness.makeViewModel()
    }
    
    override func tearDown() {
        harness.resetAllMocks()
        harness = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationFromReadingPromptToFinalStep() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: User taps "Next"
        viewModel.selectNext()
        
        // Then: Should navigate to final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    // MARK: - UI Content Tests
    
    func testReadingPromptUIContentIsValid() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Should display correct heading
        XCTAssertEqual(viewModel.readingPromptHeading, "Reading Prompt")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.nextButtonTitle, "Next")
    }
    
    // MARK: - Screen State Tests
    
    func testReadingPromptScreenStateIsCorrect() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Should not be recording
        XCTAssertFalse(viewModel.isRecording)
        
        // Then: Should not have error messages
        XCTAssertNil(viewModel.errorMessage)
        
        // Then: Should not have field errors
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        
        // Then: Should not show next button (this screen has its own next button)
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    // MARK: - Button Interaction Tests
    
    func testNextButtonIsEnabled() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Next button should be enabled and functional
        // Note: Since there's no specific isNextButtonEnabled property, we verify
        // that the button action works correctly, which implies it's enabled
        let initialStep = viewModel.currentStep
        
        // When: User taps "Next" button
        viewModel.selectNext()
        
        // Then: Should navigate successfully, indicating button is enabled
        XCTAssertNotEqual(viewModel.currentStep, initialStep)
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    // MARK: - Localization Key Tests
    
    func testLocalizedStringsAreHumanReadable() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Content should not contain localization keys
        XCTAssertFalse(viewModel.readingPromptHeading.contains("_"))
        XCTAssertFalse(viewModel.nextButtonTitle.contains("_"))
        
        // Then: Content should be human-readable text, not keys
        XCTAssertTrue(viewModel.readingPromptHeading.count > 5) // Meaningful text length
        XCTAssertTrue(viewModel.nextButtonTitle.count > 0) // Non-empty button text
    }
    
    // MARK: - Error State Tests
    
    func testErrorsDoNotBlockNavigation() {
        // Given: User is on reading prompt screen with previous errors
        viewModel.currentStep = .readingPrompt
        viewModel.errorMessage = "Previous error"
        viewModel.fieldErrors["test"] = "Test error"
        
        // When: User taps "Next" button
        viewModel.selectNext()
        
        // Then: Should still navigate successfully
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    // MARK: - Content Accessibility Tests
    
    func testReadingPromptContentIsAccessible() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Content should not be empty
        XCTAssertFalse(viewModel.readingPromptHeading.isEmpty)
        XCTAssertFalse(viewModel.nextButtonTitle.isEmpty)
        
        // Then: Content should be meaningful
        XCTAssertTrue(viewModel.readingPromptHeading.count > 5)
        XCTAssertTrue(viewModel.nextButtonTitle.count > 0)
    }
    
    // MARK: - State Persistence Tests
    
    func testReadingPromptMaintainsUserProfile() {
        // Given: User has completed signup and has a profile
        viewModel.selectAnonymous()
        let originalProfile = viewModel.userProfile
        
        // When: User navigates to reading prompt
        viewModel.currentStep = .readingPrompt
        
        // Then: Should maintain user profile
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.id, originalProfile?.id)
        
        // When: User navigates to final step
        viewModel.selectNext()
        
        // Then: Should still maintain user profile
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.id, originalProfile?.id)
    }
} 