//
//  DomainError.swift
//  Sage
//
//  Standardized error domain following DDD principles
//  Reference: DATA_STANDARDS.md §3.4, CONTRIBUTING.md
//

import Foundation

// MARK: - Domain Error Protocol
protocol DomainError: Error, LocalizedError {
    var errorCode: String { get }
    var userMessage: String { get }
    var technicalDetails: String { get }
    var shouldRetry: Bool { get }
}

// MARK: - Core Domain Errors
enum VoiceAnalysisError: DomainError {
    case recordingFailed(reason: String)
    case uploadFailed(reason: String)
    case analysisFailed(reason: String)
    case validationFailed(reasons: [String])
    case networkUnavailable
    case permissionDenied
    case timeout
    case userNotAuthenticated
    case noAnalysisResult
    case unknown
    
    var errorCode: String {
        switch self {
        case .recordingFailed: return "VOICE_001"
        case .uploadFailed: return "VOICE_002"
        case .analysisFailed: return "VOICE_003"
        case .validationFailed: return "VOICE_004"
        case .networkUnavailable: return "VOICE_005"
        case .permissionDenied: return "VOICE_006"
        case .timeout: return "VOICE_007"
        case .userNotAuthenticated: return "VOICE_008"
        case .noAnalysisResult: return "VOICE_009"
        case .unknown: return "VOICE_999"
        }
    }
    
    var userMessage: String {
        switch self {
        case .recordingFailed:
            return "Unable to record your voice. Please try again."
        case .uploadFailed:
            return "Unable to upload your recording. Please check your connection."
        case .analysisFailed:
            return "Unable to analyze your voice. Please try again."
        case .validationFailed(let reasons):
            return "Recording doesn't meet requirements: \(reasons.joined(separator: ", "))"
        case .networkUnavailable:
            return "No internet connection. Please check your network."
        case .permissionDenied:
            return "Microphone access is required. Please enable it in Settings."
        case .timeout:
            return "Request timed out. Please try again."
        case .userNotAuthenticated:
            return "Please sign in to continue."
        case .noAnalysisResult:
            return "No voice analysis results available."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .analysisFailed(let reason):
            return "Analysis failed: \(reason)"
        case .validationFailed(let reasons):
            return "Validation failed: \(reasons.joined(separator: ", "))"
        case .networkUnavailable:
            return "Network unavailable"
        case .permissionDenied:
            return "Microphone permission denied"
        case .timeout:
            return "Request timeout"
        case .userNotAuthenticated:
            return "User authentication required"
        case .noAnalysisResult:
            return "No analysis result available for processing"
        case .unknown:
            return "Unknown error occurred"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .recordingFailed, .uploadFailed, .analysisFailed, .timeout:
            return true
        case .validationFailed, .networkUnavailable, .permissionDenied, .userNotAuthenticated, .noAnalysisResult, .unknown:
            return false
        }
    }
}

// MARK: - Authentication Domain Errors
enum AuthenticationError: DomainError, CaseIterable {
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown
    
    var errorCode: String {
        switch self {
        case .invalidCredentials: return "AUTH_001"
        case .userNotFound: return "AUTH_002"
        case .emailAlreadyInUse: return "AUTH_003"
        case .weakPassword: return "AUTH_004"
        case .networkError: return "AUTH_005"
        case .unknown: return "AUTH_999"
        }
    }
    
    var userMessage: String {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "Account not found"
        case .emailAlreadyInUse:
            return "Email already registered"
        case .weakPassword:
            return "Password is too weak"
        case .networkError:
            return "Network error. Please try again"
        case .unknown:
            return "Authentication failed"
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password provided"
        case .userNotFound:
            return "User account not found"
        case .emailAlreadyInUse:
            return "Email address already registered"
        case .weakPassword:
            return "Password does not meet security requirements"
        case .networkError:
            return "Network connectivity issue"
        case .unknown:
            return "Unknown authentication error"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .networkError:
            return true
        case .invalidCredentials, .userNotFound, .emailAlreadyInUse, .weakPassword, .unknown:
            return false
        }
    }
}

// MARK: - Onboarding Domain Errors
enum OnboardingError: DomainError, CaseIterable {
    case invalidUserInfo
    case recordingFailed
    case uploadFailed
    case analysisFailed
    case unknown
    
    var errorCode: String {
        switch self {
        case .invalidUserInfo: return "ONBOARD_001"
        case .recordingFailed: return "ONBOARD_002"
        case .uploadFailed: return "ONBOARD_003"
        case .analysisFailed: return "ONBOARD_004"
        case .unknown: return "ONBOARD_999"
        }
    }
    
    var userMessage: String {
        switch self {
        case .invalidUserInfo:
            return "Please provide valid information"
        case .recordingFailed:
            return "Unable to record voice sample"
        case .uploadFailed:
            return "Unable to upload voice sample"
        case .analysisFailed:
            return "Unable to analyze voice sample"
        case .unknown:
            return "Onboarding failed"
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .invalidUserInfo:
            return "User information validation failed"
        case .recordingFailed:
            return "Voice recording failed during onboarding"
        case .uploadFailed:
            return "Voice sample upload failed"
        case .analysisFailed:
            return "Voice analysis failed during onboarding"
        case .unknown:
            return "Unknown onboarding error"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .recordingFailed, .uploadFailed, .analysisFailed:
            return true
        case .invalidUserInfo, .unknown:
            return false
        }
    }
}

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
        case .incompleteAnalysis:
            return "Voice analysis is still in progress. Please wait for the analysis to complete before establishing your baseline."
        case .clinicalValidationFailed(let reason):
            return "Voice recording quality needs improvement: \(reason)"
        case .userProfileNotFound:
            return "Please complete your profile setup first"
        case .repositoryError:
            return "Unable to save your voice baseline. Please try again."
        case .unknown:
            return "Unable to establish voice baseline"
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .incompleteAnalysis:
            return "Analysis result is incomplete for baseline establishment"
        case .clinicalValidationFailed(let reason):
            return "Clinical validation failed: \(reason)"
        case .userProfileNotFound:
            return "User profile not found in database"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        case .unknown:
            return "Unknown vocal baseline error"
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .incompleteAnalysis, .repositoryError:
            return true
        case .clinicalValidationFailed, .userProfileNotFound, .unknown:
            return false
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

// MARK: - Error Utilities
extension DomainError {
    func logError(context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        Logger.error("\(context) \(technicalDetails)", category: .general)
    }
}

// MARK: - Result Type Extensions
extension Result where Failure: DomainError {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .success: return nil
        case .failure(let error): return error.userMessage
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .success: return false
        case .failure(let error): return error.shouldRetry
        }
    }
} 