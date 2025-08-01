import Foundation

/// Protocol for user profile repository
protocol UserProfileRepositoryProtocol {
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void)
} 