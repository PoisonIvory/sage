// Shared mock and stubs for AuthProtocol-based tests
import Foundation

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
testable import Sage
class MockAuthService: AuthProtocol {
    var shouldFailSignOut = false
    var signOutCalled = false
    var currentUser: User? = nil
    func signOut() throws {
        signOutCalled = true
        if shouldFailSignOut {
            throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to sign out"])
        }
    }
    func signInAnonymously(completion: @escaping (AuthDataResult?, Error?) -> Void) {
        completion(nil, nil)
    }
} 