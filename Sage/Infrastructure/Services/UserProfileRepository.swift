// UserProfileRepository.swift
// Handles saving user profile data to Firestore per DATA_DICTIONARY.md and DATA_STANDARDS.md §2.3
// All writes must comply with scientific/data standards and field definitions.
import Foundation
import FirebaseFirestore

/// Repository for saving UserProfile to Firestore, compliant with DATA_DICTIONARY.md and DATA_STANDARDS.md §2.3.
class UserProfileRepository: UserProfileRepositoryProtocol {
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
    
    /// Fetches a UserProfile from Firestore by user ID.
    /// - Parameters:
    ///   - id: The user ID to fetch the profile for
    ///   - completion: Completion handler with optional UserProfile
    /// - SeeAlso: DATA_DICTIONARY.md, DATA_STANDARDS.md §2.3
    func fetchUserProfile(withId id: String, completion: @escaping (UserProfile?) -> Void) {
        db.collection(collection).document(id).getDocument { document, error in
            if let error = error {
                print("UserProfileRepository: Failed to fetch user profile: \(error)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                print("UserProfileRepository: No user profile found for id=\(id)")
                completion(nil)
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let profile = try decoder.decode(UserProfile.self, from: jsonData)
                print("UserProfileRepository: Successfully fetched user profile for id=\(id)")
                completion(profile)
            } catch {
                print("UserProfileRepository: Failed to decode user profile: \(error)")
                completion(nil)
            }
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