//
//  OnboardingFlowViewModelTests.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Unit tests for OnboardingFlowViewModel using TDD principles
//  Tests onboarding flow steps and validation

import Testing
@testable import Sage

struct OnboardingFlowViewModelTests {
    
@Test func shouldTriggerOnboardingFlow_whenAnonymousSignup() async throws {
    // Given: User is on authentication screen
    let viewModel = AuthViewModel()
    // When: User selects sign up and chooses anonymous
    viewModel.signInAnonymously()
    // Then: Onboarding flow is triggered (user becomes authenticated)
    #expect(viewModel.isAuthenticated == true)
    #expect(viewModel.signUpMethod == "anonymous")
}
    
    @Test func shouldNavigateToSignupMethod_whenSignupSelected() async throws {
        // Given: Onboarding flow at initial step
        let viewModel = OnboardingFlowViewModel()
        let mockCoordinator = MockOnboardingCoordinator()
        viewModel.coordinator = mockCoordinator
        
        // When: User selects signup
        viewModel.selectSignup()
        
        // Then: Should navigate to signup method selection
        #expect(viewModel.step == .signupMethod)
    }
    
    @Test func shouldNavigateToUserInfoForm_whenAnonymousSelected() async throws {
        // Given: Onboarding flow at signup method step
        let viewModel = OnboardingFlowViewModel()
        let mockCoordinator = MockOnboardingCoordinator()
        viewModel.coordinator = mockCoordinator
        viewModel.selectSignup()
        
        // When: User selects anonymous signup
        viewModel.selectAnonymous()
        
        // Then: Should navigate to user info form
        #expect(viewModel.step == .userInfoForm)
        #expect(viewModel.isAnonymous == true)
    }
    
    @Test func shouldNavigateToUserInfoForm_whenEmailSelected() async throws {
        // Given: Onboarding flow at signup method step
        let viewModel = OnboardingFlowViewModel()
        let mockCoordinator = MockOnboardingCoordinator()
        viewModel.coordinator = mockCoordinator
        viewModel.selectSignup()
        
        // When: User selects email signup
        viewModel.selectEmail()
        
        // Then: Should navigate to user info form
        #expect(viewModel.step == .userInfoForm)
        #expect(viewModel.isAnonymous == false)
    }
    
    @Test func shouldShowError_whenUserInfoInvalid() async throws {
        // Given: Onboarding flow at user info form with invalid data
        let viewModel = OnboardingFlowViewModel()
        let mockCoordinator = MockOnboardingCoordinator()
        viewModel.coordinator = mockCoordinator
        viewModel.selectSignup()
        viewModel.selectAnonymous()
        viewModel.userInfo = UserInfo(name: "", age: 0, gender: "")
        
        // When: User attempts to complete with invalid info
        viewModel.completeUserInfo()
        
        // Then: Should show error and not complete
        #expect(viewModel.errorMessage != nil)
        #expect(mockCoordinator.didComplete == false)
        #expect(viewModel.step != .completed)
    }
    
    @Test func shouldCompleteOnboarding_whenUserInfoValid() async throws {
        // Given: Onboarding flow at user info form with valid data
        let viewModel = OnboardingFlowViewModel()
        let mockCoordinator = MockOnboardingCoordinator()
        viewModel.coordinator = mockCoordinator
        viewModel.selectSignup()
        viewModel.selectAnonymous()
        viewModel.userInfo = UserInfo(name: "Test User", age: 30, gender: "female")
        
        // When: User completes with valid info
        viewModel.completeUserInfo()
        
        // Then: Should complete onboarding and notify coordinator
        #expect(viewModel.step == .completed)
        #expect(mockCoordinator.didComplete == true)
        #expect(mockCoordinator.capturedProfile?.age == 30)
        #expect(mockCoordinator.capturedProfile?.gender == "female")
        #expect(mockCoordinator.capturedProfile?.id.count > 0)
    }
    
    @Test func shouldHandleLoginSelection() async throws {
        // Given: Onboarding flow at initial step
        let viewModel = OnboardingFlowViewModel()
        let mockCoordinator = MockOnboardingCoordinator()
        viewModel.coordinator = mockCoordinator
        
        // When: User selects login
        viewModel.selectLogin()
        
        // Then: Should navigate to user info form (treating as anonymous)
        #expect(viewModel.step == .userInfoForm)
        #expect(viewModel.isAnonymous == true)
    }
} 