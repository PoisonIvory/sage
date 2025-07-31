/// Signup methods available to users
/// - anonymous: User signs up without email/password
/// - email: User signs up with email/password

import Foundation

enum SignupMethod: String, CaseIterable, Codable {
    case anonymous = "anonymous"
    case email = "email"
}

/// Specific error types for signup operations
/// - Enables robust error handling and testing with stable error comparison
enum SignupErrorType: String, Error, LocalizedError {
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

// MARK: - Value Objects

/// Age value object with built-in validation
/// - Encapsulates age range validation (13-120)
/// - Provides semantic clarity and reusability
public struct Age: Equatable, Codable {
    public let value: Int
    
    public init(_ value: Int) throws {
        guard value >= 13 && value <= 120 else {
            throw ValidationError.ageInvalid()
        }
        self.value = value
    }
    
    /// Creates age from optional value with validation
    public init?(optional value: Int?) {
        guard let value = value else { return nil }
        try? self.init(value)
    }
    
    /// Validates age without creating instance
    public static func isValid(_ value: Int) -> Bool {
        return value >= 13 && value <= 120
    }
    
    /// Minimum valid age for research purposes
    public static let minimum = 13
    
    /// Maximum valid age for research purposes
    public static let maximum = 120
}

/// Voice conditions value object
public struct VoiceConditions: Equatable, Codable {
    public let conditions: [String]
    
    public init(_ conditions: [String]) throws {
        guard !conditions.isEmpty else {
            throw ValidationError.voiceConditionsRequired()
        }
        self.conditions = conditions
    }
}

/// Diagnosed conditions value object
public struct DiagnosedConditions: Equatable, Codable {
    public let conditions: [String]
    
    public init(_ conditions: [String]) throws {
        guard !conditions.isEmpty else {
            throw ValidationError.diagnosedConditionsRequired()
        }
        self.conditions = conditions
    }
}

// MARK: - Validation Errors

/// Comprehensive validation errors for user profile data
/// - Each field has specific error types for semantic clarity
/// - Provides stable error comparison and field-specific messaging
public enum ValidationError: LocalizedError, Equatable {
    case ageRequired(fieldName: String = "age")
    case ageInvalid(fieldName: String = "age")
    case genderInvalid(fieldName: String = "gender")
    case voiceConditionsRequired(fieldName: String = "voiceConditions")
    case diagnosedConditionsRequired(fieldName: String = "diagnosedConditions")
    
    public var errorDescription: String? {
        switch self {
        case .ageRequired:
            return "Age is required for research purposes"
        case .ageInvalid:
            return "Age must be between 13 and 120"
        case .genderInvalid:
            return "Please select a valid gender option"
        case .voiceConditionsRequired:
            return "Please select at least one voice condition"
        case .diagnosedConditionsRequired:
            return "Please select at least one diagnosed condition"
        }
    }
    
    public var fieldName: String {
        switch self {
        case .ageRequired(let fieldName), 
             .ageInvalid(let fieldName), 
             .genderInvalid(let fieldName),
             .voiceConditionsRequired(let fieldName),
             .diagnosedConditionsRequired(let fieldName):
            return fieldName
        }
    }
}

/// Protocol for date injection to improve testability
public protocol DateProvider {
    var currentDate: Date { get }
}

/// Default date provider using system time
public struct SystemDateProvider: DateProvider {
    public var currentDate: Date {
        return Date()
    }
    
    public init() {}
}

/// Mock date provider for testing
public struct MockDateProvider: DateProvider {
    public let currentDate: Date
    
    public init(currentDate: Date = Date()) {
        self.currentDate = currentDate
    }
}

/// Onboarding steps for the new GWT-compliant onboarding flow
/// - signupMethod: User chooses [anonymous, email] signup
/// - explainer: View 1 - "Let's run some quick tests" screen
/// - userInfoForm: View 2 - User provides age, gender, and optional name
/// - sustainedVowelTest: View 3 - "Ahhh" test with 10-second recording
/// - readingPrompt: View 4 - Reading prompt placeholder
/// - finalStep: View 5 - Final completion step
/// - completed: Onboarding is complete
enum OnboardingStep: String, Equatable {
    case signupMethod = "signup_method"
    case explainer = "explainer"
    case userInfoForm = "user_info_form"
    case sustainedVowelTest = "sustained_vowel_test"
    case readingPrompt = "reading_prompt"
    case finalStep = "final_step"
    case completed = "completed"
}

/// User profile data for form binding during onboarding
/// This is a local struct for UI state, mapped to UserProfile for persistence
/// - Uses value objects for better encapsulation and validation
/// - Provides comprehensive validation with semantic error types
public struct UserProfileData: Equatable {
    public var age: Int
    public var genderIdentity: GenderIdentity
    public var sexAssignedAtBirth: SexAssignedAtBirth
    public var voiceConditions: [String]
    public var diagnosedConditions: [String]
    
