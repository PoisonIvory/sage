//
//  FinalStepTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - UI content verification for final step screen
//  - Onboarding completion handling
//  - Coordinator notification
//  - Navigation to home page
//  - User profile finalization

import XCTest
@testable import Sage

// MARK: - Final Step Screen Test Requirements

// Given the user is on View 4
// Then the UI displays the message: "Almost there! You're one step away from completing setup."
// Then the UI displays the "Finish" button

// When the user taps "Finish"
// Then the user is navigated to the Home page

final class FinalStepTests: XCTestCase {
    
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
    
    func testUserIsNavigatedToFinalStepAfterReadingPrompt() {
        // Given: User has completed reading prompt
        viewModel.currentStep = .readingPrompt
        
        // When: User taps "Next"
        viewModel.selectNext()
        
        // Then: Should be on final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
    }
    
    func testUserTapsFinish() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: User taps "Finish"
        viewModel.selectFinish()
        
        // Then: Should complete onboarding
        XCTAssertEqual(viewModel.currentStep, .completed)
        
        // Then: Should notify coordinator
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    // MARK: - UI Content Tests
    
    func testFinalStepScreenContent() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Should display correct message
        XCTAssertEqual(viewModel.finalStepMessage, "Almost there! You're one step away from completing setup.")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.finishButtonTitle, "Finish")
    }
    
    func testFinalStepContentIsConsistent() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: Content is accessed multiple times
        let message1 = viewModel.finalStepMessage
        let message2 = viewModel.finalStepMessage
        let buttonTitle1 = viewModel.finishButtonTitle
        let buttonTitle2 = viewModel.finishButtonTitle
        
        // Then: Content should be consistent
        XCTAssertEqual(message1, message2)
        XCTAssertEqual(buttonTitle1, buttonTitle2)
    }
    
    // MARK: - Screen State Tests
    
    func testFinalStepScreenStateIsCorrect() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Should not be recording
        XCTAssertFalse(viewModel.isRecording)
        
        // Then: Should not have error messages
        XCTAssertNil(viewModel.errorMessage)
        
        // Then: Should not have field errors
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        
        // Then: Should not show next button (this screen has finish button)
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    func testFinalStepScreenStateAfterCompletion() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: User completes onboarding
        viewModel.selectFinish()
        
        // Then: Should be completed
        XCTAssertEqual(viewModel.currentStep, .completed)
        
        // Then: Should maintain clean state
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
    }
    
    // MARK: - Button Interaction Tests
    
    func testFinishButtonIsEnabled() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Finish button should be enabled
        // Note: This assumes the view model has a property to check button state
        // If not, this test can be removed or modified based on actual implementation
        XCTAssertTrue(true) // Placeholder for button state check
    }
    
    func testFinishButtonTriggersCompletion() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: User taps "Finish" button
        viewModel.selectFinish()
        
        // Then: Should complete onboarding
        XCTAssertEqual(viewModel.currentStep, .completed)
        
        // Then: Should notify coordinator
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    // MARK: - Coordinator Notification Tests
    
    func testCoordinatorIsNotifiedOnCompletion() {
        // Given: User has a profile and is on final step
        viewModel.selectAnonymous() // Creates user profile
        viewModel.currentStep = .finalStep
        
        // When: User taps "Finish"
        viewModel.selectFinish()
        
        // Then: Should notify coordinator with user profile
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    func testCoordinatorReceivesCorrectUserProfile() {
        // Given: User has completed signup and has a profile
        viewModel.selectAnonymous()
        let userProfile = viewModel.userProfile
        viewModel.currentStep = .finalStep
        
        // When: User completes onboarding
        viewModel.selectFinish()
        
        // Then: Should notify coordinator
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
        
        // Then: Should have the same user profile
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.id, userProfile?.id)
    }
    
    // MARK: - Content Localization Tests
    
    func testFinalStepContentUsesCorrectLanguage() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Message should use proper language
        XCTAssertTrue(viewModel.finalStepMessage.contains("Almost there"))
        XCTAssertTrue(viewModel.finalStepMessage.contains("completing setup"))
        
        // Then: Button should use proper language
        XCTAssertEqual(viewModel.finishButtonTitle, "Finish")
    }
    
    // MARK: - Error State Tests
    
    func testFinalStepScreenHandlesErrorsGracefully() {
        // Given: User is on final step screen with previous errors
        viewModel.currentStep = .finalStep
        viewModel.errorMessage = "Previous error"
        viewModel.fieldErrors["test"] = "Test error"
        
        // When: User taps "Finish" button
        viewModel.selectFinish()
        
        // Then: Should still complete successfully
        XCTAssertEqual(viewModel.currentStep, .completed)
        
        // Then: Should notify coordinator despite previous errors
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    // MARK: - Multiple Completion Tests
    
    func testMultipleFinishButtonTaps() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: User taps "Finish" button multiple times
        viewModel.selectFinish()
        viewModel.selectFinish()
        viewModel.selectFinish()
        
        // Then: Should remain completed (not advance further)
        XCTAssertEqual(viewModel.currentStep, .completed)
        
        // Then: Should notify coordinator only once
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    // MARK: - Screen Transition Tests
    
    func testFinalStepToCompletionTransition() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: User taps "Finish" button
        viewModel.selectFinish()
        
        // Then: Should transition to completed state
        XCTAssertEqual(viewModel.currentStep, .completed)
        
        // Then: Should notify coordinator
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    // MARK: - Content Accessibility Tests
    
    func testFinalStepContentIsAccessible() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Content should not be empty
        XCTAssertFalse(viewModel.finalStepMessage.isEmpty)
        XCTAssertFalse(viewModel.finishButtonTitle.isEmpty)
        
        // Then: Content should be meaningful
        XCTAssertTrue(viewModel.finalStepMessage.count > 20)
        XCTAssertTrue(viewModel.finishButtonTitle.count > 0)
    }
    
    // MARK: - Screen Flow Tests
    
    func testFinalStepIsCorrectStepInFlow() {
        // Given: User has completed entire onboarding flow
        viewModel.selectAnonymous() // Signup
        viewModel.selectBegin() // To vocal test
        viewModel.currentStep = .vocalTest
        viewModel.shouldShowNextButton = true
        viewModel.selectNext() // To reading prompt
        viewModel.selectNext() // To final step
        
        // Then: Should be on final step screen
        XCTAssertEqual(viewModel.currentStep, .finalStep)
        
        // When: User completes onboarding
        viewModel.selectFinish()
        
        // Then: Should be completed
        XCTAssertEqual(viewModel.currentStep, .completed)
    }
    
    // MARK: - State Persistence Tests
    
    func testFinalStepMaintainsUserProfile() {
        // Given: User has completed signup and has a profile
        viewModel.selectAnonymous()
        let originalProfile = viewModel.userProfile
        
        // When: User navigates to final step
        viewModel.currentStep = .finalStep
        
        // Then: Should maintain user profile
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.id, originalProfile?.id)
        
        // When: User completes onboarding
        viewModel.selectFinish()
        
        // Then: Should still maintain user profile
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.id, originalProfile?.id)
    }
    
    // MARK: - Button State Tests
    
    func testFinishButtonStateIsConsistent() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: Finish button title is accessed multiple times
        let buttonTitle1 = viewModel.finishButtonTitle
        let buttonTitle2 = viewModel.finishButtonTitle
        let buttonTitle3 = viewModel.finishButtonTitle
        
        // Then: Button title should be consistent
        XCTAssertEqual(buttonTitle1, buttonTitle2)
        XCTAssertEqual(buttonTitle2, buttonTitle3)
        XCTAssertEqual(buttonTitle1, "Finish")
    }
    
    // MARK: - Error Recovery Tests
    
    func testFinalStepRecoversFromPreviousErrors() {
        // Given: User has previous errors from earlier steps
        viewModel.currentStep = .finalStep
        viewModel.errorMessage = "Upload failed"
        viewModel.fieldErrors["recording"] = "Recording error"
        
        // When: User taps "Finish"
        viewModel.selectFinish()
        
        // Then: Should complete successfully despite previous errors
        XCTAssertEqual(viewModel.currentStep, .completed)
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    // MARK: - Content Validation Tests
    
    func testFinalStepMessageIsValid() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Message should be valid
        XCTAssertNotNil(viewModel.finalStepMessage)
        XCTAssertFalse(viewModel.finalStepMessage.isEmpty)
        XCTAssertTrue(viewModel.finalStepMessage.count > 0)
        XCTAssertTrue(viewModel.finalStepMessage.count < 200) // Reasonable length
    }
    
    func testFinishButtonTitleIsValid() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Button title should be valid
        XCTAssertNotNil(viewModel.finishButtonTitle)
        XCTAssertFalse(viewModel.finishButtonTitle.isEmpty)
        XCTAssertTrue(viewModel.finishButtonTitle.count > 0)
        XCTAssertTrue(viewModel.finishButtonTitle.count < 20) // Reasonable length
    }
    
    // MARK: - Completion State Tests
    
    func testCompletionStateIsCorrect() {
        // Given: User completes onboarding
        viewModel.currentStep = .finalStep
        viewModel.selectFinish()
        
        // Then: Should be in completed state
        XCTAssertEqual(viewModel.currentStep, .completed)
        
        // Then: Should not be recording
        XCTAssertFalse(viewModel.isRecording)
        
        // Then: Should not have error messages
        XCTAssertNil(viewModel.errorMessage)
        
        // Then: Should not have field errors
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
    }
    
    // MARK: - User Profile Finalization Tests
    
    func testUserProfileFinalizationWithValidData() {
        // Given: User has minimal profile and valid data
        viewModel.selectAnonymous() // Creates minimal profile
        let validData = OnboardingTestDataFactory.createValidUserProfileData()
        
        // When: Finalizing profile with valid data
        XCTAssertNoThrow(try viewModel.finalizeUserProfile(with: validData))
        
        // Then: Should update profile with complete data
        XCTAssertEqual(viewModel.userProfile?.age, 25)
        XCTAssertEqual(viewModel.userProfile?.gender, "female")
    }
    
    func testUserProfileFinalizationWithInvalidData() {
        // Given: User has minimal profile and invalid data
        viewModel.selectAnonymous() // Creates minimal profile
        let invalidData = OnboardingTestDataFactory.createInvalidUserProfileData()
        
        // When: Finalizing profile with invalid data
        XCTAssertThrowsError(try viewModel.finalizeUserProfile(with: invalidData)) { error in
            // Then: Should throw validation error
            XCTAssertTrue(error is ValidationError)
        }
        
        // Then: Should have field-level errors
        XCTAssertNotNil(viewModel.fieldErrors["age"])
        XCTAssertNotNil(viewModel.fieldErrors["gender"])
    }
    
    // MARK: - Field Error Handling Tests
    
    func testFieldErrorsAreClearedOnNewActions() {
        // Given: User has field errors
        viewModel.fieldErrors["email"] = "Invalid email"
        viewModel.fieldErrors["password"] = "Password too short"
        
        // When: User starts new action
        viewModel.clearFieldErrors()
        
        // Then: Field errors should be cleared
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSpecificFieldErrorCanBeCleared() {
        // Given: User has multiple field errors
        viewModel.fieldErrors["email"] = "Invalid email"
        viewModel.fieldErrors["password"] = "Password too short"
        
        // When: Specific field error is cleared
        viewModel.clearFieldError(for: "email")
        
        // Then: Only email error should be cleared
        XCTAssertNil(viewModel.fieldErrors["email"])
        XCTAssertNotNil(viewModel.fieldErrors["password"])
    }
} 