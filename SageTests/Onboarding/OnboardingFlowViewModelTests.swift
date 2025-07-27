//
//  OnboardingFlowViewModelTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Tests onboarding flow steps and validation
//
//  GWT (Given-When-Then) Structure:
//  - Given: Sets up the initial state (including previous user choices)
//  - When: The specific action being tested
//  - Then: Verifies the expected outcome
//
//  UI Flow:
//  1. Welcome Screen: "Get Started" vs "I already have an account"
//  2. Create Account Screen: Email/Password vs "Continue Anonymously"
//  3. Profile Creation: User info form
//  4. Completion: Onboarding complete

import XCTest
import Mixpanel
@testable import Sage

@MainActor
class OnboardingFlowViewModelTests: XCTestCase {
    private var harness: OnboardingTestHarness!
    
    override func setUp() {
        super.setUp()
        harness = OnboardingTestHarness()
    }
    
    override func tearDown() {
        harness.resetAllMocks()
        harness = nil
        super.tearDown()
    }
    
    func createViewModel() -> OnboardingFlowViewModel {
        return OnboardingFlowViewModel(
            coordinator: harness.mockCoordinator,
            userProfileRepository: harness.mockUserProfileRepository,
            analyticsService: harness.mockAnalyticsService,
            authService: harness.mockAuthService
        )
    }
    
    // MARK: - Welcome Screen Tests
    
    func testInitialState() {
        // Given: OnboardingFlowViewModel is created
        let viewModel = createViewModel()
        
        // Then: Should have default values
        XCTAssertEqual(viewModel.currentStep, .signupMethod)
        XCTAssertNil(viewModel.selectedSignupMethod)
        XCTAssertNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfileData, UserProfileData())
        XCTAssertTrue(viewModel.validationErrors.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.operationInProgress)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testUserSelectsGetStarted() {
        // Given: User is on signup method screen
        let viewModel = createViewModel()
        
        // When: User selects "Get Started"
        viewModel.selectGetStarted()
        
        // Then: Should navigate to signup method selection
        XCTAssertEqual(viewModel.currentStep, .signupMethod)
        XCTAssertFalse(harness.mockCoordinator.didTransitionToLogin)
    }
    
    func testUserSelectsIAlreadyHaveAccount() {
        // Given: User is on signup method screen
        let viewModel = createViewModel()
        
        // When: User selects "I already have an account"
        viewModel.selectIAlreadyHaveAccount()
        
        // Then: Should transition to login flow (not continue onboarding)
        XCTAssertTrue(harness.mockCoordinator.didTransitionToLogin)
        XCTAssertEqual(viewModel.currentStep, .signupMethod) // Stays on signup method since we're transitioning out
    }
    
    // MARK: - Create Account Screen Tests
    
    func testUserSelectsContinueAnonymously() async {
        // Given: User is on signup method screen
        let viewModel = createViewModel()
        
        // When: User selects "Continue Anonymously"
        viewModel.selectAnonymous()
        
        // Then: Should stay on signup method screen (async operation)
        XCTAssertEqual(viewModel.currentStep, .signupMethod)
        // Note: isAnonymous is set during the async operation
    }
    
    func testUserSelectsEmailSignup() async {
        // Given: User is on signup method screen
        let viewModel = createViewModel()
        
        // When: User selects email signup (enters email/password and taps "Sign Up")
        viewModel.selectEmail()
        
        // Then: Should stay on signup method screen (async operation)
        XCTAssertEqual(viewModel.currentStep, .signupMethod)
        // Note: isAnonymous is set during the async operation
    }
    
    // MARK: - Profile Creation Tests
    
    func testUserCompletesProfileWithValidData() async {
        // Given: User is on signup method screen
        let viewModel = createViewModel()
        
        // When: User selects anonymous signup and completes profile
        await viewModel.selectSignupMethod(.anonymous)
        viewModel.userInfo = UserInfo(name: "Test User", age: 25, gender: "female")
        viewModel.completeUserInfo()
        
        // Then: Should complete onboarding successfully
        XCTAssertEqual(viewModel.currentStep, .completed)
        XCTAssertTrue(harness.mockCoordinator.didComplete)
        XCTAssertNotNil(harness.mockCoordinator.capturedProfile)
    }
    
    func testUserCompletesProfileWithInvalidData() {
        // Given: User is on signup method screen with invalid data
        let viewModel = createViewModel()
        viewModel.selectAnonymous()
        viewModel.userInfo = UserInfo(name: "", age: 0, gender: "")
        
        // When: User attempts to complete with invalid info
        viewModel.completeUserInfo()
        
        // Then: Should show validation errors and not complete
        XCTAssertFalse(viewModel.validationErrors.isEmpty)
        XCTAssertNotEqual(viewModel.currentStep, .completed)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateTransitionsDuringSignupMethodSelection() async {
        // Given: User is on Create Account screen
        let viewModel = createViewModel()
        viewModel.selectGetStarted()
        
        // When: User selects signup method (async operation)
        let result = await viewModel.selectSignupMethod(.anonymous)
        
        // Then: Should complete successfully and reset loading states
        XCTAssertEqual(result, .created)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.operationInProgress)
        XCTAssertNil(viewModel.errorMessage)
    }
} 