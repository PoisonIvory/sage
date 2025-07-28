import Foundation
import FirebaseAuth

/// Protocol for authentication service (for testability)
protocol AuthServiceProtocol {
    var currentUserId: String? { get }
}

/// Authentication service implementation
/// - Provides current user ID for onboarding flow
/// - Follows GWT test specifications for auth handling
final class AuthService: AuthServiceProtocol {
    
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
} 