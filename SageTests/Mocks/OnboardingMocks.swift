//
//  OnboardingMocks.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Mock objects for onboarding testing
//  Provides fake coordinator objects for unit testing

import Foundation
@testable import Sage

// MARK: - Mock Onboarding Coordinator
final class MockOnboardingCoordinator: OnboardingFlowCoordinating {
    var didComplete = false
    var capturedProfile: UserProfile? = nil
    var didTransitionToLogin = false
    
    func onboardingDidComplete(userProfile: UserProfile) {
        didComplete = true
        capturedProfile = userProfile
    }
    
    func transitionToLogin() {
        didTransitionToLogin = true
        print("MockOnboardingCoordinator: transitionToLogin called")
    }
    
    func reset() {
        didComplete = false
        capturedProfile = nil
        didTransitionToLogin = false
    }
} 