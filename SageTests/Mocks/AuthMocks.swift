//
//  AuthMocks.swift
//  SageTests
//
//  Created by Ivy Hamilton on 24/7/2025.
//
//  Mock objects for authentication testing
//  Provides fake Firebase Auth objects for unit testing

import Foundation
import FirebaseAuth

// MARK: - Mock Firebase Auth
/// Mock Firebase Auth for testing - simulates Firebase behavior
class MockFirebaseAuth {
    static var currentUser: User? = nil
    static var shouldSignInAnonymouslySucceed = true
    static var signInAnonymouslyError: Error? = nil
    
    static func reset() {
        currentUser = nil
        shouldSignInAnonymouslySucceed = true
        signInAnonymouslyError = nil
    }
}

// MARK: - Mock User
/// Mock User for testing - simulates a Firebase user
class MockUser: User {
    let uid: String
    let isAnonymous: Bool
    
    init(uid: String = "mock-uid", isAnonymous: Bool = true) {
        self.uid = uid
        self.isAnonymous = isAnonymous
    }
    
    // Required User protocol properties
    var email: String? = nil
    var phoneNumber: String? = nil
    var photoURL: URL? = nil
    var displayName: String? = nil
    var metadata: UserMetadata = MockUserMetadata()
    var providerData: [UserInfo] = []
    var refreshToken: String = ""
    var tenantID: String? = nil
    var isEmailVerified: Bool = false
    var customClaims: [String: Any]? = nil
}

// MARK: - Mock User Metadata
class MockUserMetadata: UserMetadata {
    var lastSignInDate: Date? = Date()
    var creationDate: Date? = Date()
} 