//
//  OnboardingMocks.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Mock objects for onboarding testing
//  Provides fake coordinator objects for unit testing

import Foundation

// MARK: - Mock Onboarding Coordinator
final class MockOnboardingCoordinator: OnboardingFlowCoordinating {
    var didComplete = false
    var capturedProfile: UserProfile? = nil
    
    func onboardingDidComplete(userProfile: UserProfile) {
        didComplete = true
        capturedProfile = userProfile
    }
    
    func reset() {
        didComplete = false
        capturedProfile = nil
    }
} 