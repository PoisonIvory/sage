//
//  OnboardingError.swift
//  Sage
//
//  Onboarding domain errors
//  Reference: DATA_STANDARDS.md §3.4, CONTRIBUTING.md
//

import Foundation

// MARK: - Onboarding Domain Errors
enum OnboardingError: DomainError, CaseIterable {
    case invalidUserInfo
    case onboardingRecordingFailed
    case onboardingUploadFailed
    case onboardingAnalysisFailed
    case unknown
    
    var errorCode: String {
        switch self {
        case .invalidUserInfo: return "ONBOARD_001"
        case .onboardingRecordingFailed: return "ONBOARD_002"
        case .onboardingUploadFailed: return "ONBOARD_003"
        case .onboardingAnalysisFailed: return "ONBOARD_004"
        case .unknown: return "ONBOARD_999"
        }
    }
    
    var userMessage: String {
        switch self {
        case .invalidUserInfo: return "Please provide valid information"
        case .onboardingRecordingFailed: return "Unable to record voice sample"
        case .onboardingUploadFailed: return "Unable to upload voice sample"
        case .onboardingAnalysisFailed: return "Unable to analyze voice sample"
        case .unknown: return "Onboarding failed"
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .invalidUserInfo: return "User information validation failed"
        case .onboardingRecordingFailed: return "Voice recording failed during onboarding"
        case .onboardingUploadFailed: return "Voice sample upload failed"
        case .onboardingAnalysisFailed: return "Voice analysis failed during onboarding"
        case .unknown: return "Unknown onboarding error"
        }
    }
    
    var retryBehavior: RetryBehavior {
        switch self {
        case .invalidUserInfo: return .afterUserAction(actionHint: "Correct user information")
        case .onboardingRecordingFailed: return .immediately
        case .onboardingUploadFailed: return .after(delay: 2.0)
        case .onboardingAnalysisFailed: return .after(delay: 3.0)
        case .unknown: return .never
        }
    }
}

// MARK: - Mock Data for Testing
extension OnboardingError {
    static var mock: OnboardingError {
        .onboardingRecordingFailed
    }
    
    static var mockInvalidUserInfo: OnboardingError {
        .invalidUserInfo
    }
    
    static var mockUploadFailed: OnboardingError {
        .onboardingUploadFailed
    }
    
    static var mockAnalysisFailed: OnboardingError {
        .onboardingAnalysisFailed
    }
} 