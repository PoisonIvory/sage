//
//  VocalBaselineError.swift
//  Sage
//
//  Vocal baseline domain errors
//  Reference: DATA_STANDARDS.md §3.4, CONTRIBUTING.md
//

import Foundation

// MARK: - Vocal Baseline Domain Errors
enum VocalBaselineError: DomainError, CaseIterable {
    case incompleteAnalysis
    case clinicalValidationFailed(reason: String)
    case userProfileNotFound
    case repositoryError(Error)
    case unknown
    
    var errorCode: String {
        switch self {
        case .incompleteAnalysis: return "BASELINE_001"
        case .clinicalValidationFailed: return "BASELINE_002"
        case .userProfileNotFound: return "BASELINE_003"
        case .repositoryError: return "BASELINE_004"
        case .unknown: return "BASELINE_999"
        }
    }
    
    var userMessage: String {
        switch self {
        case .incompleteAnalysis: return "Voice analysis is still in progress. Please wait for the analysis to complete before establishing your baseline."
        case .clinicalValidationFailed(let reason): return "Voice recording quality needs improvement: \(reason)"
        case .userProfileNotFound: return "Please complete your profile setup first"
        case .repositoryError: return "Unable to save your voice baseline. Please try again."
        case .unknown: return "Unable to establish voice baseline"
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .incompleteAnalysis: return "Analysis result is incomplete for baseline establishment"
        case .clinicalValidationFailed(let reason): return "Clinical validation failed: \(reason)"
        case .userProfileNotFound: return "User profile not found in database"
        case .repositoryError(let error): return "Repository error: \(error.localizedDescription)"
        case .unknown: return "Unknown vocal baseline error"
        }
    }
    
    var retryBehavior: RetryBehavior {
        switch self {
        case .incompleteAnalysis: return .after(delay: 10.0)
        case .clinicalValidationFailed: return .afterUserAction(actionHint: "Improve recording quality")
        case .userProfileNotFound: return .afterUserAction(actionHint: "Complete profile setup")
        case .repositoryError: return .immediately
        case .unknown: return .never
        }
    }
    
    // Support for CaseIterable with associated values
    static var allCases: [VocalBaselineError] {
        return [
            .incompleteAnalysis,
            .clinicalValidationFailed(reason: ""),
            .userProfileNotFound,
            .repositoryError(NSError(domain: "", code: 0)),
            .unknown
        ]
    }
}

// MARK: - Mock Data for Testing
extension VocalBaselineError {
    static var mock: VocalBaselineError {
        .clinicalValidationFailed(reason: "F0 confidence below minimum threshold")
    }
    
    static var mockIncompleteAnalysis: VocalBaselineError {
        .incompleteAnalysis
    }
    
    static var mockClinicalValidationFailed: VocalBaselineError {
        .clinicalValidationFailed(reason: "Recording duration too short")
    }
    
    static var mockUserProfileNotFound: VocalBaselineError {
        .userProfileNotFound
    }
    
    static var mockRepositoryError: VocalBaselineError {
        .repositoryError(NSError(domain: "MockRepository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Database connection failed"]))
    }
} 