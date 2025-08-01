//
//  VoiceAnalysisError.swift
//  Sage
//
//  Voice analysis domain errors
//  Reference: DATA_STANDARDS.md §3.4, CONTRIBUTING.md
//

import Foundation

// MARK: - Voice Analysis Domain Errors
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
        case .recordingFailed: return "Unable to record your voice. Please try again."
        case .uploadFailed: return "Unable to upload your recording. Please check your connection."
        case .analysisFailed: return "Unable to analyze your voice. Please try again."
        case .validationFailed(let reasons): return "Recording doesn't meet requirements: \(reasons.joined(separator: ", "))"
        case .networkUnavailable: return "No internet connection. Please check your network."
        case .permissionDenied: return "Microphone access is required. Please enable it in Settings."
        case .timeout: return "Request timed out. Please try again."
        case .userNotAuthenticated: return "Please sign in to continue."
        case .noAnalysisResult: return "No voice analysis results available."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .recordingFailed(let reason): return "Recording failed: \(reason)"
        case .uploadFailed(let reason): return "Upload failed: \(reason)"
        case .analysisFailed(let reason): return "Analysis failed: \(reason)"
        case .validationFailed(let reasons): return "Validation failed: \(reasons.joined(separator: ", "))"
        case .networkUnavailable: return "Network unavailable"
        case .permissionDenied: return "Microphone permission denied"
        case .timeout: return "Request timeout"
        case .userNotAuthenticated: return "User authentication required"
        case .noAnalysisResult: return "No analysis result available for processing"
        case .unknown: return "Unknown error occurred"
        }
    }
    
    var retryBehavior: RetryBehavior {
        switch self {
        case .recordingFailed: return .immediately
        case .uploadFailed: return .immediately
        case .analysisFailed: return .immediately
        case .validationFailed: return .never
        case .networkUnavailable: return .after(delay: 5.0)
        case .permissionDenied: return .afterUserAction(actionHint: "Enable microphone permission in Settings")
        case .timeout: return .after(delay: 2.0)
        case .userNotAuthenticated: return .afterUserAction(actionHint: "Sign in to continue")
        case .noAnalysisResult: return .never
        case .unknown: return .never
        }
    }
}

// MARK: - Mock Data for Testing
extension VoiceAnalysisError {
    static var mock: VoiceAnalysisError {
        .analysisFailed(reason: "Cloud model timeout")
    }
    
    static var mockRecordingFailed: VoiceAnalysisError {
        .recordingFailed(reason: "Invalid prompt ID")
    }
    
    static var mockValidationFailed: VoiceAnalysisError {
        .validationFailed(reasons: ["Recording too short", "Background noise detected"])
    }
    
    static var mockNetworkError: VoiceAnalysisError {
        .networkUnavailable
    }
    
    static var mockPermissionError: VoiceAnalysisError {
        .permissionDenied
    }
} 