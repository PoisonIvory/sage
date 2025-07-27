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
//  - Added real button state verification through functional testing
//  - Added comprehensive localization key detection tests
//  - Added i18n bug prevention for common localization patterns

import XCTest
@testable import Sage

// MARK: - Reading Prompt Screen Test Requirements

// Given the user is on View 3
// Then the UI displays the heading: "Reading Prompt"
// Then the UI displays the button labeled "Next"

// When the user taps "Next"
// Then they are navigated to View 4

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
    
    func testUserIsNavigatedToReadingPromptAfterVocalTest() {
        // Given: User has completed vocal test
        viewModel.currentStep = .vocalTest
        viewModel.shouldShowNextButton = true
        
        // When: User taps "Next"
        viewModel.selectNext()
        
        // Then: Should be on reading prompt screen
        XCTAssertEqual(viewModel.currentStep, .readingPrompt)
    }
    
    func testUserTapsNextOnReadingPrompt() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: User taps "Next"
        viewModel.selectNext()
        
        // Then: Should navigate to final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    // MARK: - UI Content Tests
    
    func testReadingPromptScreenContent() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Should display correct heading
        XCTAssertEqual(viewModel.readingPromptHeading, "Reading Prompt")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.nextButtonTitle, "Next")
    }
    
    func testReadingPromptContentIsConsistent() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: Content is accessed multiple times
        let heading1 = viewModel.readingPromptHeading
        let heading2 = viewModel.readingPromptHeading
        let buttonTitle1 = viewModel.nextButtonTitle
        let buttonTitle2 = viewModel.nextButtonTitle
        
        // Then: Content should be consistent
        XCTAssertEqual(heading1, heading2)
        XCTAssertEqual(buttonTitle1, buttonTitle2)
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
    
    func testReadingPromptScreenStateAfterNavigation() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: User navigates to final step
        viewModel.selectNext()
        
        // Then: Should be on final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
        
        // Then: Should maintain clean state
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
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
    
    func testNextButtonTriggersNavigation() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: User taps "Next" button
        viewModel.selectNext()
        
        // Then: Should navigate to final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    func testNextButtonStateIsConsistent() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: Next button title is accessed multiple times
        let buttonTitle1 = viewModel.nextButtonTitle
        let buttonTitle2 = viewModel.nextButtonTitle
        let buttonTitle3 = viewModel.nextButtonTitle
        
        // Then: Button title should be consistent
        XCTAssertEqual(buttonTitle1, buttonTitle2)
        XCTAssertEqual(buttonTitle2, buttonTitle3)
        XCTAssertEqual(buttonTitle1, "Next")
    }
    
    // MARK: - Content Localization Tests
    
    func testReadingPromptContentUsesCorrectLanguage() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Heading should use proper language
        XCTAssertTrue(viewModel.readingPromptHeading.contains("Reading"))
        XCTAssertTrue(viewModel.readingPromptHeading.contains("Prompt"))
        
        // Then: Button should use proper language
        XCTAssertEqual(viewModel.nextButtonTitle, "Next")
    }
    
    // MARK: - Localization Key Tests
    
    func testReadingPromptContentDoesNotShowLocalizationKeys() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Content should not contain localization keys
        XCTAssertFalse(viewModel.readingPromptHeading.contains("_key"))
        XCTAssertFalse(viewModel.readingPromptHeading.contains("NSLocalizedString"))
        XCTAssertFalse(viewModel.readingPromptHeading.contains("Localizable"))
        
        XCTAssertFalse(viewModel.nextButtonTitle.contains("_key"))
        XCTAssertFalse(viewModel.nextButtonTitle.contains("NSLocalizedString"))
        XCTAssertFalse(viewModel.nextButtonTitle.contains("Localizable"))
    }
    
    func testReadingPromptContentDoesNotShowCommonLocalizationPatterns() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Content should not contain common localization patterns
        XCTAssertFalse(viewModel.readingPromptHeading.contains("reading_prompt"))
        XCTAssertFalse(viewModel.readingPromptHeading.contains("readingPrompt"))
        XCTAssertFalse(viewModel.readingPromptHeading.contains("READING_PROMPT"))
        
        XCTAssertFalse(viewModel.nextButtonTitle.contains("next_button"))
        XCTAssertFalse(viewModel.nextButtonTitle.contains("nextButton"))
        XCTAssertFalse(viewModel.nextButtonTitle.contains("NEXT_BUTTON"))
    }
    
    func testReadingPromptContentIsProperlyLocalized() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Content should be human-readable text, not keys
        XCTAssertTrue(viewModel.readingPromptHeading.count > 5) // Meaningful text length
        XCTAssertTrue(viewModel.nextButtonTitle.count > 0) // Non-empty button text
        
        // Then: Content should not look like code or keys
        XCTAssertFalse(viewModel.readingPromptHeading.contains("."))
        XCTAssertFalse(viewModel.readingPromptHeading.contains("_"))
        XCTAssertFalse(viewModel.nextButtonTitle.contains("."))
        XCTAssertFalse(viewModel.nextButtonTitle.contains("_"))
    }
    
    // MARK: - Error State Tests
    
    func testReadingPromptScreenHandlesErrorsGracefully() {
        // Given: User is on reading prompt screen with previous errors
        viewModel.currentStep = .readingPrompt
        viewModel.errorMessage = "Previous error"
        viewModel.fieldErrors["test"] = "Test error"
        
        // When: User taps "Next" button
        viewModel.selectNext()
        
        // Then: Should still navigate successfully
        XCTAssertEqual(viewModel.currentStep, .finalStep)
        
        // Then: Previous errors should not interfere with navigation
        XCTAssertNotNil(viewModel.errorMessage) // Errors may persist until explicitly cleared
    }
    
    // MARK: - Multiple Navigation Tests
    
    func testMultipleNextButtonTaps() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: User taps "Next" button multiple times
        viewModel.selectNext()
        viewModel.selectNext()
        viewModel.selectNext()
        
        // Then: Should remain on final step screen (not advance further)
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    // MARK: - Screen Transition Tests
    
    func testReadingPromptToFinalStepTransition() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // When: User taps "Next" button
        viewModel.selectNext()
        
        // Then: Should transition to final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
        
        // Then: Should be ready for final step
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.errorMessage)
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
    
    // MARK: - Screen Flow Tests
    
    func testReadingPromptIsCorrectStepInFlow() {
        // Given: User has completed signup and vocal test
        viewModel.selectAnonymous() // Signup
        viewModel.selectBegin() // To vocal test
        viewModel.currentStep = .vocalTest
        viewModel.shouldShowNextButton = true
        viewModel.selectNext() // To reading prompt
        
        // Then: Should be on reading prompt screen
        XCTAssertEqual(viewModel.currentStep, .readingPrompt)
        
        // When: User continues to final step
        viewModel.selectNext()
        
        // Then: Should be on final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
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
    
    // MARK: - Error Recovery Tests
    
    func testReadingPromptRecoversFromPreviousErrors() {
        // Given: User has previous errors from vocal test
        viewModel.currentStep = .readingPrompt
        viewModel.errorMessage = "Upload failed"
        viewModel.fieldErrors["recording"] = "Recording error"
        
        // When: User taps "Next"
        viewModel.selectNext()
        
        // Then: Should navigate successfully despite previous errors
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    func testNextButtonRemainsFunctionalWithErrors() {
        // Given: User has errors but is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        viewModel.errorMessage = "Previous error"
        viewModel.fieldErrors["test"] = "Test error"
        
        // When: User taps "Next" button
        viewModel.selectNext()
        
        // Then: Should navigate successfully, indicating button is still functional
        XCTAssertEqual(viewModel.currentStep, .finalStep)
        
        // Then: Previous errors should not prevent navigation
        XCTAssertNotNil(viewModel.errorMessage) // Errors may persist until explicitly cleared
    }
    
    // MARK: - Content Validation Tests
    
    func testReadingPromptHeadingIsValid() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Heading should be valid
        XCTAssertNotNil(viewModel.readingPromptHeading)
        XCTAssertFalse(viewModel.readingPromptHeading.isEmpty)
        XCTAssertTrue(viewModel.readingPromptHeading.count > 0)
        XCTAssertTrue(viewModel.readingPromptHeading.count < 100) // Reasonable length
    }
    
    func testNextButtonTitleIsValid() {
        // Given: User is on reading prompt screen
        viewModel.currentStep = .readingPrompt
        
        // Then: Button title should be valid
        XCTAssertNotNil(viewModel.nextButtonTitle)
        XCTAssertFalse(viewModel.nextButtonTitle.isEmpty)
        XCTAssertTrue(viewModel.nextButtonTitle.count > 0)
        XCTAssertTrue(viewModel.nextButtonTitle.count < 20) // Reasonable length
    }
} 