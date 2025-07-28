// Shared mock and stubs for AuthProtocol-based tests
import Foundation
@testable import Sage

// Minimal stub for User (replace with FirebaseAuth.User if needed)
class User {
    var uid: String = "mock"
    var isAnonymous: Bool = false
    init(uid: String = "mock", isAnonymous: Bool = false) {
        self.uid = uid
        self.isAnonymous = isAnonymous
    }
}

// Minimal stub for AuthDataResult
class AuthDataResult {}

// Shared mock for AuthProtocol
class MockAuthService: AuthProtocol {
    var shouldFailSignOut = false
    var signOutCalled = false
    var currentUser: User? = nil
    var shouldReturnError = false
    var errorType: Error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    
    func signOut() throws {
        signOutCalled = true
        if shouldFailSignOut {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to sign out"])
        }
    }
    
    func signInAnonymously(completion: @escaping (AuthDataResult?, Error?) -> Void) {
        if shouldReturnError {
            completion(nil, errorType)
        } else {
            completion(AuthDataResult(), nil)
        }
    }
    
    func signUpWithEmail(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        if shouldReturnError {
            completion(false, errorType)
        } else {
            completion(true, nil)
        }
    }
    
    func reset() {
        shouldFailSignOut = false
        signOutCalled = false
        shouldReturnError = false
        currentUser = nil
    }
}

// Mock for AuthServiceProtocol
class MockAuthServiceProtocol: AuthServiceProtocol {
    var currentUserId: String? = "mock-user-id"
    var shouldReturnError = false
    var errorType: Error = NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
    
    func reset() {
        currentUserId = "mock-user-id"
        shouldReturnError = false
    }
} 