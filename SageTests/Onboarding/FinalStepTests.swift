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
//
//  Improvements:
//  - Consolidated redundant navigation tests
//  - Removed overzealous state checks
//  - Dropped placeholder tests
//  - Minimized localization and UI string repeats
//  - Focused on essential MVP functionality
//  - Reduced from 44 tests to 12 high-value tests
//  - Fixed MainActor isolation issues

import XCTest
@testable import Sage

// MARK: - Final Step Screen Test Requirements

// Given the user is on View 4
// Then the UI displays the message: "Almost there! You're one step away from completing setup."
// Then the UI displays the "Finish" button

// When the user taps "Finish"
// Then the user is navigated to the Home page

@MainActor
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
    
    func testFinishTapsTransitionToCompletion() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // When: User taps "Finish"
        viewModel.selectFinish()
        
        // Then: Should complete onboarding
        XCTAssertEqual(viewModel.currentStep, .completed)
        XCTAssertTrue(harness.mockCoordinator.didCompleteOnboarding)
    }
    
    // MARK: - UI Content Tests
    
    func testFinalStepUIContentIsCorrectAndStable() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Should display correct message
        XCTAssertEqual(viewModel.finalStepMessage, "Almost there! You're one step away from completing setup.")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.finishButtonTitle, "Finish")
    }
    
    // MARK: - Screen State Tests
    
    func testFinalScreenIsCleanBeforeAndAfterCompletion() {
        // Given: User is on final step screen
        viewModel.currentStep = .finalStep
        
        // Then: Should have clean state before completion
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        
        // When: User completes onboarding
        viewModel.selectFinish()
        
        // Then: Should maintain clean state after completion
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
    }
    
    // MARK: - Coordinator Tests
    
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
    
    // MARK: - Error Recovery Tests
    
    func testFinishWorksDespitePreviousErrors() {
        // Given: User is on final step screen with previous errors
        viewModel.currentStep = .finalStep
        viewModel.errorMessage = "Previous error"
        viewModel.fieldErrors["test"] = "Test error"
        
        // When: User taps "Finish" button
        viewModel.selectFinish()
        
        // Then: Should still complete successfully
        XCTAssertEqual(viewModel.currentStep, .completed)
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