    public init(
        age: Int,
        genderIdentity: GenderIdentity = .preferNotToSay,
        sexAssignedAtBirth: SexAssignedAtBirth = .preferNotToSay,
        voiceConditions: [String] = ["None"],
        diagnosedConditions: [String] = ["None"]
    ) {
        self.age = age
        self.genderIdentity = genderIdentity
        self.sexAssignedAtBirth = sexAssignedAtBirth
        self.voiceConditions = voiceConditions
        self.diagnosedConditions = diagnosedConditions
    }
    
    // MARK: - Validation Methods
    
    /// Validates profile data - throws ValidationError on first failure
    /// - Uses value objects for consistent validation
    /// - Provides semantic error messages
    public func validate() throws {
        // Age validation using value object
        if age <= 0 {
            throw ValidationError.ageRequired()
        } else if !Age.isValid(age) {
            throw ValidationError.ageInvalid()
        }
        
        // Voice conditions validation
        if voiceConditions.isEmpty {
            throw ValidationError.voiceConditionsRequired()
        }
        
        // Diagnosed conditions validation
        if diagnosedConditions.isEmpty {
            throw ValidationError.diagnosedConditionsRequired()
        }
    }
    
    /// Validates profile data - returns all errors at once
    /// - Collects all validation errors for comprehensive feedback
    /// - Useful for form validation where multiple errors can be shown
    public func validateAll() -> UserProfileValidationResult {
        var errors: [ValidationError] = []
        
        // Age validation
        if age <= 0 {
            errors.append(.ageRequired())
        } else if !Age.isValid(age) {
            errors.append(.ageInvalid())
        }
        
        // Voice conditions validation
        if voiceConditions.isEmpty {
            errors.append(.voiceConditionsRequired())
        }
        
        // Diagnosed conditions validation
        if diagnosedConditions.isEmpty {
            errors.append(.diagnosedConditionsRequired())
        }
        
        return UserProfileValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    /// Validates age specifically using Age value object
    public func validateAge() -> ValidationError? {
        if age <= 0 {
            return .ageRequired()
        } else if !Age.isValid(age) {
            return .ageInvalid()
        }
        return nil
    }
    
    /// Validates voice conditions specifically
    public func validateVoiceConditions() -> ValidationError? {
        if voiceConditions.isEmpty {
            return .voiceConditionsRequired()
        }
        return nil
    }
    
    /// Validates diagnosed conditions specifically
    public func validateDiagnosedConditions() -> ValidationError? {
        if diagnosedConditions.isEmpty {
            return .diagnosedConditionsRequired()
        }
        return nil
    }
    
    // MARK: - Profile Creation Methods
    
    /// Creates a minimal UserProfile for initial signup
    public static func createMinimalProfile(
        userId: String,
        deviceModel: String,
        osVersion: String,
        dateProvider: DateProvider = SystemDateProvider()
    ) throws -> UserProfile {
        return try UserProfile.createMinimal(
            userId: userId,
            deviceModel: deviceModel,
            osVersion: osVersion
        )
    }
    
    /// Creates a UserProfile from this form data with injected date provider
    /// - Parameters:
    ///   - id: User identifier
    ///   - deviceModel: Device model string
    ///   - osVersion: Operating system version
    ///   - dateProvider: Date provider for consistent testing
    /// - Returns: UserProfile instance
    public func toUserProfile(
        id: String, 
        deviceModel: String, 
        osVersion: String, 
        dateProvider: DateProvider = SystemDateProvider()
    ) throws -> UserProfile {
        return try UserProfile(
            id: id,
            age: age,
            genderIdentity: genderIdentity,
            sexAssignedAtBirth: sexAssignedAtBirth,
            voiceConditions: voiceConditions,
            diagnosedConditions: diagnosedConditions,
            suspectedConditions: [],
            deviceModel: deviceModel,
            osVersion: osVersion
        )
    }
}

/// Result of user profile validation
/// - Encapsulates validation results with semantic clarity
/// - Provides both boolean result and detailed error information
public struct UserProfileValidationResult {
    public let isValid: Bool
    public let errors: [ValidationError]
    
    public init(isValid: Bool, errors: [ValidationError]) {
        self.isValid = isValid
        self.errors = errors
    }
    
    /// Returns the first error for simple validation scenarios
    public var firstError: ValidationError? {
        return errors.first
    }
    
    /// Returns error messages for UI display
    public var errorMessages: [String] {
        return errors.compactMap { $0.errorDescription }
    }
    
    /// Returns field-specific errors for form validation
    public var fieldErrors: [String: String] {
        var fieldErrors: [String: String] = [:]
        for error in errors {
            fieldErrors[error.fieldName] = error.errorDescription
        }
        return fieldErrors
    }
}