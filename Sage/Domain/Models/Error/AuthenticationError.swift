//
//  AuthenticationError.swift
//  Sage
//
//  Authentication domain errors
//  Reference: DATA_STANDARDS.md §3.4, CONTRIBUTING.md
//

import Foundation

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
        case .invalidCredentials: return "Invalid email or password"
        case .userNotFound: return "Account not found"
        case .emailAlreadyInUse: return "Email already registered"
        case .weakPassword: return "Password is too weak"
        case .networkError: return "Network error. Please try again"
        case .unknown: return "Authentication failed"
        }
    }
    
    var technicalDetails: String {
        switch self {
        case .invalidCredentials: return "Invalid email or password provided"
        case .userNotFound: return "User account not found"
        case .emailAlreadyInUse: return "Email address already registered"
        case .weakPassword: return "Password does not meet security requirements"
        case .networkError: return "Network connectivity issue"
        case .unknown: return "Unknown authentication error"
        }
    }
    
    var retryBehavior: RetryBehavior {
        switch self {
        case .invalidCredentials: return .afterUserAction(actionHint: "Check email and password")
        case .userNotFound: return .afterUserAction(actionHint: "Create account or check email")
        case .emailAlreadyInUse: return .afterUserAction(actionHint: "Use different email or sign in")
        case .weakPassword: return .afterUserAction(actionHint: "Use stronger password")
        case .networkError: return .after(delay: 3.0)
        case .unknown: return .never
        }
    }
}

// MARK: - Mock Data for Testing
extension AuthenticationError {
    static var mock: AuthenticationError {
        .invalidCredentials
    }
    
    static var mockNetworkError: AuthenticationError {
        .networkError
    }
    
    static var mockUserNotFound: AuthenticationError {
        .userNotFound
    }
    
    static var mockEmailInUse: AuthenticationError {
        .emailAlreadyInUse
    }
    
    static var mockWeakPassword: AuthenticationError {
        .weakPassword
    }
} 