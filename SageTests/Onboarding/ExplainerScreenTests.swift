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
//
//  Improvements:
//  - Consolidated redundant navigation tests
//  - Merged string consistency and validation tests
//  - Limited localization key tests to essential checks
//  - Removed overzealous state checks
//  - Removed flow tests (should be in dedicated onboarding flow test)

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

@MainActor
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
    
    func testNavigationFromExplainerToVocalTest() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // When: User taps "Begin" button
        viewModel.selectBegin()
        
        // Then: Should navigate to vocal test screen
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
    }
    
    // MARK: - UI Content Tests
    
    func testExplainerUIContentIsValid() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Should display correct headline
        XCTAssertEqual(viewModel.explainerHeadline, "Let's run some quick tests")
        
        // Then: Should display correct subtext
        XCTAssertEqual(viewModel.explainerSubtext, "This helps us understand the unique physiology of your vocal tract.")
        
        // Then: Should display correct button title
        XCTAssertEqual(viewModel.beginButtonTitle, "Begin")
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
    
    // MARK: - Button Interaction Tests
    
    func testBeginButtonIsEnabled() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Begin button should be enabled and functional
        let initialStep = viewModel.currentStep
        
        // When: User taps "Begin" button
        viewModel.selectBegin()
        
        // Then: Should navigate successfully, indicating button is enabled
        XCTAssertNotEqual(viewModel.currentStep, initialStep)
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
    }
    
    // MARK: - Localization Key Tests
    
    func testLocalizedStringsAreHumanReadable() {
        // Given: User is on explainer screen
        viewModel.currentStep = .explainer
        
        // Then: Content should not contain localization keys
        XCTAssertFalse(viewModel.explainerHeadline.contains("_"))
        XCTAssertFalse(viewModel.explainerSubtext.contains("_"))
        XCTAssertFalse(viewModel.beginButtonTitle.contains("_"))
        
        // Then: Content should be human-readable text, not keys
        XCTAssertTrue(viewModel.explainerHeadline.count > 10) // Meaningful text length
        XCTAssertTrue(viewModel.explainerSubtext.count > 20) // Meaningful text length
        XCTAssertTrue(viewModel.beginButtonTitle.count > 0) // Non-empty button text
    }
    
    // MARK: - Error State Tests
    
    func testErrorsDoNotBlockNavigation() {
        // Given: User is on explainer screen with previous errors
        viewModel.currentStep = .explainer
        viewModel.errorMessage = "Previous error"
        viewModel.fieldErrors["test"] = "Test error"
        
        // When: User taps "Begin" button
        viewModel.selectBegin()
        
        // Then: Should still navigate successfully
        XCTAssertEqual(viewModel.currentStep, .vocalTest)
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