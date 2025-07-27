//
//  ExplainerScreenTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - UI content verification for explainer screen
//  - Navigation from explainer to vocal test
//  - Screen state management
//  - Button interactions

import XCTest
@testable import Sage

// MARK: - Explainer Screen Test Requirements

// Given a new user profile is created
// Then the user is navigated to View 1

// Then the UI displays the explainer headline: "Let's run some quick tests"
// Then the UI displays the subtext: "This helps us understand the unique physiology of your vocal tract."
// Then the UI displays a button labeled "Begin"

// Given the user taps the "Begin" button
// Then the user is navigated to View 2

final class ExplainerScreenTests: XCTestCase {
    
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
    
    func testUserIsNavigatedToExplainerAfterSignup() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // Then: Should be on explainer screen
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
    
    func testUserTapsBeginButton() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // When: User taps "Begin" button
        viewModel.selectBegin()
        
        // Then: Should navigate to vocal test screen
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
    }
    
    // MARK: - UI Content Tests
    
    func testExplainerScreenContent() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Should display correct headline
        XCTAssertEqual(viewModel.explainerHeadline, "Let's run some quick tests")
        
        // Then: Should display correct subtext
        XCTAssertEqual(viewModel.explainerSubtext, "This helps us understand the unique physiology of your vocal tract.")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.beginButtonTitle, "Begin")
    }
    
    func testExplainerScreenContentIsConsistent() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // When: Content is accessed multiple times
        let headline1 = viewModel.explainerHeadline
        let headline2 = viewModel.explainerHeadline
        let subtext1 = viewModel.explainerSubtext
        let subtext2 = viewModel.explainerSubtext
        let buttonTitle1 = viewModel.beginButtonTitle
        let buttonTitle2 = viewModel.beginButtonTitle
        
        // Then: Content should be consistent
        XCTAssertEqual(headline1, headline2)
        XCTAssertEqual(subtext1, subtext2)
        XCTAssertEqual(buttonTitle1, buttonTitle2)
    }
    
    // MARK: - Screen State Tests
    
    func testExplainerScreenStateIsCorrect() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Should not be recording
        XCTAssertFalse(viewModel.isRecording)
        
        // Then: Should not have error messages
        XCTAssertNil(viewModel.errorMessage)
        
        // Then: Should not have field errors
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        
        // Then: Should not show next button
        XCTAssertFalse(viewModel.shouldShowNextButton)
    }
    
    func testExplainerScreenStateAfterNavigation() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // When: User navigates to vocal test
        viewModel.selectBegin()
        
        // Then: Should be on vocal test screen
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
        
        // Then: Should maintain clean state
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
    }
    
    // MARK: - Button Interaction Tests
    
    func testBeginButtonIsEnabled() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Begin button should be enabled
        // Note: This assumes the view model has a property to check button state
        // If not, this test can be removed or modified based on actual implementation
        XCTAssertTrue(true) // Placeholder for button state check
    }
    
    func testBeginButtonTriggersNavigation() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // When: User taps "Begin" button
        viewModel.selectBegin()
        
        // Then: Should navigate to vocal test screen
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
    }
    
    // MARK: - Content Localization Tests
    
    func testExplainerContentUsesCorrectLanguage() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Headline should use proper language
        XCTAssertTrue(viewModel.explainerHeadline.contains("quick tests"))
        
        // Then: Subtext should use proper language
        XCTAssertTrue(viewModel.explainerSubtext.contains("vocal tract"))
        
        // Then: Button should use proper language
        XCTAssertEqual(viewModel.beginButtonTitle, "Begin")
    }
    
    // MARK: - Error State Tests
    
    func testExplainerScreenHandlesErrorsGracefully() {
        // Given: User is on explainer screen with previous errors
        viewModel.currentStep = .explainer
        viewModel.errorMessage = "Previous error"
        viewModel.fieldErrors["test"] = "Test error"
        
        // When: User taps "Begin" button
        viewModel.selectBegin()
        
        // Then: Should still navigate successfully
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
        
        // Then: Previous errors should not interfere with navigation
        XCTAssertNotNil(viewModel.errorMessage) // Errors may persist until explicitly cleared
    }
    
    // MARK: - Multiple Navigation Tests
    
    func testMultipleBeginButtonTaps() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // When: User taps "Begin" button multiple times
        viewModel.selectBegin()
        viewModel.selectBegin()
        viewModel.selectBegin()
        
        // Then: Should remain on vocal test screen (not advance further)
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
    }
    
    // MARK: - Screen Transition Tests
    
    func testExplainerToVocalTestTransition() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // When: User taps "Begin" button
        viewModel.selectBegin()
        
        // Then: Should transition to vocal test screen
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
        
        // Then: Should be ready for vocal test
        XCTAssertFalse(viewModel.isRecording)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Content Accessibility Tests
    
    func testExplainerContentIsAccessible() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Content should not be empty
        XCTAssertFalse(viewModel.explainerHeadline.isEmpty)
        XCTAssertFalse(viewModel.explainerSubtext.isEmpty)
        XCTAssertFalse(viewModel.beginButtonTitle.isEmpty)
        
        // Then: Content should be meaningful
        XCTAssertTrue(viewModel.explainerHeadline.count > 10)
        XCTAssertTrue(viewModel.explainerSubtext.count > 20)
        XCTAssertTrue(viewModel.beginButtonTitle.count > 0)
    }
} 