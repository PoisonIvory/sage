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
    
    // MARK: - Navigation Tests
    
    func testUserSelectsGetStarted() {
        // Given: User is on signup method selection screen
        viewModel.currentStep = .signupMethod
        
        // When: User selects "Get Started"
        viewModel.selectGetStarted()
        
        // Then: Should navigate to explainer screen
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
    
    // MARK: - Anonymous Signup Tests
    
    func testUserSelectsContinueAnonymously() {
        // Given: User is on signup method selection screen
        viewModel.currentStep = .signupMethod
        
        // When: User selects "Continue Anonymously"
        viewModel.selectAnonymous()
        
        // Then: Should create anonymous user profile
        XCTAssertEqual(viewModel.selectedSignupMethod, .anonymous)
        XCTAssertNotNil(viewModel.userProfile)
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_signup_method_selected"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_started"))
        
        // Then: Should track with correct metadata
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMethod("onboarding_signup_method_selected", expectedMethod: "anonymous"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_signup_method_selected", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_started", expectedUserID: "test-user-id"))
        
        // Then: Should navigate to explainer screen
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
    
    func testAnonymousSignupCreatesMinimalProfile() {
        // Given: User is on signup method selection screen
        viewModel.currentStep = .signupMethod
        
        // When: User selects "Continue Anonymously"
        viewModel.selectAnonymous()
        
        // Then: Should create minimal profile with required fields
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.id, "test-user-id")
        XCTAssertEqual(viewModel.userProfile?.deviceModel, "Test Device")
        XCTAssertEqual(viewModel.userProfile?.osVersion, "Test OS")
        XCTAssertNotNil(viewModel.userProfile?.createdAt)
        
        // Then: Should not have age or gender (minimal profile)
        XCTAssertNil(viewModel.userProfile?.age)
        XCTAssertNil(viewModel.userProfile?.gender)
    }
    
    // MARK: - Email Signup Tests
    
    func testUserSelectsEmailSignup() {
        // Given: User is on signup method selection screen with valid credentials
        viewModel.currentStep = .signupMethod
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should create email user profile
        XCTAssertEqual(viewModel.selectedSignupMethod, .email)
        XCTAssertNotNil(viewModel.userProfile)
        
        // Then: Should track analytics events
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_signup_method_selected"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_started"))
        
        // Then: Should track with correct metadata
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMethod("onboarding_signup_method_selected", expectedMethod: "email"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_signup_method_selected", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_started", expectedUserID: "test-user-id"))
        
        // Then: Should navigate to explainer screen
        XCTAssertEqual(viewModel.currentStep, .explainer)
    }
    
    func testEmailSignupWithValidCredentials() {
        // Given: User provides valid email and password
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should create profile successfully
        XCTAssertNotNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfile?.id, "test-user-id")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
    }
    
    // MARK: - Email Signup Error Tests
    
    func testEmailAlreadyExistsError() {
        // Given: User attempts email signup with existing email
        harness.mockAuthService.shouldReturnError = true
        harness.mockAuthService.errorType = .emailAlreadyInUse
        viewModel.email = "existing@example.com"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should display error message
        XCTAssertEqual(viewModel.errorMessage, "This email is already registered. Try signing in instead.")
        XCTAssertNil(viewModel.userProfile)
    }
    
    func testNetworkErrorDuringSignup() {
        // Given: User attempts signup without internet
        harness.mockAuthService.shouldReturnError = true
        harness.mockAuthService.errorType = .networkRequestFailed
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should display error message
        XCTAssertEqual(viewModel.errorMessage, "Check your internet connection and try again.")
        XCTAssertNil(viewModel.userProfile)
    }
    
    func testInvalidEmailFormatError() {
        // Given: User provides invalid email format
        harness.mockAuthService.shouldReturnError = true
        harness.mockAuthService.errorType = .invalidCredentials
        viewModel.email = "invalid-email"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should display error message
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.userProfile)
    }
    
    func testWeakPasswordError() {
        // Given: User provides weak password
        harness.mockAuthService.shouldReturnError = true
        harness.mockAuthService.errorType = .invalidCredentials
        viewModel.email = "test@example.com"
        viewModel.password = "123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should display error message
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.userProfile)
    }
    
    // MARK: - Analytics Tracking Tests
    
    func testAnalyticsEventsIncludeRequiredMetadata() {
        // Given: User has completed signup
        viewModel.selectAnonymous()
        
        // When: Analytics events are tracked
        // (Events are tracked automatically during signup)
        
        // Then: Should have tracked events with proper metadata
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_signup_method_selected"))
        XCTAssertTrue(harness.mockAnalyticsService.trackedEvents.contains("onboarding_started"))
        
        // Verify analytics service was called with proper properties
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_signup_method_selected", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_started", expectedUserID: "test-user-id"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMethod("onboarding_signup_method_selected", expectedMethod: "anonymous"))
    }
    
    func testEmailSignupAnalyticsIncludeCorrectMethod() {
        // Given: User provides valid email credentials
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should track with email method
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsMethod("onboarding_signup_method_selected", expectedMethod: "email"))
        XCTAssertTrue(harness.mockAnalyticsService.assertEventContainsUserID("onboarding_signup_method_selected", expectedUserID: "test-user-id"))
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessagesAreClearedOnNewSignupAttempt() {
        // Given: User has an error from previous attempt
        harness.mockAuthService.shouldReturnError = true
        harness.mockAuthService.errorType = .emailAlreadyInUse
        viewModel.email = "existing@example.com"
        viewModel.password = "password123"
        viewModel.selectEmail()
        
        // Verify error exists
        XCTAssertNotNil(viewModel.errorMessage)
        
        // When: User tries again with valid credentials
        harness.mockAuthService.shouldReturnError = false
        viewModel.email = "new@example.com"
        viewModel.password = "password123"
        viewModel.selectEmail()
        
        // Then: Error should be cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNotNil(viewModel.userProfile)
    }
    
    func testFieldErrorsAreClearedOnSuccessfulSignup() {
        // Given: User has field errors
        viewModel.fieldErrors["email"] = "Invalid email"
        viewModel.fieldErrors["password"] = "Password too short"
        
        // When: User successfully signs up
        viewModel.selectAnonymous()
        
        // Then: Field errors should be cleared
        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    // MARK: - Profile Creation Tests
    
    func testAnonymousProfileHasCorrectCreationDate() {
        // Given: User selects anonymous signup
        let customDateProvider = OnboardingTestDataFactory.createMockDateProvider()
        let customViewModel = harness.makeViewModelWithCustomDateProvider(customDateProvider)
        customViewModel.currentStep = .signupMethod
        
        // When: User selects "Continue Anonymously"
        customViewModel.selectAnonymous()
        
        // Then: Profile should have consistent date formatting
        XCTAssertNotNil(customViewModel.userProfile?.createdAt)
        XCTAssertTrue(customViewModel.userProfile!.createdAt.contains("1970-01-15"))
    }
    
    func testEmailProfileHasCorrectCreationDate() {
        // Given: User provides valid email credentials
        let customDateProvider = OnboardingTestDataFactory.createMockDateProvider()
        let customViewModel = harness.makeViewModelWithCustomDateProvider(customDateProvider)
        customViewModel.currentStep = .signupMethod
        customViewModel.email = "test@example.com"
        customViewModel.password = "password123"
        
        // When: User selects email signup
        customViewModel.selectEmail()
        
        // Then: Profile should have consistent date formatting
        XCTAssertNotNil(customViewModel.userProfile?.createdAt)
        XCTAssertTrue(customViewModel.userProfile!.createdAt.contains("1970-01-15"))
    }
} 