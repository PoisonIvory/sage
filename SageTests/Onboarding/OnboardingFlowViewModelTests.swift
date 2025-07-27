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
    var mockCoordinator: MockOnboardingCoordinator!
    var mockUserProfileRepository: MockUserProfileRepository!
    var mockAnalyticsService: MockAnalyticsService!
    var mockAuthService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockCoordinator = MockOnboardingCoordinator()
        mockUserProfileRepository = MockUserProfileRepository()
        mockAnalyticsService = MockAnalyticsService()
        mockAuthService = MockAuthService()
    }
    
    override func tearDown() {
        mockCoordinator?.reset()
        mockCoordinator = nil
        mockUserProfileRepository = nil
        mockAnalyticsService = nil
        mockAuthService = nil
        super.tearDown()
    }
    
    func createViewModel() -> OnboardingFlowViewModel {
        return OnboardingFlowViewModel(
            coordinator: mockCoordinator,
            userProfileRepository: mockUserProfileRepository,
            analyticsService: mockAnalyticsService,
            authService: mockAuthService
        )
    }
    
    // MARK: - Welcome Screen Tests
    
    func testInitialState() {
        // Given: OnboardingFlowViewModel is created
        let viewModel = createViewModel()
        
        // Then: Should have default values
        XCTAssertEqual(viewModel.currentStep, .welcome)
        XCTAssertNil(viewModel.selectedSignupMethod)
        XCTAssertNil(viewModel.userProfile)
        XCTAssertEqual(viewModel.userProfileData, UserProfileData())
        XCTAssertTrue(viewModel.validationErrors.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.operationInProgress)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testUserSelectsGetStarted() {
        // Given: User is on welcome screen
        let viewModel = createViewModel()
        
        // When: User selects "Get Started"
        viewModel.selectGetStarted()
        
        // Then: Should navigate to signup method selection (Create Account screen)
        XCTAssertEqual(viewModel.currentStep, .signupMethod)
        XCTAssertFalse(mockCoordinator.didTransitionToLogin)
    }
    
    func testUserSelectsIAlreadyHaveAccount() {
        // Given: User is on welcome screen
        let viewModel = createViewModel()
        
        // When: User selects "I already have an account"
        viewModel.selectIAlreadyHaveAccount()
        
        // Then: Should transition to login flow (not continue onboarding)
        XCTAssertTrue(mockCoordinator.didTransitionToLogin)
        XCTAssertEqual(viewModel.currentStep, .welcome) // Stays on welcome since we're transitioning out
    }
    
    // MARK: - Create Account Screen Tests
    
    func testUserSelectsContinueAnonymously() async {
        // Given: User is on Create Account screen (after selecting "Get Started")
        let viewModel = createViewModel()
        viewModel.selectGetStarted()
        
        // When: User selects "Continue Anonymously"
        viewModel.selectAnonymous()
        
        // Then: Should navigate to user profile creation (async operation)
        // Wait a moment for the async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(viewModel.currentStep, .userProfileCreation)
        XCTAssertTrue(viewModel.isAnonymous)
    }
    
    func testUserSelectsEmailSignup() async {
        // Given: User is on Create Account screen (after selecting "Get Started")
        let viewModel = createViewModel()
        viewModel.selectGetStarted()
        
        // When: User selects email signup (enters email/password and taps "Sign Up")
        viewModel.selectEmail()
        
        // Then: Should navigate to user profile creation (async operation)
        // Wait a moment for the async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(viewModel.currentStep, .userProfileCreation)
        XCTAssertFalse(viewModel.isAnonymous)
    }
    
    // MARK: - Profile Creation Tests
    
    func testUserCompletesProfileWithValidData() async {
        // Given: User is on user profile creation (after selecting signup method)
        let viewModel = createViewModel()
        viewModel.selectGetStarted()
        viewModel.selectAnonymous()
        
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Set valid user info
        viewModel.userInfo = UserInfo(name: "Test User", age: 25, gender: "female")
        
        // When: User completes profile with valid data
        viewModel.completeUserInfo()
        
        // Then: Should complete onboarding successfully
        XCTAssertEqual(viewModel.currentStep, .completed)
        XCTAssertTrue(mockCoordinator.didComplete)
        XCTAssertNotNil(mockCoordinator.capturedProfile)
    }
    
    func testUserCompletesProfileWithInvalidData() {
        // Given: User is on user info form with invalid data
        let viewModel = createViewModel()
        viewModel.selectGetStarted()
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

// MARK: - Mock Classes for Testing
class MockUserProfileRepository: UserProfileRepositoryProtocol {
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void) {
        completion(nil) // Return nil for testing
    }
}

class MockAnalyticsService: AnalyticsServiceProtocol {
    func track(_ name: String, properties: [String: MixpanelType]?, origin: String?) {
        print("MockAnalyticsService: Tracked event '\(name)' with properties: \(properties ?? [:])")
    }
}

class MockAuthService: AuthServiceProtocol {
    var currentUserId: String? {
        return "test-user-id"
    }
} 