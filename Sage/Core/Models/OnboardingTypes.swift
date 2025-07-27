/// Signup methods available to users
/// - anonymous: User signs up without email/password
/// - email: User signs up with email/password

import Foundation

enum SignupMethod: String, CaseIterable, Codable {
    case anonymous = "anonymous"
    case email = "email"
}

/// Specific error types for signup operations
/// - Provides stable error comparison without relying on localizedDescription
/// - Enables robust error handling and testing
enum SignupErrorType: String, CaseIterable, Error, LocalizedError {
    case emailAlreadyInUse = "email_already_in_use"
    case networkRequestFailed = "network_request_failed"
    case invalidCredentials = "invalid_credentials"
    case unknown = "unknown"
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyInUse:
            return "This email is already registered. Try signing in instead."
        case .networkRequestFailed:
            return "Check your internet connection and try again."
        case .invalidCredentials:
            return "Invalid email or password."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

/// Results of signup method selection operation
/// - created: New profile created successfully
/// - exists: Profile already exists for this user
/// - error: Operation failed with specific error type
enum SignupResult: Equatable {
    case created
    case exists
    case error(SignupErrorType)
    
    static func == (lhs: SignupResult, rhs: SignupResult) -> Bool {
        switch (lhs, rhs) {
        case (.created, .created), (.exists, .exists):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

/// Validation errors for user profile data with field metadata
/// - ageRequired: Age field is empty or zero
/// - ageInvalid: Age is outside valid range (13-120)
/// - genderInvalid: Gender value is not in the allowed set
enum ValidationError: LocalizedError, Equatable {
    case ageRequired(fieldName: String = "age")
    case ageInvalid(fieldName: String = "age")
    case genderInvalid(fieldName: String = "gender")
    
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
    
    var fieldName: String {
        switch self {
        case .ageRequired(let fieldName), .ageInvalid(let fieldName), .genderInvalid(let fieldName):
            return fieldName
        }
    }
}

/// Protocol for date injection to improve testability
protocol DateProvider {
    var currentDate: Date { get }
}

/// Default date provider using system time
struct SystemDateProvider: DateProvider {
    var currentDate: Date {
        return Date()
    }
}

/// Mock date provider for testing
struct MockDateProvider: DateProvider {
    let currentDate: Date
    
    init(currentDate: Date = Date()) {
        self.currentDate = currentDate
    }
}

/// Onboarding steps for the new GWT-compliant onboarding flow
/// - signupMethod: User chooses [anonymous, email] signup
/// - explainer: View 1 - "Let's run some quick tests" screen
/// - vocalTest: View 2 - "Ahhh" test with 10-second recording
/// - readingPrompt: View 3 - Reading prompt placeholder
/// - finalStep: View 4 - Final completion step
/// - completed: Onboarding is complete
enum OnboardingStep: String, Equatable {
    case signupMethod = "signup_method"
    case explainer = "explainer"
    case vocalTest = "vocal_test"
    case readingPrompt = "reading_prompt"
    case finalStep = "final_step"
    case completed = "completed"
}

/// User profile data for form binding during onboarding
/// This is a local struct for UI state, mapped to UserProfile for persistence
struct UserProfileData: Equatable {
    var name: String = ""
    var age: Int = 0
    var gender: String = ""
    
    /// Creates a UserProfile from this form data with injected date provider
    /// - Parameters:
    ///   - id: User identifier
    ///   - deviceModel: Device model string
    ///   - osVersion: Operating system version
    ///   - dateProvider: Date provider for consistent testing
    /// - Returns: UserProfile instance
    func toUserProfile(
        id: String, 
        deviceModel: String, 
        osVersion: String, 
        dateProvider: DateProvider = SystemDateProvider()
    ) -> UserProfile {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return UserProfile(
            id: id,
            age: age,
            gender: gender,
            deviceModel: deviceModel,
            osVersion: osVersion,
            createdAt: formatter.string(from: dateProvider.currentDate)
        )
    }
}