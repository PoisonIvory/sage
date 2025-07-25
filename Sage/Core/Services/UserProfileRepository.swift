// UserProfileRepository.swift
// Handles saving user profile data to Firestore per DATA_DICTIONARY.md and DATA_STANDARDS.md §2.3
// All writes must comply with scientific/data standards and field definitions.
import Foundation
import FirebaseFirestore

/// Repository for saving UserProfile to Firestore, compliant with DATA_DICTIONARY.md and DATA_STANDARDS.md §2.3.
class UserProfileRepository {
    private let db = Firestore.firestore()
    private let collection = "users"

    /// Saves a UserProfile to Firestore under the user's UID.
    /// - Parameters:
    ///   - profile: The UserProfile to save (must match DATA_DICTIONARY.md fields).
    ///   - completion: Completion handler with optional error.
    /// - SeeAlso: DATA_DICTIONARY.md, DATA_STANDARDS.md §2.3
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Error?) -> Void) {
        db.collection(collection).document(profile.id).setData(profile.toDict()) { error in
            if let error = error {
                print("UserProfileRepository: Failed to save user profile: \(error)")
            } else {
                print("UserProfileRepository: User profile saved for id=\(profile.id)")
            }
            completion(error)
        }
    }
}

// MARK: - Codable to Dictionary Helper
private extension UserProfile {
    func toDict() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
} 