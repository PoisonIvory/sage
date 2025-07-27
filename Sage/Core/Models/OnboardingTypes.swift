/// Signup methods available to users
/// - anonymous: User signs up without email/password
/// - email: User signs up with email/password

import Foundation

enum SignupMethod: String, CaseIterable, Codable {
    case anonymous = "anonymous"
    case email = "email"
}

/// Results of signup method selection operation
/// - created: New profile created successfully
/// - exists: Profile already exists for this user
/// - error: Operation failed with error

enum SignupResult: Equatable {
    case created
    case exists
    case error(Error)
    
    static func == (lhs: SignupResult, rhs: SignupResult) -> Bool {
        switch (lhs, rhs) {
        case (.created, .created), (.exists, .exists):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

/// Validation errors for user profile data
/// - ageRequired: Age field is empty or zero
/// - ageInvalid: Age is outside valid range (13-120)
/// - genderInvalid: Gender value is not in the allowed set
enum ValidationError: LocalizedError, Equatable {
    case ageRequired
    case ageInvalid
    case genderInvalid
    
    var errorDescription: String? {
        switch self {
        case .ageRequired:
            return "Age is required for research purposes"
        case .ageInvalid:
            return "Age must be between 13 and 120"
        case .genderInvalid:
            return "Please select a valid gender option"
        }
    }
}



/// User profile data for form binding during onboarding
/// This is a local struct for UI state, mapped to UserProfile for persistence
struct UserProfileData: Equatable {
    var name: String = ""
    var age: Int = 0
    var gender: String = ""
    
    /// Creates a UserProfile from this form data
    func toUserProfile(id: String, deviceModel: String, osVersion: String) -> UserProfile {
        UserProfile(
            id: id,
            age: age,
            gender: gender,
            deviceModel: deviceModel,
            osVersion: osVersion,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
    }
}