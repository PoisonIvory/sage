//
//  SignupFlowTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Test Focus Areas:
//  - Anonymous vs email signup flows
//  - Firebase auth success/failure scenarios
//  - Analytics tracking for signup events
//  - Error handling for common signup failures
//  - Navigation from signup method selection to explainer
//
//  MVP Testing Strategy:
//  - Focus on critical user flows and crash prevention
//  - Test ViewModel logic and data validation
//  - Verify coordinator transitions and analytics integration
//  - Remove UI text, localization, and redundant state tests

import XCTest
import Mixpanel
@testable import Sage

// MARK: - Signup Flow Test Requirements

// Given a new user
// When they tap "Get Started"
// Then the UI presents an option for anonymous signup
// Then the UI presents an option for email/password signup

// Given the user selects "Continue Anonymously"
// Then a new anonymous user profile is created
// Then the Mixpanel event "onboarding_signup_method_selected" is tracked with value "anonymous"
// Then the Mixpanel event "onboarding_started" is tracked
// Then the user is navigated to View 1

// Given the user selects email/password signup
// When they input a valid email and password
// Then a new email user profile is created
// Then the Mixpanel event "onboarding_signup_method_selected" is tracked with value "email"
// Then the Mixpanel event "onboarding_started" is tracked
// Then the user is navigated to View 1

// Given the user inputs an email that already exists
// Then Firebase returns auth/email-already-in-use
// Then the app displays: "This email is already registered. Try signing in instead."

// Given the user attempts signup without internet
// Then Firebase returns auth/network-request-failed
// Then the app displays: "Check your internet connection and try again."

@MainActor
final class SignupFlowTests: XCTestCase {
    
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
    
    // MARK: - Critical User Flow Tests
    
    func testAnonymousSignupFlow() {
        // Given: User is on signup method selection screen
        viewModel.currentStep = .signupMethod
        
        // When: User selects "Continue Anonymously"
        viewModel.selectAnonymous()
        
        // Then: Should create anonymous user profile and navigate
        XCTAssertEqual(viewModel.selectedSignupMethod, .anonymous)
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
    
    func testEmailSignupFlow() {
        // Given: User provides valid email credentials
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should create email user profile and navigate
        XCTAssertEqual(viewModel.selectedSignupMethod, .email)
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
    
    // MARK: - ViewModel Logic Tests
    
    func testSignupMethodSelection() {
        // Given: User is on signup method selection screen
        viewModel.currentStep = .signupMethod
        
        // When: User selects "Get Started"
        viewModel.selectGetStarted()
        
        // Then: Should navigate to explainer screen
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
    
    // MARK: - Analytics Integration Tests
    
    func testAnalyticsEventsAreTracked() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_signup_method_selected"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_started"))
    }
    
    // MARK: - Error Handling Tests
    
    func testSignupErrorHandling() {
        // Given: Signup fails due to network error
        harness.mockAuthService.shouldReturnError = true
        harness.mockAuthService.errorType = .networkRequestFailed
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should handle error gracefully
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.userProfile)
    }
    
    // MARK: - Crash Prevention Tests
    
    func testInvalidCredentialsHandling() {
        // Given: User provides invalid credentials
        harness.mockAuthService.shouldReturnError = true
        harness.mockAuthService.errorType = .invalidCredentials
        viewModel.email = "invalid-email"
        viewModel.password = "123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should handle without crashing
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.userProfile)
    }
} 