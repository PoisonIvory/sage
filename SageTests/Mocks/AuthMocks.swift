//
//  AuthMocks.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Mock objects for authentication testing
//  Provides test data for authentication scenarios
//  Updated to remove Firebase subclassing issues

import Foundation
import FirebaseAuth

// MARK: - Test Data Structures
/// Simple test data structures that don't try to subclass Firebase classes
struct TestUserData {
    let uid: String
    let isAnonymous: Bool
    let email: String?
    
    init(uid: String = "test-uid", isAnonymous: Bool = true, email: String? = nil) {
        self.uid = uid
        self.isAnonymous = isAnonymous
        self.email = email
    }
}

struct TestAuthResult {
    let success: Bool
    let error: Error?
    let userData: TestUserData?
    
    init(success: Bool, error: Error? = nil, userData: TestUserData? = nil) {
        self.success = success
        self.error = error
        self.userData = userData
    }
}

// MARK: - Test Scenarios
/// Predefined test scenarios for common authentication flows
class AuthTestScenarios {
    static let anonymousUser = TestUserData(uid: "anonymous-123", isAnonymous: true)
    static let emailUser = TestUserData(uid: "email-123", isAnonymous: false, email: "test@example.com")
    static let returningUser = TestUserData(uid: "returning-123", isAnonymous: true)
    
    static let successfulSignIn = TestAuthResult(success: true, userData: anonymousUser)
    static let failedSignIn = TestAuthResult(success: false, error: NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
    static let timeoutError = TestAuthResult(success: false, error: NSError(domain: "test", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"]))
}

// MARK: - Test Helpers
/// Helper functions for testing authentication scenarios
class AuthTestHelpers {
    static func createAnonymousUser(uid: String = "test-uid") -> TestUserData {
        return TestUserData(uid: uid, isAnonymous: true)
    }
    
    static func createEmailUser(uid: String = "test-uid", email: String = "test@example.com") -> TestUserData {
        return TestUserData(uid: uid, isAnonymous: false, email: email)
    }
    
    static func createNetworkError() -> Error {
        return NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
    }
    
    static func createTimeoutError() -> Error {
        return NSError(domain: "test", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])
    }
} 